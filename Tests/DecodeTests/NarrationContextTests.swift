import XCTest
@testable import Decode

final class NarrationContextTests: XCTestCase {

    private func makeAnnotatedChunk(_ text: String) -> AnnotatedChunk {
        let chunk = TerminalChunk(text: text, timestamp: Date(), byteCount: text.utf8.count)
        return AnnotatedChunk(chunk: chunk, labels: [.agentOutput(text: text)])
    }

    private func makeNarrationEntry(_ text: String, status: SessionStatus = .thinking) -> NarrationEntry {
        NarrationEntry(timestamp: Date(), text: text, status: status)
    }

    // MARK: - addChunk

    func testAddChunkIncreasesNewChunkCount() {
        let context = NarrationContext()
        XCTAssertEqual(context.newChunkCount, 0)

        context.addChunk(makeAnnotatedChunk("first chunk"))
        XCTAssertEqual(context.newChunkCount, 1)

        context.addChunk(makeAnnotatedChunk("second chunk"))
        XCTAssertEqual(context.newChunkCount, 2)
    }

    // MARK: - serialize()

    func testSerializeIncludesAgentTypeAndStatus() {
        let context = NarrationContext()
        context.agentType = .claudeCode
        context.currentStatus = .thinking

        context.addChunk(makeAnnotatedChunk("Reading file.swift"))

        let serialized = context.serialize()
        XCTAssertTrue(serialized.contains("AGENT: claude_code"), "Should include agent type")
        XCTAssertTrue(serialized.contains("CURRENT STATUS: on_route"), "Should include status")
        XCTAssertTrue(serialized.contains("Reading file.swift"), "Should include chunk text")
    }

    func testSerializeIncludesOriginalPrompt() {
        let context = NarrationContext()
        context.originalPrompt = "Fix the login bug"
        context.addChunk(makeAnnotatedChunk("some output"))

        let serialized = context.serialize()
        XCTAssertTrue(serialized.contains("ORIGINAL USER REQUEST: Fix the login bug"))
    }

    // MARK: - addNarration

    func testAddNarrationResetsNewChunkCount() {
        let context = NarrationContext()
        context.addChunk(makeAnnotatedChunk("chunk 1"))
        context.addChunk(makeAnnotatedChunk("chunk 2"))
        XCTAssertEqual(context.newChunkCount, 2)

        context.addNarration(makeNarrationEntry("Agent is reading files"))
        XCTAssertEqual(context.newChunkCount, 0)
    }

    func testKeepsMaxThreeRecentNarrations() {
        let context = NarrationContext()
        context.addNarration(makeNarrationEntry("First"))
        context.addNarration(makeNarrationEntry("Second"))
        context.addNarration(makeNarrationEntry("Third"))
        XCTAssertEqual(context.recentNarrations.count, 3)

        context.addNarration(makeNarrationEntry("Fourth"))
        XCTAssertEqual(context.recentNarrations.count, 3)
        XCTAssertEqual(context.recentNarrations.first?.text, "Second")
        XCTAssertEqual(context.recentNarrations.last?.text, "Fourth")
    }

    // MARK: - Pruning

    func testPrunesOldChunksWhenTokenBudgetExceeded() {
        let context = NarrationContext()
        // The serialize() method shows suffix(10) chunks, and token budget is 4000 (count/4 = 16000 chars).
        // Use very large chunks so that even 10 chunks exceed the budget.
        // Each chunk needs to be > 1600 chars so that 10 chunks serialize to > 16000 chars.
        for i in 0..<20 {
            let longText = String(repeating: "x", count: 3000) + " chunk \(i)"
            context.addChunk(makeAnnotatedChunk(longText))
        }
        // After pruning, should have fewer than 20 chunks but at least 2
        XCTAssertLessThan(context.annotatedChunks.count, 20)
        XCTAssertGreaterThanOrEqual(context.annotatedChunks.count, 2)
    }
}
