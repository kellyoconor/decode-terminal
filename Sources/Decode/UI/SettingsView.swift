import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { Theme(colorScheme: colorScheme) }

    @State private var apiKeyInput: String = ""
    @State private var isSaving = false
    @State private var validationError: String? = nil

    var body: some View {
        VStack(spacing: Theme.spaceXXL) {
            VStack(spacing: Theme.spaceMD) {
                Text("~ decode")
                    .font(.system(size: Theme.fontTitle1, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryText)
                Text("Enter your Anthropic API key to enable narration.")
                    .font(.system(size: Theme.fontBody))
                    .foregroundColor(theme.mutedText)
            }

            VStack(alignment: .leading, spacing: Theme.spaceMD) {
                Text("API Key")
                    .font(.system(size: Theme.fontSubhead, weight: .medium))
                    .foregroundColor(theme.mutedText)
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: Theme.fontBody, design: .monospaced))
                Link("Get an API key at console.anthropic.com", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.system(size: Theme.fontFootnote))
                    .foregroundColor(theme.linkBlue)
            }

            Button(action: save) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Save & Start")
                        .font(.system(size: Theme.fontBody, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.actionColor)
            .disabled(apiKeyInput.isEmpty || isSaving)

            if let validationError {
                Text(validationError)
                    .font(.system(size: Theme.fontSubhead))
                    .foregroundColor(theme.errorRed)
            }

            Text("Your key is stored in macOS Keychain.")
                .font(.system(size: Theme.fontFootnote))
                .foregroundColor(theme.subtleText)
        }
        .padding(40)
        .frame(width: 400)
        .background(theme.sidebarBg)
        .onAppear {
            apiKeyInput = appState.apiKey
        }
    }

    private func save() {
        Task {
            isSaving = true
            validationError = nil
            let result = await ClaudeAPIClient.validateKey(apiKeyInput)
            isSaving = false
            switch result {
            case .success:
                appState.saveAPIKey(apiKeyInput)
            case .failure(let error):
                validationError = error.localizedDescription
            }
        }
    }
}
