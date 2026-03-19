import Foundation
import os

/// Minimal streaming client for the Claude Messages API.
final class ClaudeAPIClient {
    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(apiKey: String, model: String = "claude-haiku-4-5-20251001") {
        self.apiKey = apiKey
        self.model = model
        self.session = URLSession(configuration: .default)
    }

    /// Stream a narration request and return tokens as they arrive.
    func stream(systemPrompt: String, userMessage: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "content-type")
                    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                    let body: [String: Any] = [
                        "model": model,
                        "max_tokens": 256,
                        "stream": true,
                        "system": [
                            [
                                "type": "text",
                                "text": systemPrompt,
                                "cache_control": ["type": "ephemeral"]
                            ]
                        ],
                        "messages": [
                            ["role": "user", "content": userMessage]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        Log.api.error("API request failed with status \(statusCode)")
                        continuation.finish(throwing: APIError.httpError(statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" { break }

                            guard let data = jsonString.data(using: .utf8),
                                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                  let type = event["type"] as? String else {
                                continue
                            }

                            if type == "content_block_delta",
                               let delta = event["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                continuation.yield(text)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    Log.api.error("Streaming error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Validate an API key by making a minimal request.
    static func validateKey(_ key: String) async -> Result<Void, APIError> {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.httpError(-1))
            }
            if httpResponse.statusCode == 200 {
                return .success(())
            } else {
                return .failure(.httpError(httpResponse.statusCode))
            }
        } catch {
            return .failure(.httpError(-1))
        }
    }

    enum APIError: Error, LocalizedError {
        case httpError(Int)
        case invalidKey
        case networkError

        var errorDescription: String? {
            switch self {
            case .httpError(let code):
                switch code {
                case 401: return "Invalid API key"
                case 429: return "Rate limited — try again in a moment"
                case -1: return "Network error — check your connection"
                default: return "API returned status \(code)"
                }
            case .invalidKey: return "Invalid API key"
            case .networkError: return "Network error — check your connection"
            }
        }
    }
}
