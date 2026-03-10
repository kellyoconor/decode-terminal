import Foundation

/// Semantic labels applied to terminal chunks by agent grammars.
enum ChunkLabel {
    case toolCall(name: String, summary: String)
    case fileEdit(path: String, operation: FileOp)
    case thinking
    case permissionPrompt(action: String)
    case testRun(command: String)
    case testResult(passed: Int, failed: Int)
    case agentOutput(text: String)
    case userInput(text: String)
    case commandExecution(command: String)
    case error(message: String)
    case sessionStart
    case sessionEnd
    case unknown(text: String)
}

enum FileOp: String {
    case read, write, create, delete, edit
}
