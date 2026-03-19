import XCTest
@testable import Decode

final class ModelTests: XCTestCase {

    // MARK: - SessionStatus

    func testSessionStatusRawValues() {
        XCTAssertEqual(SessionStatus.thinking.rawValue, "thinking")
        XCTAssertEqual(SessionStatus.exploring.rawValue, "exploring")
        XCTAssertEqual(SessionStatus.blocked.rawValue, "blocked")
        XCTAssertEqual(SessionStatus.waitingForInput.rawValue, "waiting_for_input")
        XCTAssertEqual(SessionStatus.idle.rawValue, "idle")
    }

    func testSessionStatusDisplayLabels() {
        XCTAssertEqual(SessionStatus.thinking.displayLabel, "Thinking")
        XCTAssertEqual(SessionStatus.exploring.displayLabel, "Exploring")
        XCTAssertEqual(SessionStatus.blocked.displayLabel, "Blocked")
        XCTAssertEqual(SessionStatus.waitingForInput.displayLabel, "Waiting")
        XCTAssertEqual(SessionStatus.idle.displayLabel, "Idle")
    }

    func testSessionStatusCodableRoundTrip() throws {
        for status in [SessionStatus.thinking, .exploring, .blocked, .waitingForInput, .idle] {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(SessionStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testSessionStatusInitFromRawValue() {
        XCTAssertEqual(SessionStatus(rawValue: "thinking"), .thinking)
        XCTAssertEqual(SessionStatus(rawValue: "waiting_for_input"), .waitingForInput)
        XCTAssertNil(SessionStatus(rawValue: "nonexistent"))
    }

    // MARK: - SidebarItem

    func testSidebarItemNarrationCase() {
        let entry = NarrationEntry(timestamp: Date(), text: "Testing", status: .thinking)
        let item = SidebarItem.narration(entry)
        XCTAssertEqual(item.id, entry.id)
        XCTAssertEqual(item.timestamp, entry.timestamp)
    }

    func testSidebarItemCommitCase() {
        let commit = GitCommitInfo(
            hash: "abc123",
            message: "Fix bug",
            filesChanged: 2,
            linesAdded: 10,
            linesRemoved: 5,
            timestamp: Date()
        )
        let item = SidebarItem.commit(commit)
        XCTAssertEqual(item.id, commit.id)
        XCTAssertEqual(item.timestamp, commit.timestamp)
    }

    // MARK: - TerminalChunk

    func testTerminalChunkInit() {
        let now = Date()
        let chunk = TerminalChunk(text: "hello world", timestamp: now, byteCount: 11)
        XCTAssertEqual(chunk.text, "hello world")
        XCTAssertEqual(chunk.timestamp, now)
        XCTAssertEqual(chunk.byteCount, 11)
        // id should be unique
        let chunk2 = TerminalChunk(text: "hello world", timestamp: now, byteCount: 11)
        XCTAssertNotEqual(chunk.id, chunk2.id)
    }

    // MARK: - AnnotatedChunk

    func testAnnotatedChunkInit() {
        let chunk = TerminalChunk(text: "test", timestamp: Date(), byteCount: 4)
        let labels: [ChunkLabel] = [.thinking, .agentOutput(text: "test")]
        let annotated = AnnotatedChunk(chunk: chunk, labels: labels)
        XCTAssertEqual(annotated.chunk.text, "test")
        XCTAssertEqual(annotated.labels.count, 2)
    }

    // MARK: - ChunkLabel

    func testChunkLabelCases() {
        // Verify each case can be constructed
        let toolCall = ChunkLabel.toolCall(name: "Read", summary: "file.swift")
        let fileEdit = ChunkLabel.fileEdit(path: "/tmp/file.swift", operation: .edit)
        let thinking = ChunkLabel.thinking
        let permission = ChunkLabel.permissionPrompt(action: "create file")
        let testRun = ChunkLabel.testRun(command: "npm test")
        let testResult = ChunkLabel.testResult(passed: 5, failed: 1)
        let agentOutput = ChunkLabel.agentOutput(text: "output")
        let userInput = ChunkLabel.userInput(text: "yes")
        let cmd = ChunkLabel.commandExecution(command: "ls")
        let error = ChunkLabel.error(message: "oops")
        let start = ChunkLabel.sessionStart
        let end = ChunkLabel.sessionEnd
        let unknown = ChunkLabel.unknown(text: "???")

        // Basic pattern matching check
        if case .toolCall(let name, let summary) = toolCall {
            XCTAssertEqual(name, "Read")
            XCTAssertEqual(summary, "file.swift")
        } else {
            XCTFail("Expected .toolCall")
        }

        if case .fileEdit(let path, let op) = fileEdit {
            XCTAssertEqual(path, "/tmp/file.swift")
            XCTAssertEqual(op, .edit)
        } else {
            XCTFail("Expected .fileEdit")
        }

        if case .testResult(let p, let f) = testResult {
            XCTAssertEqual(p, 5)
            XCTAssertEqual(f, 1)
        } else {
            XCTFail("Expected .testResult")
        }

        // Suppress unused warnings
        _ = (thinking, permission, testRun, agentOutput, userInput, cmd, error, start, end, unknown)
    }

    // MARK: - FileOp

    func testFileOpRawValues() {
        XCTAssertEqual(FileOp.read.rawValue, "read")
        XCTAssertEqual(FileOp.write.rawValue, "write")
        XCTAssertEqual(FileOp.create.rawValue, "create")
        XCTAssertEqual(FileOp.delete.rawValue, "delete")
        XCTAssertEqual(FileOp.edit.rawValue, "edit")
    }

    // MARK: - GitState

    func testGitStateDefaults() {
        let state = GitState()
        XCTAssertEqual(state.branch, "")
        XCTAssertEqual(state.headHash, "")
        XCTAssertEqual(state.linesAdded, 0)
        XCTAssertEqual(state.linesRemoved, 0)
        XCTAssertEqual(state.filesChanged, 0)
        XCTAssertFalse(state.isGitRepo)
    }

    func testGitStateCustomInit() {
        let state = GitState(branch: "main", headHash: "abc123", linesAdded: 10, linesRemoved: 3, filesChanged: 2, isGitRepo: true)
        XCTAssertEqual(state.branch, "main")
        XCTAssertEqual(state.headHash, "abc123")
        XCTAssertEqual(state.linesAdded, 10)
        XCTAssertEqual(state.linesRemoved, 3)
        XCTAssertEqual(state.filesChanged, 2)
        XCTAssertTrue(state.isGitRepo)
    }

    // MARK: - GitCommitInfo

    func testGitCommitInfoInit() {
        let now = Date()
        let commit = GitCommitInfo(
            hash: "abc1234",
            message: "Initial commit",
            filesChanged: 1,
            linesAdded: 100,
            linesRemoved: 0,
            timestamp: now
        )
        XCTAssertEqual(commit.hash, "abc1234")
        XCTAssertEqual(commit.message, "Initial commit")
        XCTAssertEqual(commit.filesChanged, 1)
        XCTAssertEqual(commit.linesAdded, 100)
        XCTAssertEqual(commit.linesRemoved, 0)
        XCTAssertEqual(commit.timestamp, now)
    }

    // MARK: - NarrationEntry

    func testNarrationEntryInit() {
        let now = Date()
        let entry = NarrationEntry(timestamp: now, text: "Agent is reading files", status: .thinking)
        XCTAssertEqual(entry.text, "Agent is reading files")
        XCTAssertEqual(entry.status, .thinking)
        XCTAssertEqual(entry.timestamp, now)
    }

    func testNarrationEntryTimeLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let now = Date()
        let entry = NarrationEntry(timestamp: now, text: "Test", status: .idle)
        XCTAssertEqual(entry.timeLabel, formatter.string(from: now))
    }

    // MARK: - AgentType

    func testAgentTypeRawValues() {
        XCTAssertEqual(AgentType.claudeCode.rawValue, "claude_code")
        XCTAssertEqual(AgentType.codex.rawValue, "codex")
        XCTAssertEqual(AgentType.aider.rawValue, "aider")
        XCTAssertEqual(AgentType.unknown.rawValue, "unknown")
    }
}
