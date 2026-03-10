import Foundation

/// The agent's current status as determined by the narration engine.
enum SessionStatus: String, Codable {
    case onRoute = "on_route"
    case drifting = "drifting"
    case stuck = "stuck"
    case waitingForInput = "waiting_for_input"
    case idle = "idle"

    var displayLabel: String {
        switch self {
        case .onRoute: return "On Route"
        case .drifting: return "Drifting"
        case .stuck: return "Stuck"
        case .waitingForInput: return "Waiting"
        case .idle: return "Idle"
        }
    }
}
