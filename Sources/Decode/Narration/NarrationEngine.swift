import Foundation
import Combine

/// Orchestrates narration: decides when to fire, calls Claude API, parses responses.
@MainActor
final class NarrationEngine: ObservableObject {
    @Published var currentEntry: NarrationEntry?
    @Published var isStreaming: Bool = false

    private var apiClient: ClaudeAPIClient?
    private var lastNarrationTime: Date = .distantPast
    private var lastStatus: SessionStatus = .idle
    private let minimumInterval: TimeInterval = 8.0
    private let chunkThreshold = 5
    private var consecutiveFailures = 0
    private let maxRetries = 2

    private let systemPrompt = """
    You narrate what an AI coding agent is doing in a terminal. You're like a calm GPS — short, clear, never overwhelming.

    RESPOND IN EXACTLY THIS FORMAT:
    STATUS: <on_route|drifting|stuck|waiting_for_input|idle>
    <narration>

    CRITICAL RULES:
    - Maximum 25 words. One sentence, rarely two. This is a HARD limit.
    - Present tense. Specific file names when relevant.
    - Say "the agent" not "Claude" or "the AI."
    - Never quote code. Translate to plain language.
    - Don't repeat previous narrations. Say something new or stay silent.
    - Skip spinner/loading noise entirely.
    - If waiting for permission: say what it wants to do, briefly.
    - Tone: calm, confident, like a good co-pilot.
    - "Twisting…", "Embellishing…", "Harmonizing…", "Composing…" etc. are NORMAL thinking animations. The agent is working. Status should be on_route, NOT stuck.
    - Agent startup/initialization (version info, prompts, settings) = idle or on_route, NOT stuck.
    - Only use "stuck" if the agent has clearly errored or been in a genuine error loop for 2+ minutes. A quiet terminal or idle prompt is NOT stuck — it's idle.
    - When the agent just started and is showing its initial prompt, use "idle" status.

    GOOD examples:
    "Reading package.json to check dependencies."
    "Writing the login component. Two files created so far."
    "Wants permission to edit index.html."
    "Running tests. 4 passed, 1 failed in auth module."
    "Stuck in a loop — same harmonizing output for 30 seconds."

    BAD examples (TOO LONG):
    "The agent has finished generating a complete link-in-bio page with social media icons, link cards (Website, Project, Newsletter, Shop, Buy Me a Coffee), and footer styling. It's asking permission to create the index.html file with this content."
    """

    func configure(apiKey: String) {
        apiClient = ClaudeAPIClient(apiKey: apiKey)
    }

    /// Determine if narration should fire based on context state.
    func shouldNarrate(context: NarrationContext) -> Bool {
        let timeSinceLast = -lastNarrationTime.timeIntervalSinceNow
        guard timeSinceLast >= minimumInterval else { return false }
        guard context.newChunkCount > 0 else { return false }

        // Fire on: enough new chunks, or status-changing events, or time threshold
        if context.newChunkCount >= chunkThreshold { return true }
        if timeSinceLast >= 15.0 { return true }

        // Fire immediately on permission prompts or errors
        let hasUrgentLabel = context.annotatedChunks.suffix(context.newChunkCount).contains { chunk in
            chunk.labels.contains { label in
                switch label {
                case .permissionPrompt, .error, .testResult: return true
                default: return false
                }
            }
        }
        if hasUrgentLabel { return true }

        return false
    }

    /// Fire a narration request with retry logic.
    func narrate(context: NarrationContext) async -> NarrationEntry? {
        guard let apiClient else { return nil }

        isStreaming = true
        lastNarrationTime = Date()

        let userMessage = context.serialize()
        var fullText = ""
        var status: SessionStatus = context.currentStatus
        var lastError: Error?

        for attempt in 0...maxRetries {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }

            fullText = ""
            lastError = nil

            do {
                for try await token in apiClient.stream(systemPrompt: systemPrompt, userMessage: userMessage) {
                    fullText += token
                }

                // Parse STATUS: line
                let lines = fullText.components(separatedBy: .newlines)
                if let statusLine = lines.first, statusLine.uppercased().hasPrefix("STATUS:") {
                    let rawStatus = statusLine
                        .replacingOccurrences(of: "STATUS:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                        .lowercased()
                    if let parsed = SessionStatus(rawValue: rawStatus) {
                        status = parsed
                    }
                    fullText = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
                }

                consecutiveFailures = 0
                break // Success
            } catch {
                lastError = error
                continue
            }
        }

        if let error = lastError, fullText.isEmpty {
            consecutiveFailures += 1
            if consecutiveFailures <= 3 {
                fullText = "Narration temporarily unavailable."
            } else {
                fullText = "Narration offline: \(error.localizedDescription)"
            }
            status = .idle
        }

        isStreaming = false

        guard !fullText.isEmpty else { return nil }

        // Dedup: don't repeat waiting_for_input back-to-back
        if status == .waitingForInput && lastStatus == .waitingForInput {
            isStreaming = false
            return nil
        }
        lastStatus = status

        let entry = NarrationEntry(
            timestamp: Date(),
            text: fullText,
            status: status
        )
        currentEntry = entry
        return entry
    }
}
