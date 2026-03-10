import Foundation

/// A single narration entry displayed in the sidebar.
struct NarrationEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let status: SessionStatus

    var relativeTime: String {
        let seconds = Int(-timestamp.timeIntervalSinceNow)
        if seconds < 5 { return "Just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
