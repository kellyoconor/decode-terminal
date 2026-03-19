import os

enum Log {
    static let general = Logger(subsystem: "dev.decode.app", category: "general")
    static let api = Logger(subsystem: "dev.decode.app", category: "api")
    static let keychain = Logger(subsystem: "dev.decode.app", category: "keychain")
    static let session = Logger(subsystem: "dev.decode.app", category: "session")
    static let git = Logger(subsystem: "dev.decode.app", category: "git")
    static let narration = Logger(subsystem: "dev.decode.app", category: "narration")
}
