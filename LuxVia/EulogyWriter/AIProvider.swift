// =======================================================
// File: LuxVia/EulogyWriter/AIProvider.swift
// Minimal chat model + OpenAI provider + Secrets helper.
// iOS 15+ (non-streaming)
// =======================================================
import Foundation

// Chat message model
struct ChatMessage: Identifiable, Equatable {
    enum Role: String { case system, user, assistant }
    let id = UUID()
    let role: Role
    let content: String
}

// Provider protocol
protocol ChatProvider {
    func complete(messages: [ChatMessage], cancelToken: CancellationToken) async throws -> String
}

// Cancellation
final class CancellationToken {
    private var isCancelled = false
    func cancel() { isCancelled = true }
    func check() throws { if isCancelled { throw CancellationError() } }
}
struct CancellationError: Error {}

// OpenAI (chat/completions) – non-streaming
final class OpenAIChatProvider: ChatProvider {
    private let apiKey: String
    private let session: URLSession
    var model: String = "gpt-4o-mini"
    var temperature: Double = 0.6
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func complete(messages: [ChatMessage], cancelToken: CancellationToken) async throws -> String {
        try cancelToken.check()
        let payloadMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let body: [String: Any] = ["model": model, "messages": payloadMessages, "temperature": temperature]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try cancelToken.check()

        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = dict["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.init(rawValue: http.statusCode))
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = (choices?.first?["message"] as? [String: Any])?["content"] as? String
        guard let text = content, !text.isEmpty else {
            throw NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response."])
        }
        return text
    }
}

// Secrets helper
enum Secrets {
    static func openAIAPIKey() -> String? {
        if let key = UserDefaults.standard.string(forKey: "OPENAI_API_KEY"), !key.isEmpty { return key }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}
