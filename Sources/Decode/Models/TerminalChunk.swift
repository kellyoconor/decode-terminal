import Foundation

/// A cleaned chunk of terminal output, stripped of ANSI codes.
struct TerminalChunk: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let byteCount: Int
}
