import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKeyInput = ""
    @State private var currentStep = 0

    private let warmBg = Color(red: 0.980, green: 0.980, blue: 0.969)
    private let mutedText = Color(red: 0.549, green: 0.549, blue: 0.522)
    private let accentGreen = Color(red: 0.086, green: 0.639, blue: 0.290)

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
                        .fill(i == currentStep ? Color(red: 0.102, green: 0.102, blue: 0.102) : Color(red: 0.830, green: 0.830, blue: 0.810))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 32)
        }
        .frame(width: 480, height: 420)
        .background(warmBg)
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
                    .foregroundColor(mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 360)
            }

            Button("Get started") {
                withAnimation { currentStep = 1 }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.102, green: 0.102, blue: 0.102))
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
            .tint(Color(red: 0.102, green: 0.102, blue: 0.102))
        }
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accentGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(mutedText)
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
                    .foregroundColor(mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Anthropic API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(mutedText)
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(maxWidth: 320)
            }

            Button("Start navigating") {
                appState.saveAPIKey(apiKeyInput)
                appState.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.102, green: 0.102, blue: 0.102))
            .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
