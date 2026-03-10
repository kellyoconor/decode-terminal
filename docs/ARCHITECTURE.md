# Architecture

This document describes how Decode works internally. It is written for contributors who want to understand the codebase, fix bugs, or add features like new agent grammars.

---

## System overview

```
+-------------------------------+       +----------------------------------+
|         Terminal Pane          |       |        Narration Sidebar         |
|         (dark, left)           |       |        (warm cream, right)       |
|                                |       |                                  |
|  +-------------------------+  |       |  +----------------------------+  |
|  |  TappedTerminalView     |  |       |  |  StatusPillView            |  |
|  |  (SwiftTerm subclass)   |--|--+    |  +----------------------------+  |
|  +-------------------------+  |  |    |  |  GitBranchView             |  |
|                                |  |    |  |  GitActionsView            |  |
+-------------------------------+  |    |  +----------------------------+  |
                                   |    |  |  NarrationEntryView (x N)  |  |
                                   |    |  |  GitCommitCardView  (x N)  |  |
                                   |    |  +----------------------------+  |
                                   |    +----------------------------------+
                                   |
                                   v
                              [ PTYTap ]
                                   |
                                   | raw bytes (Data)
                                   v
                            [ ANSIStripper ]
                                   |
                                   | clean text
                                   v
                           [ ChunkAssembler ]
                                   |
                                   | TerminalChunk (text + timestamp)
                                   v
                         [ ClaudeCodeGrammar ]
                                   |
                                   | AnnotatedChunk (chunk + [ChunkLabel])
                                   v
                          [ NarrationContext ]
                                   |
                                   | serialized context string
                                   v
                          [ NarrationEngine ]
                                   |
                                   | NarrationEntry (text + status)
                                   v
                        [ SessionController ]
                           /       |       \
                          v        v        v
                   Sidebar UI   GitMonitor  SessionPersistence
```

---

## The narration pipeline

### Stage 1: Byte interception (PTYTap)

`TappedTerminalView` is a subclass of SwiftTerm's `LocalProcessTerminalView`. It overrides `dataReceived(slice:)` to copy each byte slice to `PTYTap` before calling `super`. This is the only point where Decode touches the terminal data path -- it is a passive tap, not a filter. The terminal never waits on the narration pipeline.

`PTYTap` publishes bytes on a Combine `PassthroughSubject<Data, Never>`. It also holds the shell's `pid_t` (set after terminal startup) and a weak reference to the terminal view for command injection (used by git quick actions).

**File:** `Sources/Decode/Terminal/PTYTap.swift`

### Stage 2: ANSI stripping (ANSIStripper)

Raw terminal output contains CSI sequences (colors, cursor movement), OSC sequences (window titles), carriage returns (progress bars), and spinner characters (braille dots, box-drawing frames). `ANSIStripper.strip(_:)` removes all of these with a single combined regex pass.

`ANSIStripper.isSpinnerNoise(_:)` further filters out:

- Very short chunks (under 5 characters)
- Claude Code thinking animation words ("Twisting...", "Embellishing...", "Harmonizing...", etc.)
- Startup UI chrome ("Tip:", "Press", "for shortcuts", etc.)
- Content that is more than 70% spinner/braille characters

This filtering is critical. Without it, the narration engine would fire on every spinner frame and produce garbage.

**File:** `Sources/Decode/Terminal/ANSIStripper.swift`

### Stage 3: Chunk assembly (ChunkAssembler)

The assembler subscribes to `PTYTap.dataSubject` and buffers incoming bytes. It flushes on two conditions:

- **Time-based:** every 500ms via a repeating timer
- **Volume-based:** when the buffer exceeds 2048 bytes

On flush, the buffer is decoded as UTF-8, stripped of ANSI codes, trimmed, checked for spinner noise, and published as a `TerminalChunk` on a Combine subject. Empty or noise-only flushes are silently dropped.

The 500ms / 2KB thresholds are tuned for typical Claude Code output. Tool call headers arrive in bursts (high volume, low latency). Thinking animations trickle in (low volume, high latency). The dual-trigger strategy handles both patterns.

**File:** `Sources/Decode/Agent/ChunkAssembler.swift`

