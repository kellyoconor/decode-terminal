import SwiftUI

struct Theme {
    let colorScheme: ColorScheme

    // MARK: - Spacing scale (4px base)

    static let spaceXS: CGFloat = 4
    static let spaceSM: CGFloat = 6
    static let spaceMD: CGFloat = 8
    static let spaceLG: CGFloat = 12
    static let spaceXL: CGFloat = 16
    static let spaceXXL: CGFloat = 24
    static let spaceSection: CGFloat = 32

    // MARK: - Type scale

    static let fontCaption2: CGFloat = 9
    static let fontCaption: CGFloat = 10
    static let fontFootnote: CGFloat = 11
    static let fontSubhead: CGFloat = 12
    static let fontBody: CGFloat = 13
    static let fontCallout: CGFloat = 14
    static let fontTitle3: CGFloat = 16
    static let fontTitle2: CGFloat = 18
    static let fontTitle1: CGFloat = 24
    static let fontLargeTitle: CGFloat = 32

    // MARK: - Border radius scale

    static let radiusSM: CGFloat = 3      // shortcut badges
    static let radiusMD: CGFloat = 6      // buttons
    static let radiusLG: CGFloat = 8      // cards

    // MARK: - Card & surface tokens

    static let cardPadding: CGFloat = 14
    static let borderWidth: CGFloat = 1

    // MARK: - Opacity scale

    static let opacityCardTint: Double = 0.06
    static let opacityPillBg: Double = 0.1
    static let opacityCardStroke: Double = 0.2

    // MARK: - Line spacing

    static let lineSpaceBody: CGFloat = 4
    static let lineSpaceCompact: CGFloat = 2

    // MARK: - Icon sizes

    static let iconEmptyState: CGFloat = 28
    static let indicatorDot: CGFloat = 6

    // MARK: - Sidebar backgrounds

    var sidebarBg: Color {
        colorScheme == .dark
            ? Color(red: 0.118, green: 0.118, blue: 0.118)
            : Color(red: 0.980, green: 0.980, blue: 0.969)
    }
    var cardBg: Color {
        colorScheme == .dark
            ? Color(red: 0.161, green: 0.161, blue: 0.161)
            : Color(red: 0.941, green: 0.941, blue: 0.922)
    }
    var borderColor: Color {
        colorScheme == .dark
            ? Color(red: 0.220, green: 0.220, blue: 0.220)
            : Color(red: 0.910, green: 0.910, blue: 0.890)
    }

    // MARK: - Text colors

    var primaryText: Color {
        colorScheme == .dark
            ? Color(red: 0.900, green: 0.900, blue: 0.890)
            : Color(red: 0.102, green: 0.102, blue: 0.102)
    }
    var mutedText: Color {
        colorScheme == .dark
            ? Color(red: 0.600, green: 0.600, blue: 0.580)
            : Color(red: 0.549, green: 0.549, blue: 0.522)
    }
    var subtleText: Color {
        colorScheme == .dark
            ? Color(red: 0.500, green: 0.500, blue: 0.480)
            : Color(red: 0.639, green: 0.639, blue: 0.612)
    }

    // MARK: - Action button colors

    var buttonBg: Color {
        colorScheme == .dark
            ? Color(red: 0.200, green: 0.200, blue: 0.200)
            : Color.white
    }
    var actionColor: Color {
        colorScheme == .dark
            ? Color(red: 0.900, green: 0.900, blue: 0.890)
            : Color(red: 0.102, green: 0.102, blue: 0.102)
    }
    var shortcutBg: Color {
        colorScheme == .dark
            ? Color(red: 0.250, green: 0.250, blue: 0.250)
            : Color(red: 0.941, green: 0.941, blue: 0.922)
    }
    var shortcutColor: Color {
        colorScheme == .dark
            ? Color(red: 0.550, green: 0.550, blue: 0.530)
            : Color(red: 0.749, green: 0.749, blue: 0.729)
    }

    // MARK: - Status colors (desaturated ~12% in dark mode)

    var activeColor: Color {
        colorScheme == .dark
            ? Color(red: 0.120, green: 0.580, blue: 0.290)
            : Color(red: 0.086, green: 0.639, blue: 0.290)
    }
    var exploringAmber: Color {
        colorScheme == .dark
            ? Color(red: 0.880, green: 0.590, blue: 0.100)
            : Color(red: 0.961, green: 0.620, blue: 0.043)
    }
    var blockedRed: Color {
        colorScheme == .dark
            ? Color(red: 0.850, green: 0.300, blue: 0.300)
            : Color(red: 0.937, green: 0.267, blue: 0.267)
    }
    var waitingBlue: Color {
        colorScheme == .dark
            ? Color(red: 0.270, green: 0.490, blue: 0.880)
            : Color(red: 0.231, green: 0.510, blue: 0.965)
    }
    var idleGray: Color {
        colorScheme == .dark
            ? Color(red: 0.500, green: 0.500, blue: 0.480)
            : Color(red: 0.549, green: 0.549, blue: 0.522)
    }

    // MARK: - Diff & git colors (desaturated in dark mode)

    var addedGreen: Color {
        colorScheme == .dark
            ? Color(red: 0.230, green: 0.660, blue: 0.370)
            : Color(red: 0.204, green: 0.718, blue: 0.357)
    }
    var removedRed: Color {
        colorScheme == .dark
            ? Color(red: 0.830, green: 0.360, blue: 0.360)
            : Color(red: 0.910, green: 0.329, blue: 0.329)
    }
    var commitColor: Color {
        colorScheme == .dark
            ? Color(red: 0.860, green: 0.500, blue: 0.160)
            : Color(red: 0.933, green: 0.510, blue: 0.118)
    }
    var watchingGreen: Color {
        colorScheme == .dark
            ? Color(red: 0.230, green: 0.760, blue: 0.560)
            : Color(red: 0.204, green: 0.827, blue: 0.600)
    }

    // MARK: - Utility colors (desaturated in dark mode)

    var errorRed: Color {
        colorScheme == .dark
            ? Color(red: 0.780, green: 0.280, blue: 0.260)
            : Color(red: 0.850, green: 0.250, blue: 0.235)
    }
    var linkBlue: Color {
        colorScheme == .dark
            ? Color(red: 0.270, green: 0.490, blue: 0.880)
            : Color(red: 0.231, green: 0.510, blue: 0.965)
    }
}
