import SwiftUI

/// Compact branch + diff stats display for the sidebar header.
struct GitBranchView: View {
    let gitState: GitState

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        HStack(spacing: 10) {
            // Branch name
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11))
                    .foregroundColor(theme.mutedText)
                Text(gitState.branch)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(theme.mutedText)
                    .lineLimit(1)
            }
            .accessibilityLabel("Git branch: \(gitState.branch)")

            Spacer()

            // Diff stats
            if gitState.linesAdded > 0 || gitState.linesRemoved > 0 {
                HStack(spacing: 6) {
                    Text("+\(gitState.linesAdded)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.addedGreen)
                    Text("-\(gitState.linesRemoved)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.removedRed)
                }
                .accessibilityLabel("\(gitState.linesAdded) lines added, \(gitState.linesRemoved) lines removed")
            }

            // Files changed
            if gitState.filesChanged > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                        .foregroundColor(theme.mutedText)
                    Text("\(gitState.filesChanged)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.mutedText)
                }
            }
        }
    }
}
