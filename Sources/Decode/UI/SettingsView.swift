import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKeyInput: String = ""
    @State private var isSaving = false

    private let sidebarBg = Color(red: 0.980, green: 0.980, blue: 0.969)
    private let cardBg = Color(red: 0.941, green: 0.941, blue: 0.922)
    private let borderColor = Color(red: 0.910, green: 0.910, blue: 0.890)

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("~ decode")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("Enter your Anthropic API key to enable narration.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                SecureField("sk-ant-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
            }

            Button(action: save) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Save & Start")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.102, green: 0.102, blue: 0.102))
            .disabled(apiKeyInput.isEmpty || isSaving)

            Text("Your key is stored in macOS Keychain.")
                .font(.system(size: 11))
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(40)
        .frame(width: 400)
        .background(sidebarBg)
        .onAppear {
            apiKeyInput = appState.apiKey
        }
    }

    private func save() {
        isSaving = true
        appState.saveAPIKey(apiKeyInput)
        isSaving = false
    }
}
