import Foundation
import Combine
import SwiftTerm

/// Captures raw bytes from the terminal's PTY output stream without
/// modifying or delaying delivery to the terminal emulator.
/// Also provides command injection into the terminal.
final class PTYTap: ObservableObject {
    /// Raw data chunks as they arrive from the PTY
    let dataSubject = PassthroughSubject<Data, Never>()

    /// Total bytes captured this session
    @Published private(set) var totalBytes: Int = 0

    /// Shell process PID, set after terminal starts. Used for cwd discovery.
    @Published var shellPid: pid_t?

    /// Weak reference to the terminal view for command injection.
    weak var terminalView: LocalProcessTerminalView?

    func receive(slice: ArraySlice<UInt8>) {
        let data = Data(slice)
        totalBytes += data.count
        dataSubject.send(data)
    }

    /// Inject a command into the terminal as if the user typed it.
    func injectCommand(_ command: String) {
        guard let process = terminalView?.process else { return }
        let bytes = Array((command + "\n").utf8)
        process.send(data: bytes[bytes.startIndex..<bytes.endIndex])
    }
}
