import Foundation
import Combine

/// Orchestrates narration: decides when to fire, calls Claude API, parses responses.
@MainActor
final class NarrationEngine: ObservableObject {
    @Published var currentEntry: NarrationEntry?
    @Published var isStreaming: Bool = false

    private var apiClient: ClaudeAPIClient?
    private var lastNarrationTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 3.0
    private let chunkThreshold = 3

    private let systemPrompt = """
    You are the narration engine for Decode, a terminal companion app. You watch an AI coding agent working in a terminal and narrate what it's doing in plain, warm language — like a GPS giving directions.

    Your job:
    1. Describe what the agent just did in 1-3 short sentences. Use present tense. Be specific about file names and actions. Don't repeat what you already said in previous narrations.
    2. Assess the agent's status. Reply with exactly one of: on_route, drifting, stuck, waiting_for_input, idle.
    3. If the agent appears to be drifting from the original request, say so briefly.

    Format your response EXACTLY as:
    STATUS: <status>
    <narration text>

    Rules:
    - Never quote raw code or terminal output. Translate it into plain language.
    - Use "the agent" not "Claude" or "the AI."
    - Keep it under 50 words per narration.
    - If the agent is waiting for permission, say what it wants to do.
    - If you see test failures, mention what failed.
    - If the agent is reading files, say what it's likely looking for based on context.
    - Be calm and confident in tone, like a good navigator.
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
        if timeSinceLast >= 10.0 { return true }

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

    /// Fire a narration request and stream the response.
    func narrate(context: NarrationContext) async -> NarrationEntry? {
        guard let apiClient else { return nil }

        isStreaming = true
        lastNarrationTime = Date()

        let userMessage = context.serialize()
        var fullText = ""
        var status: SessionStatus = context.currentStatus

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
        } catch {
            fullText = "Narration unavailable: \(error.localizedDescription)"
            status = .idle
        }

        isStreaming = false

        guard !fullText.isEmpty else { return nil }

        let entry = NarrationEntry(
            timestamp: Date(),
            text: fullText,
            status: status
        )
        currentEntry = entry
        return entry
    }
}
