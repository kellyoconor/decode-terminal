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
        VStack(alignment: .leading, spacing: Theme.spaceSM) {
            HStack {
                Text(entry.timeLabel)
                    .font(.system(size: Theme.fontFootnote, weight: .regular, design: .default))
                    .foregroundColor(theme.subtleText)
                Spacer()
                StatusPillView(status: entry.status)
            }
            Text(entry.text)
                .font(.system(size: Theme.fontBody, weight: .regular, design: .default))
                .foregroundColor(isRecent ? theme.primaryText : theme.mutedText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Theme.spaceXS)
        .accessibilityLabel("\(entry.status.displayLabel): \(entry.text)")
    }

    private var waitingCard: some View {
        VStack(alignment: .leading, spacing: Theme.spaceMD) {
            HStack(spacing: Theme.spaceMD) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.waitingBlue)
                Text("Needs your input")
                    .font(.system(size: Theme.fontSubhead, weight: .semibold))
                    .foregroundColor(theme.waitingBlue)
                Spacer()
                Text(entry.timeLabel)
                    .font(.system(size: Theme.fontFootnote))
                    .foregroundColor(theme.subtleText)
            }
            Text(entry.text)
                .font(.system(size: Theme.fontBody, weight: .regular, design: .default))
                .foregroundColor(theme.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(theme.waitingBlue.opacity(0.06))
        .cornerRadius(Theme.spaceMD)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.spaceMD)
                .stroke(theme.waitingBlue.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("Agent needs input: \(entry.text)")
    }

    private var isRecent: Bool {
        -entry.timestamp.timeIntervalSinceNow < 30
    }
}
