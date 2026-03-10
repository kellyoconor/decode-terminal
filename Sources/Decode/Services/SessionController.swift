import Foundation
import Combine

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

    private var cancellables = Set<AnyCancellable>()
    private var narrationTimer: Timer?
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
    }

    func configure(apiKey: String) {
        narrationEngine.configure(apiKey: apiKey)

        // Start the narration check timer
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
            narrationContext.addNarration(entry)
            currentStatus = entry.status
            narrationContext.currentStatus = entry.status
        }
        isNarrating = false
    }

    deinit {
        narrationTimer?.invalidate()
    }
}
