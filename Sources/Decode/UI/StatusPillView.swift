import SwiftUI

struct StatusPillView: View {
    let status: SessionStatus

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

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
        .accessibilityLabel("Status: \(status.displayLabel)")
    }

    private var statusColor: Color {
        switch status {
        case .onRoute: return theme.onRouteColor
        case .drifting: return theme.driftingAmber
        case .stuck: return theme.stuckRed
        case .waitingForInput: return theme.waitingBlue
        case .idle: return theme.idleGray
        }
    }
}
