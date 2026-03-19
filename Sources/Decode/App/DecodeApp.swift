import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: Notification.Name("appWillTerminate"), object: nil)
    }
}

@main
struct DecodeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    init() {
        // When launched from the command line, macOS treats us as a background process.
        // This makes us a proper foreground app that can receive keyboard focus.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Register bundled JetBrains Mono so it works without system install
        FontLoader.registerBundledFonts()
    }

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
            CommandMenu("Git") {
                Button("Commit...") {
                    NotificationCenter.default.post(name: .gitCommitShortcut, object: nil)
                }
                .keyboardShortcut("k")

                Button("Push") {
                    NotificationCenter.default.post(name: .gitPushShortcut, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button("Create PR") {
                    NotificationCenter.default.post(name: .gitPRShortcut, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",")
            }
        }
    }
}

extension Notification.Name {
    static let gitCommitShortcut = Notification.Name("gitCommitShortcut")
    static let gitPushShortcut = Notification.Name("gitPushShortcut")
    static let gitPRShortcut = Notification.Name("gitPRShortcut")
}
