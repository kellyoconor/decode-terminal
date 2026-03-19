import SwiftUI

/// The warm, light narration sidebar — the "human layer."
struct NarrationSidebarView: View {
    @ObservedObject var session: SessionController
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Navigator")
                    .font(.system(size: Theme.fontSubhead, weight: .medium, design: .default))
                    .foregroundColor(theme.mutedText)
                    .tracking(1)
                    .accessibilityLabel("Navigator sidebar")
                Spacer()
                if session.isNarrating {
                    HStack(spacing: Theme.spaceSM) {
                        Circle()
                            .fill(theme.watchingGreen)
                            .frame(width: Theme.indicatorDot, height: Theme.indicatorDot)
                        Text("Watching")
                            .font(.system(size: Theme.fontFootnote, weight: .medium))
                            .foregroundColor(theme.watchingGreen)
                    }
                    .accessibilityLabel("Status: Watching")
                } else if session.detectedAgent != .unknown {
                    HStack(spacing: Theme.spaceSM) {
                        Circle()
                            .fill(theme.watchingGreen)
                            .frame(width: Theme.indicatorDot, height: Theme.indicatorDot)
                        Text("Connected")
                            .font(.system(size: Theme.fontFootnote, weight: .medium))
                            .foregroundColor(theme.watchingGreen)
                    }
                    .accessibilityLabel("Status: Connected")
                }
            }
            .padding(.horizontal, Theme.spaceXXL)
            .padding(.vertical, Theme.spaceXL)

            // Git branch + diff stats + quick actions
            if session.gitState.isGitRepo {
                VStack(alignment: .leading, spacing: 10) {
                    GitBranchView(gitState: session.gitState)
                    GitActionsView(ptyTap: session.ptyTap, gitState: session.gitState)
                }
                .padding(.horizontal, Theme.spaceXXL)
                .padding(.bottom, Theme.spaceLG)
            }

            Divider()
                .background(theme.borderColor)

            // Status card
            if session.currentStatus != .idle {
                HStack {
                    Text(session.currentStatus.displayLabel)
                        .font(.system(size: Theme.fontSubhead, weight: .semibold))
                        .foregroundColor(theme.activeColor)
                    Spacer()
                    Text(sessionDuration)
                        .font(.system(size: Theme.fontSubhead))
                        .foregroundColor(theme.subtleText)
                }
                .padding(.horizontal, Theme.spaceXL)
                .padding(.vertical, Theme.spaceLG)
                .background(theme.cardBg)
                .cornerRadius(Theme.radiusLG)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusLG)
                        .stroke(theme.borderColor, lineWidth: Theme.borderWidth)
                )
                .padding(.horizontal, Theme.spaceXXL)
                .padding(.top, Theme.spaceXL)
            }

            // Sidebar feed — newest on top, narration + commit cards interleaved
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.spaceXL) {
                    if session.sidebarItems.isEmpty {
                        emptyState
                    } else {
                        ForEach(session.sidebarItems.reversed()) { item in
                            switch item {
                            case .narration(let entry):
                                NarrationEntryView(entry: entry)
                            case .commit(let commitInfo):
                                GitCommitCardView(commit: commitInfo)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.spaceXXL)
                .padding(.vertical, Theme.spaceXL)
            }

            Spacer(minLength: 0)
        }
        .background(theme.sidebarBg)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Theme.spaceLG) {
            Image(systemName: "terminal.fill")
                .font(.system(size: Theme.iconEmptyState))
                .foregroundColor(theme.borderColor)
            Text("Waiting for an agent session...")
                .font(.system(size: Theme.fontBody, weight: .medium))
                .foregroundColor(theme.mutedText)
            Text("Launch Claude Code, Codex, or another AI agent in the terminal. Decode will start narrating automatically.")
                .font(.system(size: Theme.fontSubhead))
                .foregroundColor(theme.subtleText)
                .lineSpacing(Theme.lineSpaceBody)
        }
        .padding(.top, Theme.spaceXXL)
    }

    private var sessionDuration: String {
        let interval = session.narrationEntries.first?.timestamp.timeIntervalSinceNow ?? 0
        let seconds = Int(-interval)
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)m \(s)s"
    }
}
