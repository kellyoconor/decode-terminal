import SwiftUI

struct Theme {
    let colorScheme: ColorScheme

    // Sidebar backgrounds
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

    // Text colors
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

    // Action button colors
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

    // Status colors (same in both modes — these are semantic)
    let onRouteColor = Color(red: 0.086, green: 0.639, blue: 0.290)
    let driftingAmber = Color(red: 0.961, green: 0.620, blue: 0.043)
    let stuckRed = Color(red: 0.937, green: 0.267, blue: 0.267)
    let waitingBlue = Color(red: 0.231, green: 0.510, blue: 0.965)
    let idleGray = Color(red: 0.549, green: 0.549, blue: 0.522)
    let addedGreen = Color(red: 0.204, green: 0.718, blue: 0.357)
    let removedRed = Color(red: 0.910, green: 0.329, blue: 0.329)
    let commitColor = Color(red: 0.933, green: 0.510, blue: 0.118)
    let watchingGreen = Color(red: 0.204, green: 0.827, blue: 0.600)
    let errorRed = Color(red: 0.850, green: 0.250, blue: 0.235)
    let linkBlue = Color(red: 0.231, green: 0.510, blue: 0.965)
}
