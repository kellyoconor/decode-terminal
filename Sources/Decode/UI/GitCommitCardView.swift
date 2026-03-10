import SwiftUI

/// A card displayed in the sidebar feed when a new git commit is detected.
struct GitCommitCardView: View {
    let commit: GitCommitInfo

    private let commitColor = Color(red: 0.933, green: 0.510, blue: 0.118) // warm amber
    private let addedGreen = Color(red: 0.204, green: 0.718, blue: 0.357)
    private let removedRed = Color(red: 0.910, green: 0.329, blue: 0.329)
    private let subtleText = Color(red: 0.639, green: 0.639, blue: 0.612)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(commitColor)
                Text("Committed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(commitColor)
                Spacer()
                Text(timeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(subtleText)
            }

            Text(commit.message)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .lineSpacing(4)
                .lineLimit(2)

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                    Text("\(commit.filesChanged) file\(commit.filesChanged == 1 ? "" : "s")")
                        .font(.system(size: 11))
                }
                .foregroundColor(subtleText)

                if commit.linesAdded > 0 {
                    Text("+\(commit.linesAdded)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(addedGreen)
                }
                if commit.linesRemoved > 0 {
                    Text("-\(commit.linesRemoved)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(removedRed)
                }

                Spacer()

                Text(commit.hash)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(subtleText)
            }
        }
        .padding(14)
        .background(commitColor.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(commitColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: commit.timestamp)
    }
}
