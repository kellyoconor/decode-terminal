import SwiftUI

struct StatusPillView: View {
    let status: SessionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(status.displayLabel)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .onRoute: return Color(red: 0.086, green: 0.639, blue: 0.290) // #16A34A
        case .drifting: return Color(red: 0.961, green: 0.620, blue: 0.043) // #F59E0B
        case .stuck: return Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444
        case .waitingForInput: return Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6
        case .idle: return Color(red: 0.549, green: 0.549, blue: 0.522) // #8C8C85
        }
    }
}
