import Foundation

/// Strips ANSI escape sequences from terminal output, producing clean text for the narration engine.
enum ANSIStripper {
    // CSI sequences: ESC [ ... final_byte
    private static let csiPattern = "\u{1B}\\[[0-9;?]*[A-Za-z]"
    // OSC sequences: ESC ] ... BEL or ESC ] ... ST
    private static let oscPattern = "\u{1B}\\].*?(?:\u{07}|\u{1B}\\\\)"
    // Simple two-byte escape sequences: ESC + single char
    private static let simpleEscPattern = "\u{1B}[^\\[\\]]"
    // Carriage return (used for line rewrites/progress bars)
    private static let crPattern = "\\r(?!\\n)"

    private static let combinedPattern = [csiPattern, oscPattern, simpleEscPattern, crPattern].joined(separator: "|")
    private static let regex = try! NSRegularExpression(pattern: combinedPattern, options: [])

    /// Strip all ANSI escape sequences from the input string.
    static func strip(_ input: String) -> String {
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
    }
}
