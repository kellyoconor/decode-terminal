import Foundation

/// Maintains a sliding window of annotated chunks for the narration engine.
/// Manages token budget and serializes context for the Claude API.
final class NarrationContext {
    var originalPrompt: String = ""
    var agentType: AgentType = .unknown
    var currentStatus: SessionStatus = .idle
    var sessionStart: Date = Date()

    private(set) var annotatedChunks: [AnnotatedChunk] = []
    private(set) var recentNarrations: [NarrationEntry] = []

    private let maxEstimatedTokens = 4000

    /// Number of new chunks since last narration was generated.
    var newChunkCount: Int = 0

    func addChunk(_ chunk: AnnotatedChunk) {
        annotatedChunks.append(chunk)
        newChunkCount += 1
        pruneIfNeeded()
    }

    func addNarration(_ entry: NarrationEntry) {
        recentNarrations.append(entry)
        if recentNarrations.count > 3 {
            recentNarrations.removeFirst()
        }
        newChunkCount = 0
    }

    /// Serialize the context window for the Claude API user message.
    func serialize() -> String {
        var parts: [String] = []

        parts.append("AGENT: \(agentType.rawValue)")
        parts.append("SESSION DURATION: \(Int(-sessionStart.timeIntervalSinceNow))s")

        if !originalPrompt.isEmpty {
            parts.append("ORIGINAL USER REQUEST: \(originalPrompt)")
        }

        parts.append("CURRENT STATUS: \(currentStatus.rawValue)")

        if !recentNarrations.isEmpty {
            parts.append("\nPREVIOUS NARRATIONS (do not repeat):")
            for entry in recentNarrations {
                parts.append("- [\(entry.status.rawValue)] \(entry.text)")
            }
        }

        parts.append("\nNEW TERMINAL OUTPUT:")
        for chunk in annotatedChunks.suffix(10) {
            let labelStr = chunk.labels.map { describeLabel($0) }.joined(separator: ", ")
            parts.append("[\(labelStr)] \(chunk.chunk.text)")
        }

        return parts.joined(separator: "\n")
    }

    private func describeLabel(_ label: ChunkLabel) -> String {
        switch label {
        case .toolCall(let name, _): return "TOOL:\(name)"
        case .fileEdit(let path, let op): return "\(op.rawValue.uppercased()):\(path)"
        case .thinking: return "THINKING"
        case .permissionPrompt: return "PERMISSION_PROMPT"
        case .testRun(let cmd): return "TEST:\(cmd)"
        case .testResult(let p, let f): return "RESULT:passed=\(p),failed=\(f)"
        case .agentOutput: return "OUTPUT"
        case .userInput: return "USER_INPUT"
        case .commandExecution(let cmd): return "CMD:\(cmd)"
        case .error(let msg): return "ERROR:\(String(msg.prefix(50)))"
        case .sessionStart: return "SESSION_START"
        case .sessionEnd: return "SESSION_END"
        case .unknown: return "UNKNOWN"
        }
    }

    private func pruneIfNeeded() {
        var totalTokens = estimateTokens(serialize())
        while totalTokens > maxEstimatedTokens && annotatedChunks.count > 2 {
            annotatedChunks.removeFirst()
            totalTokens = estimateTokens(serialize())
        }
    }

    private func estimateTokens(_ text: String) -> Int {
        text.count / 4
    }
}
