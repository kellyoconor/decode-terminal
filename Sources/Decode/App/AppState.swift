import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String = ""
    @Published var showSettings: Bool = false

    init() {
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
}
