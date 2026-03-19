import XCTest
@testable import Decode

final class SessionPersistenceTests: XCTestCase {

    func testSavedSessionCodableRoundTrip() throws {
        let now = Date()

        let entries = [
            SessionPersistence.SavedEntry(timestamp: now, text: "Reading files", status: "on_route"),
            SessionPersistence.SavedEntry(timestamp: now.addingTimeInterval(10), text: "Running tests", status: "on_route"),
        ]

        let commits = [
            SessionPersistence.SavedCommit(
                hash: "abc1234",
                message: "Fix login bug",
                filesChanged: 3,
                linesAdded: 42,
                linesRemoved: 8,
                timestamp: now.addingTimeInterval(30)
            ),
        ]

        let session = SessionPersistence.SavedSession(
            id: "test-session",
            startTime: now,
            entries: entries,
            commits: commits
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SessionPersistence.SavedSession.self, from: data)

        XCTAssertEqual(decoded.id, "test-session")
        XCTAssertEqual(decoded.entries.count, 2)
        XCTAssertEqual(decoded.entries[0].text, "Reading files")
        XCTAssertEqual(decoded.entries[0].status, "on_route")
        XCTAssertEqual(decoded.entries[1].text, "Running tests")
        XCTAssertEqual(decoded.commits.count, 1)
        XCTAssertEqual(decoded.commits[0].hash, "abc1234")
        XCTAssertEqual(decoded.commits[0].message, "Fix login bug")
        XCTAssertEqual(decoded.commits[0].filesChanged, 3)
        XCTAssertEqual(decoded.commits[0].linesAdded, 42)
        XCTAssertEqual(decoded.commits[0].linesRemoved, 8)
        // Dates lose sub-second precision in JSON, compare to 1 second tolerance
        XCTAssertEqual(decoded.startTime.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
    }

    func testSavedEntryRoundTrip() throws {
        let entry = SessionPersistence.SavedEntry(
            timestamp: Date(),
            text: "Some narration text",
            status: "idle"
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SessionPersistence.SavedEntry.self, from: data)
        XCTAssertEqual(decoded.text, entry.text)
        XCTAssertEqual(decoded.status, entry.status)
    }

    func testSavedCommitRoundTrip() throws {
        let commit = SessionPersistence.SavedCommit(
            hash: "def5678",
            message: "Add feature",
            filesChanged: 5,
            linesAdded: 100,
            linesRemoved: 20,
            timestamp: Date()
        )
        let data = try JSONEncoder().encode(commit)
        let decoded = try JSONDecoder().decode(SessionPersistence.SavedCommit.self, from: data)
        XCTAssertEqual(decoded.hash, commit.hash)
        XCTAssertEqual(decoded.message, commit.message)
        XCTAssertEqual(decoded.filesChanged, commit.filesChanged)
        XCTAssertEqual(decoded.linesAdded, commit.linesAdded)
        XCTAssertEqual(decoded.linesRemoved, commit.linesRemoved)
    }
}
