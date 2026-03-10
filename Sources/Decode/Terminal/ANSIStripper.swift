import Foundation

/// Strips ANSI escape sequences and spinner artifacts from terminal output,
/// producing clean text for the narration engine.
enum ANSIStripper {
    // CSI sequences: ESC [ ... final_byte
    private static let csiPattern = "\u{1B}\\[[0-9;?]*[A-Za-z]"
    // OSC sequences: ESC ] ... BEL or ESC ] ... ST
    private static let oscPattern = "\u{1B}\\].*?(?:\u{07}|\u{1B}\\\\)"
    // Simple two-byte escape sequences: ESC + single char
    private static let simpleEscPattern = "\u{1B}[^\\[\\]]"
    // Carriage return (used for line rewrites/progress bars)
    private static let crPattern = "\\r(?!\\n)"
    // Spinner/loading characters (braille dots, box-drawing spinners, etc.)
    private static let spinnerPattern = "[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⣾⣽⣻⢿⡿⣟⣯⣷◐◓◑◒◴◷◶◵⠁⠂⠄⡀⢀⠠⠐⠈|/\\-\\\\](?=[|/\\-\\\\⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏])"

    private static let combinedPattern = [csiPattern, oscPattern, simpleEscPattern, crPattern].joined(separator: "|")
    private static let regex = try! NSRegularExpression(pattern: combinedPattern, options: [])

    /// Strip all ANSI escape sequences from the input string.
    static func strip(_ input: String) -> String {
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
    }

    /// Claude Code thinking animation words — these are normal processing, not stuck.
    private static let thinkingWords: Set<String> = [
        "twisting", "embellishing", "harmonizing", "composing", "weaving",
        "crafting", "shaping", "forming", "thinking", "reasoning",
        "analyzing", "processing", "considering", "evaluating", "planning",
        "preparing", "assembling", "building", "generating", "structuring",
    ]

    /// Returns true if the chunk is mostly spinner/loading animation noise.
    static func isSpinnerNoise(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Very short chunks that are just spinner frames
        if trimmed.count < 5 { return true }

        // Claude Code thinking animations: "Twisting…", "Embellishing… (36s · ↑ 37 tokens)"
        let firstWord = trimmed.components(separatedBy: .whitespaces).first?
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased() ?? ""
        if thinkingWords.contains(firstWord) { return true }

        // Mostly braille/spinner unicode characters
        let spinnerChars = CharacterSet(charactersIn: "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⣾⣽⣻⢿⡿⣟⣯⣷◐◓◑◒◴◷◶◵⠁⠂⠄⡀⢀⠠⠐⠈")
        let stripped = trimmed.unicodeScalars.filter { !spinnerChars.contains($0) && !CharacterSet.whitespacesAndNewlines.contains($0) }
        if stripped.count == 0 { return true }
        // If more than half the content is spinner chars, it's noise
        let ratio = Double(stripped.count) / Double(trimmed.unicodeScalars.count)
        return ratio < 0.3
    }
}
