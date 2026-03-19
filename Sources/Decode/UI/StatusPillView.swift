import SwiftUI

struct StatusPillView: View {
    let status: SessionStatus

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        HStack(spacing: Theme.spaceSM) {
            Circle()
                .fill(statusColor)
                .frame(width: Theme.spaceSM, height: Theme.spaceSM)
            Text(status.displayLabel)
                .font(.system(size: Theme.fontFootnote, weight: .semibold, design: .default))
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
