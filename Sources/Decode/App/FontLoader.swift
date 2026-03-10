import AppKit
import CoreText

/// Registers bundled JetBrains Mono fonts so they're available even if not installed system-wide.
enum FontLoader {
    static func registerBundledFonts() {
        let fontNames = [
            "JetBrainsMono-Regular",
            "JetBrainsMono-Medium",
            "JetBrainsMono-Bold"
        ]

        for name in fontNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
