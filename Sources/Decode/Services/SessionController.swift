import Foundation
import Combine
import AppKit
import os

/// Orchestrates the full pipeline: PTY → Chunking → Grammar → Narration → UI.
@MainActor
final class SessionController: ObservableObject {
    @Published var narrationEntries: [NarrationEntry] = []
    @Published var sidebarItems: [SidebarItem] = []
    @Published var currentStatus: SessionStatus = .idle
    @Published var isNarrating: Bool = false
    @Published var detectedAgent: AgentType = .unknown
    @Published var gitState = GitState()

    let ptyTap = PTYTap()
    let gitMonitor = GitMonitor()

    private let chunkAssembler: ChunkAssembler
    private let grammar = ClaudeCodeGrammar()
    private let narrationContext = NarrationContext()
    private let narrationEngine = NarrationEngine()

    private let maxSidebarItems = 100

    private var cancellables = Set<AnyCancellable>()
    private var narrationTimer: Timer?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var detectionChunks: [TerminalChunk] = []
    private var isDetectionLocked = false

    init() {
        chunkAssembler = ChunkAssembler(ptyTap: ptyTap)
        narrationContext.sessionStart = Date()

        // Subscribe to assembled chunks
        chunkAssembler.chunkSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] chunk in
                self?.handleChunk(chunk)
            }
            .store(in: &cancellables)

        // Start git monitoring when shell PID becomes available
        ptyTap.$shellPid
            .compactMap { $0 }
            .first()
            .receive(on: RunLoop.main)
            .sink { [weak self] pid in
                self?.gitMonitor.start(shellPid: pid)
            }
            .store(in: &cancellables)

        // Forward git state
        gitMonitor.$gitState
            .receive(on: RunLoop.main)
            .assign(to: &$gitState)

        // Insert commit cards into the sidebar feed
        gitMonitor.$latestCommit
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] commit in
                self?.sidebarItems.append(.commit(commit))
            }
            .store(in: &cancellables)

        // Save session on app termination
        NotificationCenter.default.addObserver(forName: Notification.Name("appWillTerminate"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.autoSave()
            }
        }
    }

    func configure(apiKey: String) {
        Log.session.info("Session configured with API key")
        narrationEngine.configure(apiKey: apiKey)

        // Start the narration check timer
        resumeNarrationTimer()

        // Remove previous observers if configure() called again (e.g. user changes API key)
        if let obs = sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }
        if let obs = wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs) }

        // Pause narration timer on system sleep, resume on wake
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pauseNarrationTimer()
            }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.resumeNarrationTimer()
            }
        }
    }

    private func pauseNarrationTimer() {
        narrationTimer?.invalidate()
        narrationTimer = nil
    }

    private func resumeNarrationTimer() {
        guard narrationTimer == nil else { return }
        narrationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAndNarrate()
            }
        }
    }

    private func handleChunk(_ chunk: TerminalChunk) {
        // Agent detection (probe phase)
        if !isDetectionLocked {
            detectionChunks.append(chunk)
            let confidence = grammar.confidence(for: detectionChunks)
            if confidence >= 0.8 {
                isDetectionLocked = true
                detectedAgent = grammar.agentType
                narrationContext.agentType = grammar.agentType
                Log.session.info("Agent detected: \(String(describing: self.grammar.agentType))")
            }

            // Capture the first user command as the "original prompt"
            if narrationContext.originalPrompt.isEmpty && chunk.text.contains("claude") {
                // Try to extract the prompt from the command line
                let lines = chunk.text.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("claude") {
                        narrationContext.originalPrompt = line.trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }
        }

        // Annotate the chunk
        let labels = grammar.annotate(chunk: chunk)
        let annotated = AnnotatedChunk(chunk: chunk, labels: labels)
        narrationContext.addChunk(annotated)

        // Update status based on labels
        for label in labels {
            switch label {
            case .permissionPrompt:
                currentStatus = .waitingForInput
                narrationContext.currentStatus = .waitingForInput
            case .error:
                currentStatus = .stuck
                narrationContext.currentStatus = .stuck
            default:
                if currentStatus != .onRoute {
                    currentStatus = .onRoute
                    narrationContext.currentStatus = .onRoute
                }
            }
        }
    }

    private func checkAndNarrate() async {
        guard narrationEngine.shouldNarrate(context: narrationContext) else { return }

        isNarrating = true
        if let entry = await narrationEngine.narrate(context: narrationContext) {
            narrationEntries.append(entry)
            sidebarItems.append(.narration(entry))
            trimIfNeeded()
            autoSave()
            narrationContext.addNarration(entry)
            currentStatus = entry.status
            narrationContext.currentStatus = entry.status
        }
        isNarrating = false
    }

    private func autoSave() {
        let commits = sidebarItems.compactMap { item -> GitCommitInfo? in
            if case .commit(let c) = item { return c }
            return nil
        }
        SessionPersistence.save(
            entries: narrationEntries,
            commits: commits,
            sessionStart: narrationContext.sessionStart
        )
    }

    private func trimIfNeeded() {
        if sidebarItems.count > maxSidebarItems {
            sidebarItems.removeFirst(sidebarItems.count - maxSidebarItems)
        }
        if narrationEntries.count > maxSidebarItems {
            narrationEntries.removeFirst(narrationEntries.count - maxSidebarItems)
        }
    }

    deinit {
        narrationTimer?.invalidate()
    }
}
