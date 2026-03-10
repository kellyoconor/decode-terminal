import Foundation

/// Snapshot of the current git repository state, polled periodically.
struct GitState {
    var branch: String = ""
    var headHash: String = ""
    var linesAdded: Int = 0
    var linesRemoved: Int = 0
    var filesChanged: Int = 0
    var isGitRepo: Bool = false
}

/// A detected git commit, shown as a card in the sidebar feed.
struct GitCommitInfo: Identifiable {
    let id = UUID()
    let hash: String
    let message: String
    let filesChanged: Int
    let linesAdded: Int
    let linesRemoved: Int
    let timestamp: Date
}
