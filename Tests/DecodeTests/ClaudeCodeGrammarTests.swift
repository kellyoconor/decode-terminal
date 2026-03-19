import XCTest
@testable import Decode

final class ClaudeCodeGrammarTests: XCTestCase {
    let grammar = ClaudeCodeGrammar()

    // MARK: - Helpers

    private func makeChunk(_ text: String) -> TerminalChunk {
        TerminalChunk(text: text, timestamp: Date(), byteCount: text.utf8.count)
    }

    // MARK: - confidence()

    func testHighConfidenceWithClaudeAndBoxDrawing() {
        let chunks = [
            makeChunk("claude code v1.2.3"),
            makeChunk("╭─────────────────╮"),
            makeChunk("│ Welcome         │"),
        ]
        let score = grammar.confidence(for: chunks)
        XCTAssertGreaterThanOrEqual(score, 0.8)
    }

    func testZeroConfidenceForEmptyChunks() {
        let score = grammar.confidence(for: [])
        XCTAssertEqual(score, 0.0)
    }

    func testLowConfidenceForUnrelatedOutput() {
        let chunks = [
            makeChunk("npm install"),
            makeChunk("added 432 packages"),
            makeChunk("found 0 vulnerabilities"),
        ]
        let score = grammar.confidence(for: chunks)
        XCTAssertLessThan(score, 0.5)
    }

    func testMediumConfidenceWithSingleMarker() {
        let chunks = [
            makeChunk("claude is running"),
        ]
        let score = grammar.confidence(for: chunks)
        XCTAssertEqual(score, 0.6)
    }

    // MARK: - annotate()

    func testRecognizesToolCalls() {
        let chunk = makeChunk("Read: /path/to/file.swift")
        let labels = grammar.annotate(chunk: chunk)
        let hasToolCall = labels.contains { label in
            if case .toolCall(let name, _) = label { return name == "Read" }
            return false
        }
        XCTAssertTrue(hasToolCall, "Should recognize 'Read:' as a tool call")
    }

    func testRecognizesBashToolCall() {
        let chunk = makeChunk("Bash: npm test")
        let labels = grammar.annotate(chunk: chunk)
        let hasToolCall = labels.contains { label in
            if case .toolCall(let name, _) = label { return name == "Bash" }
            return false
        }
        XCTAssertTrue(hasToolCall, "Should recognize 'Bash:' as a tool call")
    }

    func testRecognizesPermissionPrompts() {
        let chunk = makeChunk("Do you want to create file.txt?")
        let labels = grammar.annotate(chunk: chunk)
        let hasPermission = labels.contains { label in
            if case .permissionPrompt = label { return true }
            return false
        }
        XCTAssertTrue(hasPermission, "Should recognize permission prompt")
    }

    func testRecognizesErrors() {
        let chunk = makeChunk("Error: something failed")
        let labels = grammar.annotate(chunk: chunk)
        let hasError = labels.contains { label in
            if case .error = label { return true }
            return false
        }
        XCTAssertTrue(hasError, "Should recognize error pattern")
    }

    func testRecognizesTestRuns() {
        let chunk = makeChunk("npm test")
        let labels = grammar.annotate(chunk: chunk)
        let hasTestRun = labels.contains { label in
            if case .testRun(let cmd) = label { return cmd == "npm test" }
            return false
        }
        XCTAssertTrue(hasTestRun, "Should recognize test run command")
    }

    func testRecognizesPytestRun() {
        let chunk = makeChunk("pytest -v tests/")
        let labels = grammar.annotate(chunk: chunk)
        let hasTestRun = labels.contains { label in
            if case .testRun = label { return true }
            return false
        }
        XCTAssertTrue(hasTestRun, "Should recognize pytest as a test run")
    }

    func testFallsBackToAgentOutput() {
        let chunk = makeChunk("Just some normal output from the terminal")
        let labels = grammar.annotate(chunk: chunk)
        let hasAgentOutput = labels.contains { label in
            if case .agentOutput = label { return true }
            return false
        }
        XCTAssertTrue(hasAgentOutput, "Unrecognized text should fall back to .agentOutput")
    }

    func testRecognizesTestResults() {
        let chunk = makeChunk("Tests: 10 passed, 2 failed")
        let labels = grammar.annotate(chunk: chunk)
        let hasTestResult = labels.contains { label in
            if case .testResult = label { return true }
            return false
        }
        XCTAssertTrue(hasTestResult, "Should recognize test result pattern")
    }
}
