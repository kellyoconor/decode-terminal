import Foundation
import Combine
import Darwin

/// Polls git state in the terminal's working directory.
/// Detects branch, diff stats, and new commits.
@MainActor
final class GitMonitor: ObservableObject {
    @Published var gitState = GitState()
    @Published var latestCommit: GitCommitInfo?

    private var pollTimer: Timer?
    private var shellPid: pid_t?
    private var lastHeadHash: String = ""
    private var lastCwd: String = ""

    func start(shellPid: pid_t) {
        self.shellPid = shellPid
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        // Immediate first poll
        poll()
    }

    deinit {
        pollTimer?.invalidate()
    }

    private func poll() {
        guard let pid = shellPid else { return }
        guard let cwd = cwdForPid(pid), !cwd.isEmpty else { return }
        lastCwd = cwd

        // Check if this is a git repo (re-checks every poll, so git init mid-session works)
        guard let repoRoot = runGit(["rev-parse", "--show-toplevel"], in: cwd) else {
            if gitState.isGitRepo {
                gitState = GitState() // Left the repo
            }
            return
        }

        let workDir = repoRoot.trimmingCharacters(in: .whitespacesAndNewlines)

        // Branch name (returns "HEAD" when detached)
        var branch = runGit(["rev-parse", "--abbrev-ref", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Handle detached HEAD — show short hash instead
        if branch == "HEAD" {
            let shortHash = runGit(["rev-parse", "--short", "HEAD"], in: workDir)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            branch = shortHash.isEmpty ? "detached" : "(\(shortHash))"
        }

        // HEAD hash — may not exist in empty repos
        let headHash = runGit(["rev-parse", "--short", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // No commits yet — show repo as detected but with no stats
        guard !headHash.isEmpty else {
            gitState = GitState(branch: branch, headHash: "", linesAdded: 0, linesRemoved: 0, filesChanged: 0, isGitRepo: true)
            return
        }

        // Diff stats (unstaged + staged vs HEAD)
        let diffStat = runGit(["diff", "--shortstat", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let (files, added, removed) = parseShortStat(diffStat)

        gitState = GitState(
            branch: branch,
            headHash: headHash,
            linesAdded: added,
            linesRemoved: removed,
            filesChanged: files,
            isGitRepo: true
        )

        // Detect new commits
        if !lastHeadHash.isEmpty && headHash != lastHeadHash {
            detectNewCommit(in: workDir, newHash: headHash)
        }
        lastHeadHash = headHash
    }

    private func detectNewCommit(in workDir: String, newHash: String) {
        let message = runGit(["log", "-1", "--format=%s"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Commit"

        // Get diff stats — HEAD~1 may not exist for first commit
        let stat = runGit(["diff", "--shortstat", "HEAD~1", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? runGit(["diff", "--shortstat", "--cached", "HEAD"], in: workDir)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let (files, added, removed) = parseShortStat(stat)

        let commit = GitCommitInfo(
            hash: newHash,
            message: message,
            filesChanged: files,
            linesAdded: added,
            linesRemoved: removed,
            timestamp: Date()
        )
        latestCommit = commit
    }

    // MARK: - Helpers

    private func runGit(_ args: [String], in directory: String) -> String? {
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
            return nil
        }
    }

    /// Parse `git diff --shortstat` output like "3 files changed, 42 insertions(+), 8 deletions(-)"
    private func parseShortStat(_ stat: String) -> (files: Int, added: Int, removed: Int) {
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
