import Foundation
import Combine

/// Captures raw bytes from the terminal's PTY output stream without
/// modifying or delaying delivery to the terminal emulator.
/// Publishes raw data for downstream processing (ANSI stripping, chunking, narration).
final class PTYTap: ObservableObject {
    /// Raw data chunks as they arrive from the PTY
    let dataSubject = PassthroughSubject<Data, Never>()

    /// Total bytes captured this session
    @Published private(set) var totalBytes: Int = 0

    func receive(slice: ArraySlice<UInt8>) {
        let data = Data(slice)
        totalBytes += data.count
        dataSubject.send(data)
    }
}
