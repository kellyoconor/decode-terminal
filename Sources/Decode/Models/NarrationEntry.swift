import Foundation

/// A single narration entry displayed in the sidebar.
struct NarrationEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let status: SessionStatus

    /// Formatted timestamp showing actual time, not relative
    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
}
