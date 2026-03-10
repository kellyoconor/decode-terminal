import SwiftUI

/// Compact branch + diff stats display for the sidebar header.
struct GitBranchView: View {
    let gitState: GitState

    private let mutedText = Color(red: 0.549, green: 0.549, blue: 0.522)
    private let addedGreen = Color(red: 0.204, green: 0.718, blue: 0.357)
    private let removedRed = Color(red: 0.910, green: 0.329, blue: 0.329)

    var body: some View {
        HStack(spacing: 10) {
            // Branch name
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11))
                    .foregroundColor(mutedText)
                Text(gitState.branch)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(mutedText)
                    .lineLimit(1)
            }

            Spacer()

            // Diff stats
            if gitState.linesAdded > 0 || gitState.linesRemoved > 0 {
                HStack(spacing: 6) {
                    Text("+\(gitState.linesAdded)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(addedGreen)
                    Text("-\(gitState.linesRemoved)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(removedRed)
                }
            }

            // Files changed
            if gitState.filesChanged > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                        .foregroundColor(mutedText)
                    Text("\(gitState.filesChanged)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(mutedText)
                }
            }
        }
    }
}
