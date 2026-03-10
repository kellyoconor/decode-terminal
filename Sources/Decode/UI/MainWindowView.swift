import SwiftUI

/// Main window: terminal on the left (dark), narration sidebar on the right (warm/light).
/// The visual contrast between the two panes IS the product story.
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var session = SessionController()

    var body: some View {
        HSplitView {
            // Left: Terminal (the firehose)
            TerminalContainerView(ptyTap: session.ptyTap)
                .frame(minWidth: 500)

            // Right: Narration sidebar (the navigator)
            NarrationSidebarView(session: session)
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 400)
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
        }
        .onAppear {
            if !appState.apiKey.isEmpty {
                session.configure(apiKey: appState.apiKey)
            }
        }
        .onChange(of: appState.apiKey) { _, newKey in
            if !newKey.isEmpty {
                session.configure(apiKey: newKey)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.showSettings = true }) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}
