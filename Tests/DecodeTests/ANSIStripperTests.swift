import XCTest
@testable import Decode

final class ANSIStripperTests: XCTestCase {

    // MARK: - strip()

    func testStripCSISequences() {
        let input = "\u{1B}[32mhello\u{1B}[0m"
        XCTAssertEqual(ANSIStripper.strip(input), "hello")
    }

    func testStripMultipleCSISequences() {
        let input = "\u{1B}[1;31mERROR:\u{1B}[0m \u{1B}[33mwarning\u{1B}[0m"
        XCTAssertEqual(ANSIStripper.strip(input), "ERROR: warning")
    }

    func testStripOSCSequences() {
        // OSC terminated by BEL
        let input = "\u{1B}]0;Terminal Title\u{07}hello"
        XCTAssertEqual(ANSIStripper.strip(input), "hello")
    }

    func testStripOSCSequencesWithST() {
        // OSC terminated by ST (ESC \)
        let input = "\u{1B}]0;Title\u{1B}\\hello"
        XCTAssertEqual(ANSIStripper.strip(input), "hello")
    }

    func testStripSimpleEscapeSequences() {
        // ESC + single char (e.g., ESC M for reverse index)
        let input = "\u{1B}Mhello"
        XCTAssertEqual(ANSIStripper.strip(input), "hello")
    }

    func testHandlesEmptyString() {
        XCTAssertEqual(ANSIStripper.strip(""), "")
    }

    func testPassthroughPlainText() {
        let input = "hello world, no escapes here!"
        XCTAssertEqual(ANSIStripper.strip(input), input)
    }

    func testStripsCarriageReturnButNotCRLF() {
        // Standalone \r should be stripped (progress bar rewrite)
        let input = "progress\roverwrite"
        XCTAssertEqual(ANSIStripper.strip(input), "progressoverwrite")

        // \r\n: the \r is preserved (negative lookahead keeps it when followed by \n)
        let inputCRLF = "line1\r\nline2"
        let result = ANSIStripper.strip(inputCRLF)
        XCTAssertTrue(result.contains("line1"), "Should preserve text before CRLF")
        XCTAssertTrue(result.contains("line2"), "Should preserve text after CRLF")
    }

    // MARK: - isSpinnerNoise()

    func testBrailleSpinnerCharsAreNoise() {
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("⠋⠙⠹"))
    }

    func testThinkingWordsAreNoise() {
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("Twisting…"))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("Embellishing… (36s)"))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("Thinking…"))
    }

    func testStartupNoiseDetected() {
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("Press Esc to interrupt"))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("Tip: use shift+tab for something"))
    }

    func testMeaningfulOutputNotNoise() {
        XCTAssertFalse(ANSIStripper.isSpinnerNoise("Reading package.json to check dependencies"))
    }

    func testVeryShortStringsAreNoise() {
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("ab"))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise(""))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("hi"))
    }

    func testNormalTerminalOutputNotNoise() {
        XCTAssertFalse(ANSIStripper.isSpinnerNoise("Successfully compiled 42 files in 3.2s"))
        XCTAssertFalse(ANSIStripper.isSpinnerNoise("npm install completed with 0 vulnerabilities"))
    }

    func testSinglePromptCharsAreNoise() {
        XCTAssertTrue(ANSIStripper.isSpinnerNoise("?"))
        XCTAssertTrue(ANSIStripper.isSpinnerNoise(">"))
    }
}
