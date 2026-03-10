import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String = ""
    @Published var showSettings: Bool = false
    @Published var hasCompletedOnboarding: Bool = false

    @Published var sidebarWidth: CGFloat {
        didSet { UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth") }
    }

    init() {
        let saved = UserDefaults.standard.double(forKey: "sidebarWidth")
        sidebarWidth = saved > 0 ? saved : 340

        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if let key = KeychainService.shared.getAPIKey() {
            apiKey = key
        } else {
            showSettings = true
        }
    }

    func saveAPIKey(_ key: String) {
        apiKey = key
        KeychainService.shared.saveAPIKey(key)
        showSettings = false
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
