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
                .lineSpacing(Theme.lineSpaceBody)
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
                .lineSpacing(Theme.lineSpaceBody)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.cardPadding)
        .background(theme.waitingBlue.opacity(Theme.opacityCardTint))
        .cornerRadius(Theme.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(theme.waitingBlue.opacity(Theme.opacityCardStroke), lineWidth: Theme.borderWidth)
        )
        .accessibilityLabel("Agent needs input: \(entry.text)")
    }

    private var isRecent: Bool {
        -entry.timestamp.timeIntervalSinceNow < 30
    }
}
