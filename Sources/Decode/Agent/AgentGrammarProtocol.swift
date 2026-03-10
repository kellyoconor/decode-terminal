import Foundation

/// Identifies the type of AI coding agent running in the terminal.
enum AgentType: String, Codable {
    case claudeCode = "claude_code"
    case codex
    case aider
    case unknown
}

/// Protocol for agent-specific pattern matching against terminal output.
protocol AgentGrammarProtocol {
    var agentType: AgentType { get }

    /// Returns a confidence score (0.0-1.0) that this agent is running,
    /// based on the accumulated chunks seen so far.
    func confidence(for chunks: [TerminalChunk]) -> Double

    /// Annotate a single chunk with semantic labels based on agent-specific patterns.
    func annotate(chunk: TerminalChunk) -> [ChunkLabel]
}
