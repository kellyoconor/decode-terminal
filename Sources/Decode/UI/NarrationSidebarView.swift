import SwiftUI

/// The warm, light narration sidebar — the "human layer."
struct NarrationSidebarView: View {
    @ObservedObject var session: SessionController

    // Warm cream/paper palette
    private let sidebarBg = Color(red: 0.980, green: 0.980, blue: 0.969) // #FAFAF7
    private let cardBg = Color(red: 0.941, green: 0.941, blue: 0.922) // #F0F0EB
    private let borderColor = Color(red: 0.910, green: 0.910, blue: 0.890) // #E8E8E3
    private let mutedText = Color(red: 0.549, green: 0.549, blue: 0.522) // #8C8C85
    private let subtleText = Color(red: 0.639, green: 0.639, blue: 0.612) // #A3A39C

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Navigator")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(mutedText)
                    .tracking(1)
                Spacer()
                if session.isNarrating {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.204, green: 0.827, blue: 0.600)) // #34D399
                            .frame(width: 6, height: 6)
                        Text("Watching")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.204, green: 0.827, blue: 0.600))
                    }
                } else if session.detectedAgent != .unknown {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.204, green: 0.827, blue: 0.600))
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.204, green: 0.827, blue: 0.600))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()
                .background(borderColor)

            // Status card
            if session.currentStatus != .idle {
                HStack {
                    Text(session.currentStatus.displayLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.086, green: 0.639, blue: 0.290))
                    Spacer()
                    Text(sessionDuration)
                        .font(.system(size: 12))
                        .foregroundColor(subtleText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBg)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            // Narration feed — newest on top
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if session.narrationEntries.isEmpty {
                        emptyState
                    } else {
                        ForEach(session.narrationEntries.reversed()) { entry in
                            NarrationEntryView(entry: entry)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            Spacer(minLength: 0)
        }
        .background(sidebarBg)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waiting for an agent session...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(mutedText)
            Text("Launch Claude Code, Codex, or another AI agent in the terminal. Decode will start narrating automatically.")
                .font(.system(size: 12))
                .foregroundColor(subtleText)
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
