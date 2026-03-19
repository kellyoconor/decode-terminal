import SwiftUI

struct NarrationEntryView: View {
    let entry: NarrationEntry

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        if entry.status == .waitingForInput {
            waitingCard
        } else {
            standardEntry
        }
    }

    private var standardEntry: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.timeLabel)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(theme.subtleText)
                Spacer()
                StatusPillView(status: entry.status)
            }
            Text(entry.text)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(isRecent ? theme.primaryText : theme.mutedText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(entry.status.displayLabel): \(entry.text)")
    }

    /// Distinct card for when the agent needs user input
    private var waitingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.waitingBlue)
                Text("Needs your input")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.waitingBlue)
                Spacer()
                Text(entry.timeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(theme.subtleText)
            }
            Text(entry.text)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(theme.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(theme.waitingBlue.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.waitingBlue.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("Agent needs input: \(entry.text)")
    }

    private var isRecent: Bool {
        -entry.timestamp.timeIntervalSinceNow < 30
    }
}
