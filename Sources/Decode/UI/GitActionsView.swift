import SwiftUI

/// Quick git action buttons for the sidebar.
struct GitActionsView: View {
    let ptyTap: PTYTap
    let gitState: GitState

    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    @State private var showCommitConfirm = false
    @State private var showPushConfirm = false
    @State private var showPRConfirm = false
    @State private var commitMessage = ""

    var body: some View {
        HStack(spacing: Theme.spaceMD) {
            actionButton(icon: "arrow.triangle.branch", label: "Commit", shortcut: "\u{2318}K") {
                showCommitConfirm = true
            }
            .disabled(gitState.filesChanged == 0 && gitState.linesAdded == 0)

            actionButton(icon: "arrow.up.circle", label: "Push", shortcut: "\u{21E7}\u{2318}P") {
                showPushConfirm = true
            }

            actionButton(icon: "arrow.triangle.pull", label: "PR", shortcut: "\u{21E7}\u{2318}R") {
                showPRConfirm = true
            }
        }
        .sheet(isPresented: $showCommitConfirm) {
            commitSheet
        }
        .alert("Push to remote?", isPresented: $showPushConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Push") { ptyTap.injectCommand("git push") }
        } message: {
            Text("This will push \(gitState.branch) to origin.")
        }
        .alert("Create pull request?", isPresented: $showPRConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Create PR") { ptyTap.injectCommand("gh pr create --fill") }
        } message: {
            Text("This will create a PR from \(gitState.branch) using gh.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitCommitShortcut)) { _ in
            if gitState.isGitRepo { showCommitConfirm = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPushShortcut)) { _ in
            if gitState.isGitRepo { showPushConfirm = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gitPRShortcut)) { _ in
            if gitState.isGitRepo { showPRConfirm = true }
        }
    }

    private func actionButton(icon: String, label: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.spaceXS) {
                Image(systemName: icon)
                    .font(.system(size: Theme.fontCaption))
                Text(label)
                    .font(.system(size: Theme.fontFootnote, weight: .medium))
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: Theme.fontCaption2, weight: .medium, design: .rounded))
                        .foregroundColor(theme.shortcutColor)
                        .padding(.horizontal, Theme.spaceXS)
                        .padding(.vertical, 1)
                        .background(theme.shortcutBg)
                        .cornerRadius(Theme.radiusSM)
                }
            }
            .foregroundColor(theme.actionColor)
            .padding(.horizontal, 10)
            .padding(.vertical, Theme.spaceSM)
            .background(theme.buttonBg)
            .cornerRadius(Theme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .stroke(theme.borderColor, lineWidth: Theme.borderWidth)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Git \(label)")
        .accessibilityHint("Double-tap to \(label.lowercased())")
    }

    /// POSIX-safe shell escaping: wraps in single quotes, escapes embedded single quotes.
    private func shellEscape(_ str: String) -> String {
        let escaped = str.replacingOccurrences(of: "'", with: "'\\''")
        let cleaned = escaped.unicodeScalars.filter { scalar in
            scalar.value >= 0x20 || scalar == "\n" || scalar == "\t"
        }
        return "'" + String(String.UnicodeScalarView(cleaned)) + "'"
    }

    private var commitSheet: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            Text("Commit changes")
                .font(.system(size: Theme.fontCallout, weight: .semibold))

            HStack(spacing: 10) {
                if gitState.linesAdded > 0 {
                    Text("+\(gitState.linesAdded)")
                        .font(.system(size: Theme.fontSubhead, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.addedGreen)
                }
                if gitState.linesRemoved > 0 {
                    Text("-\(gitState.linesRemoved)")
                        .font(.system(size: Theme.fontSubhead, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.removedRed)
                }
                Text("\(gitState.filesChanged) file\(gitState.filesChanged == 1 ? "" : "s")")
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.mutedText)
            }

            TextField("Commit message", text: $commitMessage)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: Theme.fontBody))

            HStack {
                Spacer()
                Button("Cancel") {
                    showCommitConfirm = false
                    commitMessage = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Commit") {
                    let msg = commitMessage.isEmpty ? "Update" : commitMessage
                    let escaped = shellEscape(msg)
                    ptyTap.injectCommand("git add -A && git commit -m \(escaped)")
                    showCommitConfirm = false
                    commitMessage = ""
                }
                .keyboardShortcut(.defaultAction)
                .disabled(commitMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
