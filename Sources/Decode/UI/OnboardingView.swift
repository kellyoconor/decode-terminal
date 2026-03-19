import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var apiKeyInput = ""
    @State private var currentStep = 0
    @State private var isValidating = false
    @State private var validationError: String? = nil

    private var stepTransition: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.25)
    }

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
            HStack(spacing: Theme.spaceMD) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i == currentStep ? theme.primaryText : theme.borderColor)
                        .frame(width: Theme.spaceSM, height: Theme.spaceSM)
                }
            }
            .padding(.bottom, Theme.spaceSection)
        }
        .frame(width: 480, height: 420)
        .background(theme.sidebarBg)
    }

    private var welcomeStep: some View {
        VStack(spacing: Theme.spaceXXL) {
            Text("decode")
                .font(.system(size: Theme.fontLargeTitle, weight: .bold, design: .monospaced))

            VStack(spacing: Theme.spaceLG) {
                Text("Google Maps for your terminal.")
                    .font(.system(size: Theme.fontTitle3, weight: .medium))
                    .foregroundColor(theme.primaryText)

                Text("A native macOS terminal with an AI sidebar that narrates what your coding agent is doing — in plain language, in real time.")
                    .font(.system(size: Theme.fontBody))
                    .foregroundColor(theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Theme.lineSpaceBody)
                    .frame(maxWidth: 360)
            }

            Button("Get started") {
                withAnimation(stepTransition) { currentStep = 1 }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
        }
    }

    private var howItWorksStep: some View {
        VStack(spacing: Theme.spaceXXL) {
            VStack(alignment: .leading, spacing: Theme.spaceXL) {
                featureRow(icon: "terminal", title: "Run your agent", desc: "Launch Claude Code, Codex, or any agent inside Decode.")
                featureRow(icon: "eye", title: "Sidebar narrates", desc: "The navigator translates terminal output into short, calm updates.")
                featureRow(icon: "arrow.triangle.branch", title: "Git awareness", desc: "Live branch, diff stats, commit cards, and quick actions.")
            }
            .frame(maxWidth: 340)

            Button("Next") {
                withAnimation(stepTransition) { currentStep = 2 }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spaceLG) {
            Image(systemName: icon)
                .font(.system(size: Theme.fontCallout))
                .foregroundColor(theme.onRouteColor)
                .frame(width: Theme.spaceXXL)

            VStack(alignment: .leading, spacing: Theme.spaceXS) {
                Text(title)
                    .font(.system(size: Theme.fontBody, weight: .semibold))
                Text(desc)
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.mutedText)
                    .lineSpacing(Theme.lineSpaceCompact)
            }
        }
    }

    private var apiKeyStep: some View {
        VStack(spacing: Theme.spaceXXL) {
            VStack(spacing: Theme.spaceMD) {
                Text("Connect to Claude")
                    .font(.system(size: Theme.fontTitle2, weight: .semibold))
                Text("Decode uses Claude Haiku to narrate your sessions.\nYour key is stored in macOS Keychain.")
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Theme.lineSpaceCompact)
            }

            VStack(alignment: .leading, spacing: Theme.spaceMD) {
                Text("Anthropic API Key")
                    .font(.system(size: Theme.fontSubhead, weight: .medium))
                    .foregroundColor(theme.mutedText)
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Theme.fontBody, design: .monospaced))
                    .frame(maxWidth: 320)
                Link("Get an API key at console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.system(size: Theme.fontFootnote))
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
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.errorRed)
            }
        }
    }
}
