import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    @State private var apiKeyInput = ""
    @State private var currentStep = 0
    @State private var isValidating = false
    @State private var validationError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if currentStep == 0 {
                welcomeStep
            } else if currentStep == 1 {
                howItWorksStep
            } else {
                apiKeyStep
            }

            Spacer()

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i == currentStep ? theme.primaryText : theme.borderColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 32)
        }
        .frame(width: 480, height: 420)
        .background(theme.sidebarBg)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Text("decode")
                .font(.system(size: 32, weight: .bold, design: .monospaced))

            VStack(spacing: 12) {
                Text("Google Maps for your terminal.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text("A native macOS terminal with an AI sidebar that narrates what your coding agent is doing — in plain language, in real time.")
                    .font(.system(size: 13))
                    .foregroundColor(theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 360)
            }

            Button("Get started") {
                withAnimation { currentStep = 1 }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
        }
    }

    private var howItWorksStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "terminal", title: "Run your agent", desc: "Launch Claude Code, Codex, or any agent inside Decode.")
                featureRow(icon: "eye", title: "Sidebar narrates", desc: "The navigator translates terminal output into short, calm updates.")
                featureRow(icon: "arrow.triangle.branch", title: "Git awareness", desc: "Live branch, diff stats, commit cards, and quick actions.")
            }
            .frame(maxWidth: 340)

            Button("Next") {
                withAnimation { currentStep = 2 }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.onRouteColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(theme.mutedText)
                    .lineSpacing(2)
            }
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Connect to Claude")
                    .font(.system(size: 18, weight: .semibold))
                Text("Decode uses Claude Haiku to narrate your sessions.\nYour key is stored in macOS Keychain.")
                    .font(.system(size: 12))
                    .foregroundColor(theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Anthropic API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.mutedText)
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(maxWidth: 320)
                Link("Get an API key at console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.system(size: 11))
                    .foregroundColor(theme.linkBlue)
            }

            Button("Start navigating") {
                Task {
                    isValidating = true
                    validationError = nil
                    let result = await ClaudeAPIClient.validateKey(apiKeyInput)
                    isValidating = false
                    switch result {
                    case .success:
                        appState.saveAPIKey(apiKeyInput)
                        appState.completeOnboarding()
                    case .failure(let error):
                        validationError = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
            .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)

            if isValidating {
                ProgressView()
                    .controlSize(.small)
            }

            if let validationError {
                Text(validationError)
                    .font(.system(size: 12))
                    .foregroundColor(theme.errorRed)
            }
        }
    }
}