### Stage 4: Agent grammar (ClaudeCodeGrammar)

The grammar has two jobs:

**Detection.** During the first ~20 chunks, `confidence(for:)` scans for Claude Code signatures: the word "claude" (case-insensitive), box-drawing characters, and "anthropic". Two or more hits yield 95% confidence. Once confidence crosses 80%, the `SessionController` locks detection and stops probing.

**Annotation.** For every chunk, `annotate(chunk:)` runs a series of regex patterns and returns a list of `ChunkLabel` values:

| Label | Pattern | Example match |
|-------|---------|---------------|
| `toolCall` | `^\\s*(?:>\\s*)?(Read\|Write\|Edit\|Bash\|...)\\s*[:(]` | `Read: src/main.swift` |
| `fileEdit` | File path regex + inferred operation | `/src/App.swift` (read/write/create/delete/edit) |
| `permissionPrompt` | "Do you want to...", "allow edits", "Esc to cancel" | `Do you want to edit index.html` |
| `testRun` | `npm test`, `pytest`, `cargo test`, etc. | `npm test` |
| `testResult` | "PASS", "FAIL", "N passed", "N failed" | `Tests: 4 passed, 1 failed` |
| `error` | "error:", "FAIL", "panic", "traceback" | `Error: file not found` |
| `userInput` | "Interrupted", "What should Claude do", permission dialogs | `Do you want to create...` |
| `agentOutput` | Fallback -- anything that doesn't match above | General agent text |

Chunks can carry multiple labels. A chunk containing both a tool call and an error gets both.

**File:** `Sources/Decode/Agent/ClaudeCodeGrammar.swift`

### Stage 5: Context assembly (NarrationContext)

`NarrationContext` maintains:

- A sliding window of `AnnotatedChunk` values (the last ~10, pruned to stay under 4000 estimated tokens)
- The last 3 `NarrationEntry` values (sent to Claude as "do not repeat" context)
- The detected agent type, session start time, and original user prompt
- A `newChunkCount` counter, reset after each narration

`serialize()` produces a structured text block for the Claude API user message:

```
AGENT: claude_code
SESSION DURATION: 47s
ORIGINAL USER REQUEST: claude build me a login page
CURRENT STATUS: on_route

PREVIOUS NARRATIONS (do not repeat):
- [on_route] Reading package.json to check dependencies.
- [on_route] Writing the login component. Two files created so far.

NEW TERMINAL OUTPUT:
[TOOL:Edit] editing src/Login.swift with new form component
[OUTPUT] compilation successful, no warnings
```

Token estimation uses a simple `count / 4` heuristic. When the serialized context exceeds 4000 tokens, the oldest chunks are pruned one at a time.

**File:** `Sources/Decode/Narration/NarrationContext.swift`

### Stage 6: Narration engine (NarrationEngine)

The engine answers two questions: **when** to narrate, and **what** to say.

**Trigger policy** (`shouldNarrate`):

| Condition | Fires? |
|-----------|--------|
| Less than 8 seconds since last narration | Never |
| 5+ new chunks since last narration | Yes |
| 15+ seconds since last narration (with any new chunks) | Yes |
| Most recent chunk has a `permissionPrompt`, `error`, or `testResult` label | Immediately (after 8s cooldown) |
| No new chunks | Never |

**System prompt design.** The system prompt is a carefully tuned instruction set that tells Claude Haiku to:

- Respond in a strict `STATUS: <value>` + narration format
- Stay under 25 words, one sentence
- Use present tense, refer to "the agent" (never "Claude")
- Never quote code -- translate to plain language
- Not repeat previous narrations
- Treat thinking animations as normal work (on_route), not stuck
- Reserve "stuck" for genuine error loops lasting 2+ minutes

**Dedup logic.** If the engine produces a `waiting_for_input` status and the previous narration was also `waiting_for_input`, the entry is silently dropped. This prevents the sidebar from filling with identical "Needs your input" cards.

**Retry strategy.** On API failure, the engine retries up to 2 times with linear backoff (1s, 2s). After 3 consecutive failures, the narration degrades to an error message rather than silently disappearing. The failure counter resets on any successful response.

