import SwiftUI

/// A card displayed in the sidebar feed when a new git commit is detected.
struct GitCommitCardView: View {
    let commit: GitCommitInfo

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.commitColor)
                Text("Committed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.commitColor)
                Spacer()
                Text(timeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(theme.subtleText)
            }

            Text(commit.message)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(theme.primaryText)
                .lineSpacing(4)
                .lineLimit(2)

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                    Text("\(commit.filesChanged) file\(commit.filesChanged == 1 ? "" : "s")")
                        .font(.system(size: 11))
                }
                .foregroundColor(theme.subtleText)

                if commit.linesAdded > 0 {
                    Text("+\(commit.linesAdded)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.addedGreen)
                }
                if commit.linesRemoved > 0 {
                    Text("-\(commit.linesRemoved)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.removedRed)
                }

                Spacer()

                Text(commit.hash)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(theme.subtleText)
            }
        }
        .padding(14)
        .background(theme.commitColor.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.commitColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("Committed: \(commit.message), \(commit.filesChanged) files changed")
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: commit.timestamp)
    }
}
