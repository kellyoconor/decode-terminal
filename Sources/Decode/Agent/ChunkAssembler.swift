import Foundation
import Combine

/// Assembles raw PTY bytes into clean, ANSI-stripped text chunks.
/// Uses time-based (500ms) and volume-based (2KB) flushing.
final class ChunkAssembler {
    let chunkSubject = PassthroughSubject<TerminalChunk, Never>()

    private var buffer = Data()
    private var flushTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let flushInterval: TimeInterval = 0.5
    private let maxBufferSize = 2048

    init(ptyTap: PTYTap) {
        ptyTap.dataSubject
            .sink { [weak self] data in
                self?.append(data)
            }
            .store(in: &cancellables)

        startTimer()
    }

    deinit {
        flushTimer?.invalidate()
    }

    private func append(_ data: Data) {
        buffer.append(data)

        if buffer.count >= maxBufferSize {
            flush()
        }
    }

    private func startTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    private func flush() {
        guard !buffer.isEmpty else { return }

        let raw = buffer
        buffer = Data()

        guard let text = String(data: raw, encoding: .utf8) else { return }

        let stripped = ANSIStripper.strip(text)
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !ANSIStripper.isSpinnerNoise(trimmed) else { return }

        let chunk = TerminalChunk(
            text: trimmed,
            timestamp: Date(),
            byteCount: raw.count
        )
        chunkSubject.send(chunk)
    }
}
