import SwiftUI
import SwiftTerm

/// Wraps SwiftTerm's LocalProcessTerminalView in a SwiftUI NSViewRepresentable.
/// Subclasses to tap into dataReceived for narration without disrupting terminal rendering.
struct TerminalContainerView: NSViewRepresentable {
    let ptyTap: PTYTap

    func makeNSView(context: Context) -> TappedTerminalView {
        let terminalView = TappedTerminalView(frame: .zero)
        terminalView.ptyTap = ptyTap

        // Terminal appearance — dark, matching the left pane design
        terminalView.nativeForegroundColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        terminalView.nativeBackgroundColor = NSColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1) // #0C0C0C

        // Use a nice monospace font
        terminalView.font = NSFont(name: "JetBrains Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Start the shell process
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        terminalView.startProcess(
            executable: shell,
            args: [shell, "--login"],
            environment: nil,
            execName: nil
        )

        return terminalView
    }

    func updateNSView(_ nsView: TappedTerminalView, context: Context) {
        // No dynamic updates needed
    }
}

/// Subclass of LocalProcessTerminalView that taps into the data stream.
class TappedTerminalView: LocalProcessTerminalView {
    var ptyTap: PTYTap?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        // Tap the bytes for narration pipeline — non-blocking copy
        ptyTap?.receive(slice: slice)

        // Let SwiftTerm process normally
        super.dataReceived(slice: slice)
    }
}
