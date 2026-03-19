import Foundation

/// Pattern matcher for Claude Code terminal output.
/// Recognizes tool calls, file operations, permission prompts, test runs, and errors.
struct ClaudeCodeGrammar: AgentGrammarProtocol {
    let agentType: AgentType = .claudeCode

    // MARK: - Detection patterns

    /// Claude Code signature markers in early output
    private static let startupPatterns: [NSRegularExpression] = {
        let patterns: [(String, String, [NSRegularExpression.Options])] = [
            ("startupPattern[0]", "(?i)claude\\s*(code)?", []),
            ("startupPattern[1]", "[╭╮╰╯┌┐└┘]", []),
            ("startupPattern[2]", "(?i)anthropic", []),
        ]
        return patterns.map { name, pattern, options in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: options.reduce(0) { $0 | $1.rawValue })) else {
                fatalError("ClaudeCodeGrammar: invalid \(name) regex — this is a programming error")
            }
            return regex
        }
    }()

    // MARK: - Annotation patterns

    /// Tool call headers: Read, Write, Edit, Bash, Search, Grep, Glob, etc.
    private static let toolCallPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "^\\s*(?:>\\s*)?(Read|Write|Edit|Bash|Search|Grep|Glob|TodoRead|TodoWrite|WebFetch|WebSearch|Agent)\\s*[:(]",
            options: [.anchorsMatchLines]
        ) else {
            fatalError("ClaudeCodeGrammar: invalid toolCallPattern regex — this is a programming error")
        }
        return regex
    }()

    /// File paths in output
    private static let filePathPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "(?:^|\\s)(/[a-zA-Z0-9_\\-/.]+\\.[a-zA-Z0-9]+)",
            options: [.anchorsMatchLines]
        ) else {
            fatalError("ClaudeCodeGrammar: invalid filePathPattern regex — this is a programming error")
        }
        return regex
    }()

    /// Permission prompts — only match explicit permission UI, not generic text
    private static let permissionPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)(Do you want to (?:create|edit|delete|write|run|execute|overwrite)|allow.*edits.*this session|Esc to cancel)",
            options: []
        ) else {
            fatalError("ClaudeCodeGrammar: invalid permissionPattern regex — this is a programming error")
        }
        return regex
    }()

    /// Test execution
    private static let testRunPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)(npm\\s+test|pytest|cargo\\s+test|go\\s+test|jest|vitest|mocha)",
            options: []
        ) else {
            fatalError("ClaudeCodeGrammar: invalid testRunPattern regex — this is a programming error")
        }
        return regex
    }()

    /// Test results
    private static let testResultPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)(PASS|FAIL|passed|failed|Tests?:?\\s*\\d+)",
            options: []
        ) else {
            fatalError("ClaudeCodeGrammar: invalid testResultPattern regex — this is a programming error")
        }
        return regex
    }()

    /// Error patterns
    private static let errorPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)(^error|\\berror:|\\bError\\b|FAIL\\b|failed|panic|exception|traceback)",
            options: [.anchorsMatchLines]
        ) else {
            fatalError("ClaudeCodeGrammar: invalid errorPattern regex — this is a programming error")
        }
        return regex
    }()

    /// User input prompt (Claude Code waiting for input)
    /// NOTE: Do NOT match `^\s*>\s*$` — that's the normal Claude Code prompt, not a request for input.
    private static let userInputPattern: NSRegularExpression = {
        guard let regex = try? NSRegularExpression(
            pattern: "Interrupted|What should Claude do|Do you want to (?:create|edit|delete|write|run|execute|overwrite)|(?:Yes|No)\\s*/\\s*(?:Yes|No)|allow.*edits.*this session",
            options: [.anchorsMatchLines, .caseInsensitive]
        ) else {
            fatalError("ClaudeCodeGrammar: invalid userInputPattern regex — this is a programming error")
        }
        return regex
    }()

    // MARK: - AgentGrammarProtocol

    func confidence(for chunks: [TerminalChunk]) -> Double {
        let combinedText = chunks.prefix(20).map(\.text).joined(separator: "\n")
        let range = NSRange(combinedText.startIndex..., in: combinedText)

        var hits = 0
        for pattern in Self.startupPatterns {
            if pattern.firstMatch(in: combinedText, options: [], range: range) != nil {
                hits += 1
            }
        }

        // Strong signal: 2+ markers = very likely Claude Code
        if hits >= 2 { return 0.95 }
        if hits == 1 { return 0.6 }
        return 0.0
    }

    func annotate(chunk: TerminalChunk) -> [ChunkLabel] {
        let text = chunk.text
        let range = NSRange(text.startIndex..., in: text)
        var labels: [ChunkLabel] = []

        // Check for tool calls
        if let match = Self.toolCallPattern.firstMatch(in: text, options: [], range: range),
           let toolRange = Range(match.range(at: 1), in: text) {
            let toolName = String(text[toolRange])
            labels.append(.toolCall(name: toolName, summary: extractToolSummary(text: text, tool: toolName)))
        }

        // Check for file paths (attach file operations)
        let fileMatches = Self.filePathPattern.matches(in: text, options: [], range: range)
        for match in fileMatches {
            if let pathRange = Range(match.range(at: 1), in: text) {
                let path = String(text[pathRange])
                let op = inferFileOp(text: text)
                labels.append(.fileEdit(path: path, operation: op))
            }
        }

        // Check for permission prompts
        if Self.permissionPattern.firstMatch(in: text, options: [], range: range) != nil {
            let action = text.trimmingCharacters(in: .whitespacesAndNewlines)
            labels.append(.permissionPrompt(action: String(action.prefix(100))))
        }

        // Check for test runs
        if let match = Self.testRunPattern.firstMatch(in: text, options: [], range: range),
           let cmdRange = Range(match.range(at: 1), in: text) {
            labels.append(.testRun(command: String(text[cmdRange])))
        }

        // Check for test results
        if Self.testResultPattern.firstMatch(in: text, options: [], range: range) != nil {
            let (passed, failed) = parseTestCounts(text: text)
            labels.append(.testResult(passed: passed, failed: failed))
        }

        // Check for errors
        if Self.errorPattern.firstMatch(in: text, options: [], range: range) != nil {
            labels.append(.error(message: String(text.prefix(200))))
        }

        // Check for user input prompts
        if Self.userInputPattern.firstMatch(in: text, options: [], range: range) != nil {
            labels.append(.userInput(text: text))
        }

        // Fallback
        if labels.isEmpty {
            labels.append(.agentOutput(text: String(text.prefix(200))))
        }

        return labels
    }

    // MARK: - Helpers

    private func extractToolSummary(text: String, tool: String) -> String {
        // Try to grab the first meaningful line after the tool name
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix(tool) {
                return String(trimmed.prefix(120))
            }
        }
        return tool
    }

    private func inferFileOp(text: String) -> FileOp {
        let lower = text.lowercased()
        if lower.contains("read") || lower.contains("reading") { return .read }
        if lower.contains("creat") || lower.contains("new file") { return .create }
        if lower.contains("edit") || lower.contains("editing") { return .edit }
        if lower.contains("delet") || lower.contains("remov") { return .delete }
        if lower.contains("writ") { return .write }
        return .read
    }

    private func parseTestCounts(text: String) -> (passed: Int, failed: Int) {
        guard let passedRegex = try? NSRegularExpression(pattern: "(\\d+)\\s*passed", options: [.caseInsensitive]) else {
            fatalError("ClaudeCodeGrammar: invalid passedRegex regex — this is a programming error")
        }
        guard let failedRegex = try? NSRegularExpression(pattern: "(\\d+)\\s*failed", options: [.caseInsensitive]) else {
            fatalError("ClaudeCodeGrammar: invalid failedRegex regex — this is a programming error")
        }
        let range = NSRange(text.startIndex..., in: text)

        var passed = 0
        var failed = 0
        if let match = passedRegex.firstMatch(in: text, options: [], range: range),
           let numRange = Range(match.range(at: 1), in: text) {
            passed = Int(text[numRange]) ?? 0
        }
        if let match = failedRegex.firstMatch(in: text, options: [], range: range),
           let numRange = Range(match.range(at: 1), in: text) {
            failed = Int(text[numRange]) ?? 0
        }
        return (passed, failed)
    }
}
