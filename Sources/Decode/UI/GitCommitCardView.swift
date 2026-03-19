import SwiftUI

/// A card displayed in the sidebar feed when a new git commit is detected.
struct GitCommitCardView: View {
    let commit: GitCommitInfo

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceMD) {
            HStack(spacing: Theme.spaceMD) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.commitColor)
                Text("Committed")
                    .font(.system(size: Theme.fontSubhead, weight: .semibold))
                    .foregroundColor(theme.commitColor)
                Spacer()
                Text(timeLabel)
                    .font(.system(size: Theme.fontFootnote))
                    .foregroundColor(theme.subtleText)
            }

            Text(commit.message)
                .font(.system(size: Theme.fontBody, weight: .regular, design: .default))
                .foregroundColor(theme.primaryText)
                .lineSpacing(Theme.lineSpaceBody)
                .lineLimit(2)

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: Theme.fontCaption))
                    Text("\(commit.filesChanged) file\(commit.filesChanged == 1 ? "" : "s")")
                        .font(.system(size: Theme.fontFootnote))
                }
                .foregroundColor(theme.subtleText)

                if commit.linesAdded > 0 {
                    Text("+\(commit.linesAdded)")
                        .font(.system(size: Theme.fontFootnote, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.addedGreen)
                }
                if commit.linesRemoved > 0 {
                    Text("-\(commit.linesRemoved)")
                        .font(.system(size: Theme.fontFootnote, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.removedRed)
                }

                Spacer()

                Text(commit.hash)
                    .font(.system(size: Theme.fontCaption, design: .monospaced))
                    .foregroundColor(theme.subtleText)
            }
        }
        .padding(Theme.cardPadding)
        .background(theme.commitColor.opacity(Theme.opacityCardTint))
        .cornerRadius(Theme.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(theme.commitColor.opacity(Theme.opacityCardStroke), lineWidth: Theme.borderWidth)
        )
        .accessibilityLabel("Committed: \(commit.message), \(commit.filesChanged) files changed")
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: commit.timestamp)
    }
}
