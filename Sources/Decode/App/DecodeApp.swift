import SwiftUI

@main
struct DecodeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    // TODO: multi-session support
                }
                .keyboardShortcut("n")
            }
        }
    }
}
