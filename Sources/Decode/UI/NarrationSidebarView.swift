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
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(theme.mutedText)
                    .tracking(1)
                    .accessibilityLabel("Navigator sidebar")
                Spacer()
                if session.isNarrating {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.watchingGreen)
                            .frame(width: 6, height: 6)
                        Text("Watching")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.watchingGreen)
                    }
                    .accessibilityLabel("Status: Watching")
                } else if session.detectedAgent != .unknown {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.watchingGreen)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.watchingGreen)
                    }
                    .accessibilityLabel("Status: Connected")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            // Git branch + diff stats + quick actions
            if session.gitState.isGitRepo {
                VStack(alignment: .leading, spacing: 10) {
                    GitBranchView(gitState: session.gitState)
                    GitActionsView(ptyTap: session.ptyTap, gitState: session.gitState)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            Divider()
                .background(theme.borderColor)

            // Status card
            if session.currentStatus != .idle {
                HStack {
                    Text(session.currentStatus.displayLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.onRouteColor)
                    Spacer()
                    Text(sessionDuration)
                        .font(.system(size: 12))
                        .foregroundColor(theme.subtleText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.cardBg)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.borderColor, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            // Sidebar feed — newest on top, narration + commit cards interleaved
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
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
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            Spacer(minLength: 0)
        }
        .background(theme.sidebarBg)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waiting for an agent session...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.mutedText)
            Text("Launch Claude Code, Codex, or another AI agent in the terminal. Decode will start narrating automatically.")
                .font(.system(size: 12))
                .foregroundColor(theme.subtleText)
                .lineSpacing(4)
        }
        .padding(.top, 24)
    }

    private var sessionDuration: String {
        let interval = session.narrationEntries.first?.timestamp.timeIntervalSinceNow ?? 0
        let seconds = Int(-interval)
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)m \(s)s"
    }
}