**Streaming.** The engine uses `ClaudeAPIClient.stream()` which returns an `AsyncThrowingStream<String, Error>`. Tokens arrive via Server-Sent Events. The system prompt uses Anthropic's prompt caching (`cache_control: ephemeral`) to reduce latency and cost on repeated calls.

**Files:**
- `Sources/Decode/Narration/NarrationEngine.swift`
- `Sources/Decode/Narration/ClaudeAPIClient.swift`

---

## Git monitoring

### How cwd resolution works

The terminal runs a shell process. AI agents change directories freely (`cd` into project folders, subfolders, etc.). Decode needs to know where the shell is right now to run `git` commands against the correct repo.

`GitMonitor.cwdForPid(_:)` uses the Darwin `proc_pidinfo` syscall with `PROC_PIDVNODEPATHINFO` to read the kernel's record of the process's current working directory. This is the same mechanism `lsof` uses. It does not require any shell integration, dotfile modification, or precmd hooks. It works with any shell.

The shell PID is obtained from SwiftTerm's `LocalProcessTerminalView.process.shellPid` after terminal startup (with a retry loop, since the PID is not immediately available).

### Polling strategy

`GitMonitor` polls every 3 seconds. Each poll:

1. Resolves cwd via `proc_pidinfo`
2. Runs `git rev-parse --show-toplevel` to find (or confirm) the repo root
3. Reads the current branch name (`git rev-parse --abbrev-ref HEAD`)
4. Reads the HEAD short hash
5. Runs `git diff --shortstat HEAD` for lines added/removed/files changed
6. Compares HEAD hash against the previous poll to detect new commits

If a new commit is detected, `detectNewCommit` reads the commit message and diff stats, then publishes a `GitCommitInfo` value that the `SessionController` inserts into the sidebar feed as a commit card.

The 3-second interval is a balance between responsiveness (catching commits within seconds) and resource usage (6 git processes per poll cycle).

**File:** `Sources/Decode/Services/GitMonitor.swift`

---

## Session orchestration

`SessionController` is the central coordinator. It owns:

- `PTYTap` (byte interception)
- `ChunkAssembler` (buffering and flushing)
- `ClaudeCodeGrammar` (pattern matching)
- `NarrationContext` (context window)
- `NarrationEngine` (Claude API interaction)
- `GitMonitor` (git state polling)

It subscribes to chunk events, annotates them, updates status based on labels, and runs a 2-second timer that checks whether narration should fire. When narration produces an entry, it appends it to the sidebar feed and auto-saves the session.

The sidebar feed is a `[SidebarItem]` array containing interleaved `.narration` and `.commit` entries, capped at 100 items. The UI renders them newest-first.

**File:** `Sources/Decode/Services/SessionController.swift`

---

## Design philosophy

### Why warm cream, not dark

The terminal pane is dark -- that's where the raw, dense, machine-readable output lives. The sidebar is warm cream (`#FAFAF7` background, `#F0F0EB` cards, `#E8E8E3` borders) -- that's the human layer.

The contrast between the two panes IS the product story. The left side is the firehose. The right side is the navigator. Putting them side by side, in visually distinct palettes, makes the value proposition immediately legible.

The warm tones (cream, not white; muted olive text, not gray) were chosen to feel calm and readable during long sessions. The sidebar should feel like a notebook sitting next to your terminal, not like another panel competing for attention.

### Card taxonomy

The sidebar feed contains three visual types:

| Card type | Color accent | Trigger |
|-----------|-------------|---------|
| Narration entry | None (text on cream) | Narration engine fires |
| "Needs your input" | Blue (`#3B82F6`) border and background tint | `waiting_for_input` status |
| Commit card | Amber (`#EE821E`) border and background tint | New commit detected by GitMonitor |

Each card type is visually distinct at a glance. You should be able to scan the sidebar and immediately spot permission requests and commits without reading any text.

### Status pill colors

The status pill in the sidebar uses a deliberate color language:

- **Green** (On Route): Everything is fine. This is the most common state.
- **Amber** (Drifting): Attention may be needed, but it's not urgent.
- **Red** (Stuck): Something is wrong. The agent needs help.
- **Blue** (Waiting): A decision is needed from you.
- **Gray** (Idle): Nothing is happening. The terminal is quiet.

