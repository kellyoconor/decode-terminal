import Foundation
import Combine
import Darwin
import os

/// Polls git state in the terminal's working directory.
/// Detects branch, diff stats, and new commits.
/// Git commands run on a background thread to avoid blocking the UI.
@MainActor
final class GitMonitor: ObservableObject {
    @Published var gitState = GitState()
    @Published var latestCommit: GitCommitInfo?

    private var pollTimer: Timer?
    private var shellPid: pid_t?
    private var lastHeadHash: String = ""
    private var isPollInFlight = false

    func start(shellPid: pid_t) {
        self.shellPid = shellPid
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.poll()
            }
        }
        // Immediate first poll
        Task { await poll() }
    }

    deinit {
        pollTimer?.invalidate()
    }

    private func poll() async {
        guard let pid = shellPid else { return }
        guard !isPollInFlight else { return }
        isPollInFlight = true
        defer { isPollInFlight = false }

        // All git I/O happens off the main thread
        let lastHash = lastHeadHash
        let result = await Task.detached { [weak self] () -> PollResult? in
            guard let self else { return nil }
            guard let cwd = self.cwdForPid(pid), !cwd.isEmpty else { return nil }

            guard let repoRoot = self.runGit(["rev-parse", "--show-toplevel"], in: cwd) else {
                return PollResult(state: GitState(), commit: nil)
            }

            let workDir = repoRoot.trimmingCharacters(in: .whitespacesAndNewlines)

            var branch = self.runGit(["rev-parse", "--abbrev-ref", "HEAD"], in: workDir)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if branch == "HEAD" {
                let shortHash = self.runGit(["rev-parse", "--short", "HEAD"], in: workDir)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                branch = shortHash.isEmpty ? "detached" : "(\(shortHash))"
            }

            let headHash = self.runGit(["rev-parse", "--short", "HEAD"], in: workDir)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !headHash.isEmpty else {
                return PollResult(
                    state: GitState(branch: branch, headHash: "", linesAdded: 0, linesRemoved: 0, filesChanged: 0, isGitRepo: true),
                    commit: nil
                )
            }

            let diffStat = self.runGit(["diff", "--shortstat", "HEAD"], in: workDir)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let (files, added, removed) = self.parseShortStat(diffStat)

            let state = GitState(
                branch: branch,
                headHash: headHash,
                linesAdded: added,
                linesRemoved: removed,
                filesChanged: files,
                isGitRepo: true
            )

            // Detect new commit
            var commit: GitCommitInfo?
            if !lastHash.isEmpty && headHash != lastHash {
                commit = self.buildCommitInfo(in: workDir, newHash: headHash)
            }

            return PollResult(state: state, commit: commit)
        }.value

        // Publish results on main thread
        guard let result else { return }
        gitState = result.state
        lastHeadHash = result.state.headHash
        if let commit = result.commit {
            latestCommit = commit
        }
    }

    // MARK: - Background helpers (nonisolated — safe to call from any thread)

    private nonisolated func buildCommitInfo(in workDir: String, newHash: String) -> GitCommitInfo {
        let message = runGit(["log", "-1", "--format=%s"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Commit"

        let stat = runGit(["diff", "--shortstat", "HEAD~1", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? runGit(["diff", "--shortstat", "--cached", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let (files, added, removed) = parseShortStat(stat)

        return GitCommitInfo(
            hash: newHash,
            message: message,
            filesChanged: files,
            linesAdded: added,
            linesRemoved: removed,
            timestamp: Date()
        )
    }

    private nonisolated func runGit(_ args: [String], in directory: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: directory)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            Log.git.error("Git command failed: git \(args.joined(separator: " ")) — \(error.localizedDescription)")
            return nil
        }
    }

    /// Parse `git diff --shortstat` output like "3 files changed, 42 insertions(+), 8 deletions(-)"
    private nonisolated func parseShortStat(_ stat: String) -> (files: Int, added: Int, removed: Int) {
        var files = 0, added = 0, removed = 0

        if let match = stat.range(of: #"(\d+) file"#, options: .regularExpression) {
            files = Int(stat[match].components(separatedBy: " ").first ?? "") ?? 0
        }
        if let match = stat.range(of: #"(\d+) insertion"#, options: .regularExpression) {
            added = Int(stat[match].components(separatedBy: " ").first ?? "") ?? 0
        }
        if let match = stat.range(of: #"(\d+) deletion"#, options: .regularExpression) {
            removed = Int(stat[match].components(separatedBy: " ").first ?? "") ?? 0
        }

        return (files, added, removed)
    }

    /// Resolve the current working directory for a process via macOS proc_pidinfo.
    private nonisolated func cwdForPid(_ pid: pid_t) -> String? {
        let size = MemoryLayout<proc_vnodepathinfo>.size
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<proc_vnodepathinfo>.alignment)
        defer { buffer.deallocate() }

        let ret = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, buffer, Int32(size))
        guard ret == size else { return nil }

        let info = buffer.load(as: proc_vnodepathinfo.self)
        return withUnsafePointer(to: info.pvi_cdir.vip_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { cstr in
                String(cString: cstr)
            }
        }
    }
}

/// Result of a background git poll.
private struct PollResult {
    let state: GitState
    let commit: GitCommitInfo?
}
