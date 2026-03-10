import Foundation

/// Union type for items shown in the narration sidebar feed.
enum SidebarItem: Identifiable {
    case narration(NarrationEntry)
    case commit(GitCommitInfo)

    var id: UUID {
        switch self {
        case .narration(let entry): return entry.id
        case .commit(let info): return info.id
        }
    }

    var timestamp: Date {
        switch self {
        case .narration(let entry): return entry.timestamp
        case .commit(let info): return info.timestamp
        }
    }
}
