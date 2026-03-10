import Foundation

/// A terminal chunk with semantic labels applied by the agent grammar.
struct AnnotatedChunk: Identifiable {
    let id = UUID()
    let chunk: TerminalChunk
    let labels: [ChunkLabel]
}
