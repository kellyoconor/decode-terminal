import XCTest
@testable import Decode

final class NarrationEngineTests: XCTestCase {

    private func makeAnnotatedChunk(_ text: String, labels: [ChunkLabel] = []) -> AnnotatedChunk {
        let chunk = TerminalChunk(text: text, timestamp: Date(), byteCount: text.utf8.count)
        let actualLabels = labels.isEmpty ? [ChunkLabel.agentOutput(text: text)] : labels
        return AnnotatedChunk(chunk: chunk, labels: actualLabels)
    }

    // MARK: - shouldNarrate()

    @MainActor
    func testShouldNarrateReturnsFalseWithNoNewChunks() {
        let engine = NarrationEngine()
        let context = NarrationContext()
        // No chunks added, newChunkCount is 0
        XCTAssertFalse(engine.shouldNarrate(context: context))
    }

    @MainActor
    func testShouldNarrateRequiresBothChunksAndInterval() {
        // This test verifies the combined requirement: both newChunkCount > 0
        // AND minimum interval passed. Since we can't easily manipulate
        // lastNarrationTime without calling narrate (which makes network calls),
        // we verify the newChunkCount == 0 guard works even when interval is satisfied.
        let engine = NarrationEngine()
        let context = NarrationContext()

        // No chunks, interval is satisfied (lastNarrationTime is .distantPast)
        XCTAssertFalse(engine.shouldNarrate(context: context), "Should return false when no new chunks even if interval passed")

        // Add one chunk - with .distantPast as lastNarrationTime, interval is satisfied
        // but only 1 chunk (below threshold of 5), so it should still pass
        // because timeSinceLast >= 15.0 is true
        context.addChunk(makeAnnotatedChunk("single chunk"))
        XCTAssertTrue(engine.shouldNarrate(context: context), "Should return true: 1 chunk + interval > 15s from distantPast")
    }

    @MainActor
    func testShouldNarrateReturnsTrueWithEnoughChunks() {
        let engine = NarrationEngine()
        let context = NarrationContext()

        // Add 5+ chunks (chunkThreshold)
        for i in 0..<6 {
            context.addChunk(makeAnnotatedChunk("chunk \(i)"))
        }

        // lastNarrationTime is .distantPast, so interval check passes
        XCTAssertTrue(engine.shouldNarrate(context: context))
    }

    @MainActor
    func testShouldNarrateReturnsTrueOnUrgentLabels() {
        let engine = NarrationEngine()
        let context = NarrationContext()

        // Add a single chunk with a permission prompt label
        context.addChunk(makeAnnotatedChunk(
            "Do you want to create file.txt?",
            labels: [.permissionPrompt(action: "create file.txt")]
        ))

        // Even with just 1 chunk, urgent label should trigger
        XCTAssertTrue(engine.shouldNarrate(context: context))
    }

    @MainActor
    func testShouldNarrateReturnsTrueOnErrorLabel() {
        let engine = NarrationEngine()
        let context = NarrationContext()

        context.addChunk(makeAnnotatedChunk(
            "Error: compilation failed",
            labels: [.error(message: "compilation failed")]
        ))

        XCTAssertTrue(engine.shouldNarrate(context: context))
    }

    @MainActor
    func testShouldNarrateReturnsTrueOnTestResultLabel() {
        let engine = NarrationEngine()
        let context = NarrationContext()

        context.addChunk(makeAnnotatedChunk(
            "5 passed, 1 failed",
            labels: [.testResult(passed: 5, failed: 1)]
        ))

        XCTAssertTrue(engine.shouldNarrate(context: context))
    }
}