---

## File reference

### App layer

| File | Purpose |
|------|---------|
| `App/DecodeApp.swift` | App entry point. Sets activation policy, registers fonts, defines menu bar with Git commands. |
| `App/AppState.swift` | Global state: API key, onboarding status, sidebar width. Persists via Keychain and UserDefaults. |
| `App/FontLoader.swift` | Registers bundled JetBrains Mono fonts via CoreText at launch. |

### Terminal layer

| File | Purpose |
|------|---------|
| `Terminal/PTYTap.swift` | Publishes raw PTY bytes on a Combine subject. Holds shell PID for cwd discovery. Supports command injection. |
| `Terminal/ANSIStripper.swift` | Strips CSI, OSC, and escape sequences. Filters spinner noise and thinking animations. |
| `Terminal/TerminalContainerView.swift` | NSViewRepresentable wrapping SwiftTerm. Subclasses `LocalProcessTerminalView` to tap `dataReceived`. Manages keyboard focus. |

### Agent layer

| File | Purpose |
|------|---------|
| `Agent/AgentGrammarProtocol.swift` | Protocol defining `confidence(for:)` and `annotate(chunk:)`. Also defines the `AgentType` enum. |
| `Agent/ChunkAssembler.swift` | Buffers PTY bytes, flushes on 500ms timer or 2KB threshold, produces `TerminalChunk` values. |
| `Agent/ClaudeCodeGrammar.swift` | Regex-based pattern matcher for Claude Code. Detects tool calls, file ops, permissions, tests, errors. |

### Narration layer

| File | Purpose |
|------|---------|
| `Narration/NarrationContext.swift` | Sliding window of annotated chunks. Serializes context for the Claude API. Manages token budget. |
| `Narration/NarrationEngine.swift` | Trigger policy, Claude API orchestration, response parsing, dedup, retry logic. |
| `Narration/ClaudeAPIClient.swift` | Streaming HTTP client for the Anthropic Messages API. Uses SSE parsing and prompt caching. |

### Services layer

| File | Purpose |
|------|---------|
| `Services/SessionController.swift` | Central orchestrator. Owns the full pipeline from PTY to sidebar UI. Runs narration timer. |
| `Services/GitMonitor.swift` | Polls git state every 3s. Resolves cwd via `proc_pidinfo`. Detects branch, diff stats, new commits. |
| `Services/SessionPersistence.swift` | Auto-saves narration entries and commits to `~/Library/Application Support/Decode/Sessions/` as JSON. |
| `Services/KeychainService.swift` | Reads and writes the Anthropic API key to macOS Keychain. |

### Models

| File | Purpose |
|------|---------|
| `Models/TerminalChunk.swift` | A cleaned chunk of terminal output: text, timestamp, byte count. |
| `Models/AnnotatedChunk.swift` | A `TerminalChunk` paired with its semantic `[ChunkLabel]` array. |
| `Models/ChunkLabel.swift` | Enum of semantic labels: toolCall, fileEdit, permissionPrompt, testRun, error, etc. Also defines `FileOp`. |
| `Models/NarrationEntry.swift` | A single sidebar narration: text, timestamp, status, formatted time label. |
| `Models/SidebarItem.swift` | Union type for sidebar feed items: `.narration` or `.commit`. |
| `Models/SessionStatus.swift` | Enum: `on_route`, `drifting`, `stuck`, `waiting_for_input`, `idle`. Includes display labels. |
| `Models/GitState.swift` | Snapshot of git state (branch, hash, diff stats). Also defines `GitCommitInfo`. |

### UI layer

