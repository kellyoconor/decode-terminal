import SwiftUI

/// Quick git action buttons for the sidebar.
struct GitActionsView: View {
    let ptyTap: PTYTap
    let gitState: GitState

    @State private var showCommitConfirm = false
    @State private var showPushConfirm = false
    @State private var showPRConfirm = false
    @State private var commitMessage = ""

    private let borderColor = Color(red: 0.910, green: 0.910, blue: 0.890)
    private let mutedText = Color(red: 0.549, green: 0.549, blue: 0.522)
    private let actionColor = Color(red: 0.102, green: 0.102, blue: 0.102)

    var body: some View {
        HStack(spacing: 8) {
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

    private let shortcutColor = Color(red: 0.749, green: 0.749, blue: 0.729)

    private func actionButton(icon: String, label: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(shortcutColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(red: 0.941, green: 0.941, blue: 0.922))
                        .cornerRadius(3)
                }
            }
            .foregroundColor(actionColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var commitSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commit changes")
                .font(.system(size: 14, weight: .semibold))

            HStack(spacing: 10) {
                if gitState.linesAdded > 0 {
                    Text("+\(gitState.linesAdded)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.204, green: 0.718, blue: 0.357))
                }
                if gitState.linesRemoved > 0 {
                    Text("-\(gitState.linesRemoved)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.910, green: 0.329, blue: 0.329))
                }
                Text("\(gitState.filesChanged) file\(gitState.filesChanged == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(mutedText)
            }

            TextField("Commit message", text: $commitMessage)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))

            HStack {
                Spacer()
                Button("Cancel") {
                    showCommitConfirm = false
                    commitMessage = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Commit") {
                    let msg = commitMessage.isEmpty ? "Update" : commitMessage
                    let escaped = msg.replacingOccurrences(of: "'", with: "'\\''")
                    ptyTap.injectCommand("git add -A && git commit -m '\(escaped)'")
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
