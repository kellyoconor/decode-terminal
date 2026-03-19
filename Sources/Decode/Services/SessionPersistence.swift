import Foundation
import os

/// Saves and loads narration session history to disk.
enum SessionPersistence {
    private static let sessionsDir: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Decode", isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            Log.session.error("Failed to create sessions directory: \(error.localizedDescription)")
        }
        return dir
    }()

    struct SavedSession: Codable {
        let id: String
        let startTime: Date
        let entries: [SavedEntry]
        let commits: [SavedCommit]
    }

    struct SavedEntry: Codable {
        let timestamp: Date
        let text: String
        let status: String
    }

    struct SavedCommit: Codable {
        let hash: String
        let message: String
        let filesChanged: Int
        let linesAdded: Int
        let linesRemoved: Int
        let timestamp: Date
    }

    static func save(entries: [NarrationEntry], commits: [GitCommitInfo], sessionStart: Date) {
        let sessionId = ISO8601DateFormatter().string(from: sessionStart)
            .replacingOccurrences(of: ":", with: "-")

        let saved = SavedSession(
            id: sessionId,
            startTime: sessionStart,
            entries: entries.map { SavedEntry(timestamp: $0.timestamp, text: $0.text, status: $0.status.rawValue) },
            commits: commits.map { SavedCommit(hash: $0.hash, message: $0.message, filesChanged: $0.filesChanged, linesAdded: $0.linesAdded, linesRemoved: $0.linesRemoved, timestamp: $0.timestamp) }
        )

        let file = sessionsDir.appendingPathComponent("\(sessionId).json")
        do {
            let data = try JSONEncoder().encode(saved)
            try data.write(to: file, options: .atomic)
        } catch {
            Log.session.error("Failed to save session to \(file.path): \(error.localizedDescription)")
        }
    }

    static func listSessions() -> [SavedSession] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .prefix(50)
            .compactMap { file in
                guard let data = try? Data(contentsOf: file) else { return nil }
                return try? JSONDecoder().decode(SavedSession.self, from: data)
            }
    }
}
