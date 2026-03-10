# Decode

**Google Maps for your terminal.**

Decode is a native macOS terminal emulator with an AI-powered narration sidebar. It watches what your coding agent is doing and translates the wall of terminal output into short, calm, plain-language updates -- in real time.

You launch Claude Code (or Codex, or any AI agent). You work. The sidebar tells you what's happening: which files the agent is reading, what it's building, when it needs your permission, whether it's on track or going in circles. You're still driving. You never feel lost.

---

## Features

### Real-time narration sidebar

A warm cream sidebar sits beside your dark terminal. Every few seconds, it produces a one-sentence update (25 words max) describing what the agent is doing right now. No jargon, no code dumps -- just plain language.

### Git awareness

Live branch name and diff stats (`+42 -8`, 3 files) update in the sidebar header as the agent works. When a commit lands, a distinct amber card appears in the feed with the message, hash, and file stats.

### Quick git actions

Commit, push, and create PRs without leaving the terminal. Each action has a keyboard shortcut and a confirmation dialog so nothing fires by accident.

| Action | Shortcut |
|--------|----------|
| Commit | `Cmd+K` |
| Push | `Shift+Cmd+P` |
| Create PR | `Shift+Cmd+R` |

### "Needs your input" cards

When the agent asks for permission (edit a file, run a command, etc.), a distinct blue card appears in the sidebar so you notice immediately -- even if the terminal output has scrolled past it.

### Status system

A colored status pill shows the agent's current state at a glance:

| Status | Color | Meaning |
|--------|-------|---------|
| On Route | Green | Working normally, making progress |
| Drifting | Amber | Producing output but may be off track |
| Stuck | Red | Error loop or repeated failures |
| Waiting | Blue | Needs your input or permission |
| Idle | Gray | No active agent work |

### Agent detection

Decode auto-detects Claude Code by recognizing its startup patterns (box-drawing characters, "anthropic" references, tool-call headers). It works with any terminal agent -- the grammar system is pluggable.

### Session persistence

Every narration entry and commit card is auto-saved to `~/Library/Application Support/Decode/Sessions/` as JSON. Sessions are keyed by start time and retained across app restarts.

### Bundled JetBrains Mono

The terminal ships with JetBrains Mono (Regular, Medium, Bold) registered at launch. No system font installation required.

---

## How it works

1. **Run your agent.** Launch Claude Code, Codex, or any AI coding agent inside Decode's terminal. It's a real terminal -- your shell, your environment, your dotfiles.

2. **The sidebar narrates.** Decode taps the PTY byte stream, strips ANSI codes, assembles chunks, classifies them with an agent grammar, and sends context to Claude Haiku for a one-sentence narration. The whole pipeline runs in the background. The terminal is never slowed down.

3. **You stay in flow.** Glance at the sidebar when you want context. Ignore it when you don't. Commit, push, or create a PR with a shortcut. The narration scrolls like a timeline -- newest at the top.

---

## Installation

### Requirements

- macOS 14 (Sonoma) or later
- An [Anthropic API key](https://console.anthropic.com/) (Decode uses Claude Haiku for narration)

### Download

Grab the latest `Decode.dmg` from [Releases](https://github.com/user/decode-app/releases) and drag to Applications.

### Build from source

```bash
git clone https://github.com/user/decode-app.git
cd decode-app
swift build -c release
./scripts/build-app.sh
open dist/Decode.app
```

The build script compiles a release binary, creates a proper `.app` bundle with an `Info.plist`, and copies bundled resources (fonts). To create a DMG:

```bash
hdiutil create -volname Decode -srcfolder dist -ov -format UDZO dist/Decode.dmg
```

---

## Configuration

On first launch, Decode walks you through a three-step onboarding:

1. Welcome screen
2. How it works overview
3. API key entry

Your Anthropic API key is stored in macOS Keychain (not on disk, not in plaintext). You can update it anytime from **Settings** (`Cmd+,`).

Decode uses Claude Haiku (`claude-haiku-4-5-20251001`) with streaming, prompt caching, and a 256-token max response. Narration costs are minimal -- a typical hour-long session uses a few cents of API calls.

---

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+K` | Commit changes (with message dialog) |
| `Shift+Cmd+P` | Push to remote |
| `Shift+Cmd+R` | Create pull request (via `gh pr create --fill`) |
| `Cmd+N` | New session |
| `Cmd+,` | Settings |

---

## Architecture (for contributors)

Decode is a SwiftUI app built on [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for terminal emulation. The narration pipeline is fully decoupled from the terminal -- it reads a copy of the byte stream and never interferes with normal terminal operation.

**Pipeline:**

```
PTY bytes → ANSIStripper → ChunkAssembler → ClaudeCodeGrammar → NarrationContext → NarrationEngine → Sidebar UI
```

**Key components:**

- **PTYTap** intercepts raw bytes from SwiftTerm's `dataReceived` callback via a `TappedTerminalView` subclass. Zero-copy, non-blocking.
- **ChunkAssembler** buffers bytes and flushes on a 500ms timer or 2KB threshold, producing clean `TerminalChunk` values.
- **ClaudeCodeGrammar** matches chunks against regex patterns to produce semantic labels: tool calls, file edits, permission prompts, test results, errors.
- **NarrationContext** maintains a sliding window of annotated chunks (pruned to ~4000 estimated tokens) plus the last 3 narrations for dedup.
- **NarrationEngine** decides when to fire (8s minimum interval, 5-chunk threshold, immediate on permission/error) and streams the response from Claude Haiku.
- **GitMonitor** resolves the shell's cwd via `proc_pidinfo`, polls `git` every 3 seconds, and detects new commits by comparing HEAD hashes.
- **SessionPersistence** auto-saves narration entries and commit info to `~/Library/Application Support/Decode/Sessions/` as JSON.

For a deeper dive, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Contributing

Contributions are welcome. Some areas that would benefit from help:

- **New agent grammars.** Implement `AgentGrammarProtocol` to support Codex, Aider, or other agents. See `ClaudeCodeGrammar.swift` for the pattern.
- **Multi-session support.** The data model supports it; the UI needs tab/window management.
- **Session history browser.** `SessionPersistence` already saves sessions -- a history view would make them accessible.
- **Tests.** The `Tests/DecodeTests/` directory is waiting.

Before submitting a PR, make sure the project builds cleanly:

```bash
swift build
```

---

## License

MIT
