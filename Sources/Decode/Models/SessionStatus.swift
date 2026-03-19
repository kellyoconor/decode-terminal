import Foundation

/// The agent's current status as determined by the narration engine.
enum SessionStatus: String, Codable {
    case thinking = "thinking"
    case exploring = "exploring"
    case blocked = "blocked"
    case waitingForInput = "waiting_for_input"
    case idle = "idle"

    var displayLabel: String {
        switch self {
        case .thinking: return "Thinking"
        case .exploring: return "Exploring"
        case .blocked: return "Blocked"
        case .waitingForInput: return "Waiting"
        case .idle: return "Idle"
        }
    }
}
