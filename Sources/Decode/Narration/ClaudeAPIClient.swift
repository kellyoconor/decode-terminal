import Foundation

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
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    enum APIError: Error, LocalizedError {
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .httpError(let code): return "API returned status \(code)"
            }
        }
    }
}