| File | Purpose |
|------|---------|
| `UI/MainWindowView.swift` | HSplitView: terminal left, sidebar right. Manages onboarding gate and settings sheet. |
| `UI/NarrationSidebarView.swift` | The warm cream sidebar. Renders header, git info, status card, and scrolling feed of sidebar items. |
| `UI/NarrationEntryView.swift` | Renders a single narration entry. Uses a distinct blue card style for `waiting_for_input`. |
| `UI/StatusPillView.swift` | Colored capsule showing current session status (On Route, Drifting, Stuck, Waiting, Idle). |
| `UI/GitBranchView.swift` | Compact branch name + diff stats display in the sidebar header. |
| `UI/GitActionsView.swift` | Commit/Push/PR buttons with keyboard shortcut badges. Injects commands via PTYTap. |
| `UI/GitCommitCardView.swift` | Amber-accented card for detected commits. Shows message, hash, file count, diff stats. |
| `UI/OnboardingView.swift` | Three-step onboarding flow: welcome, how-it-works, API key entry. |
| `UI/SettingsView.swift` | API key management sheet. Saves to Keychain. |

---

## How to add support for a new agent

To add support for a new AI coding agent (e.g., Codex, Aider, Cursor Agent):

### 1. Add the agent type

In `AgentGrammarProtocol.swift`, add a case to the `AgentType` enum:

```swift
enum AgentType: String, Codable {
    case claudeCode = "claude_code"
    case codex
    case aider
    case myNewAgent = "my_new_agent"  // Add your agent here
    case unknown
}
```

### 2. Implement the grammar

Create a new file in `Sources/Decode/Agent/` (e.g., `CodexGrammar.swift`) that conforms to `AgentGrammarProtocol`:

```swift
struct CodexGrammar: AgentGrammarProtocol {
    let agentType: AgentType = .codex

    func confidence(for chunks: [TerminalChunk]) -> Double {
        // Look at the first ~20 chunks for startup signatures.
        // Return 0.0 (no match) to 1.0 (certain match).
        let text = chunks.prefix(20).map(\.text).joined(separator: "\n")

        // Example: Codex prints "OpenAI Codex" on startup
        if text.contains("OpenAI Codex") { return 0.95 }
        if text.contains("codex") { return 0.6 }
        return 0.0
    }

    func annotate(chunk: TerminalChunk) -> [ChunkLabel] {
        // Match agent-specific patterns and return semantic labels.
        // See ClaudeCodeGrammar.swift for the full pattern.
        var labels: [ChunkLabel] = []

        // ... your regex patterns here ...

        if labels.isEmpty {
            labels.append(.agentOutput(text: String(chunk.text.prefix(200))))
        }
        return labels
    }
}
```

### 3. Register the grammar

In `SessionController.swift`, add your grammar to the detection logic. Currently, the controller uses a single `ClaudeCodeGrammar` instance. To support multiple agents, you would create an array of grammars and probe each one during the detection phase:

```swift
private let grammars: [AgentGrammarProtocol] = [
    ClaudeCodeGrammar(),
    CodexGrammar(),
]
```

Then update `handleChunk` to iterate through grammars and lock on the one with the highest confidence.

### 4. Update the ANSI stripper (if needed)

If your agent uses unusual spinner characters or UI chrome that should be filtered, add patterns to `ANSIStripper.thinkingWords` or `ANSIStripper.startupNoisePatterns`.

---

## Key design decisions

**Why PTY tap instead of shell integration?** Shell hooks (precmd, preexec) require dotfile modification and break across shells. The PTY tap works with any shell, any agent, zero configuration. The tradeoff is that we see raw bytes instead of structured events, which is why the grammar layer exists.

**Why Claude Haiku instead of local inference?** The narration must be fast (under 2 seconds), cheap (pennies per session), and good at natural language. Haiku hits all three. Local models would eliminate the API key requirement but currently can't match the quality at this latency.

**Why polling for git instead of file watching?** File system events (`FSEvents`, `kqueue`) on `.git/` are noisy and race-prone during rebases and merges. Polling every 3 seconds with simple `git` commands is reliable, predictable, and easy to debug. The 6 git processes per cycle have negligible CPU impact.

**Why proc_pidinfo for cwd?** It's the only reliable way to get a process's current working directory on macOS without cooperation from the process itself. `lsof -p` works but spawns a heavy subprocess. The `proc_pidinfo` syscall is a single kernel call with no forking.

**Why 25 words max?** Early testing showed that longer narrations compete with the terminal for attention. The sidebar should be glanceable. 25 words forces the narration to be a headline, not a paragraph. This constraint is enforced in the system prompt, not in code -- Claude respects it reliably.
