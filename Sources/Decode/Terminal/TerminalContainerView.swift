import SwiftUI
import SwiftTerm

/// Wraps SwiftTerm's LocalProcessTerminalView in a SwiftUI NSViewRepresentable.
/// Uses a hosting NSView to ensure keyboard focus is properly forwarded to the terminal.
struct TerminalContainerView: NSViewRepresentable {
    let ptyTap: PTYTap

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        // Create a container that holds the terminal view
        let container = TerminalHostView()
        let terminalView = TappedTerminalView(frame: .zero)
        terminalView.ptyTap = ptyTap
        context.coordinator.terminalView = terminalView

        // Terminal appearance — dark, matching the left pane design
        terminalView.nativeForegroundColor = NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        terminalView.nativeBackgroundColor = NSColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1)

        // Use a nice monospace font
        terminalView.font = NSFont(name: "JetBrains Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Add terminal view as subview filling the container
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(terminalView)
        NSLayoutConstraint.activate([
            terminalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            terminalView.topAnchor.constraint(equalTo: container.topAnchor),
            terminalView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.terminalView = terminalView

        // Start the shell process
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        terminalView.startProcess(
            executable: shell,
            args: ["--login"],
            environment: nil,
            execName: nil,
            currentDirectory: home
        )

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class Coordinator {
        var terminalView: TappedTerminalView?
    }
}

/// A container NSView that forwards first responder to the terminal.
class TerminalHostView: NSView {
    var terminalView: TappedTerminalView?

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        if let tv = terminalView {
            return window?.makeFirstResponder(tv) ?? false
        }
        return super.becomeFirstResponder()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Auto-focus the terminal when we enter a window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if let tv = self?.terminalView {
                self?.window?.makeFirstResponder(tv)
            }
        }
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

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }
}
