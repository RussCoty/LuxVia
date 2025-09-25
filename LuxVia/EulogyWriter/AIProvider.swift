// ==============================
// File: LuxVia/EulogyWriter/AIProvider.swift
// Purpose: Minimal chat plumbing + OpenAI provider + secrets helper
// iOS 16+, Swift 5.9
// ==============================

import Foundation

// MARK: - Minimal chat model
struct ChatMessage: Identifiable, Equatable {
    enum Role: String { case system, user, assistant }
    let id: UUID = UUID()
    let role: Role
    let content: String
}

// MARK: - Provider protocol
protocol ChatProvider {
    /// Returns assistant reply text for the given conversation.
    func complete(messages: [ChatMessage], cancelToken: CancellationToken) async throws -> String
}

// MARK: - Cancellation
final class CancellationToken {
    private var isCancelled = false
    func cancel() { isCancelled = true }
    func check() throws { if isCancelled { throw CancellationError() } }
}
struct CancellationError: Error {}

// MARK: - OpenAI provider (non-streaming)
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

        // Wire format expected by OpenAI
        let payloadMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let body: [String: Any] = [
            "model": model,
            "messages": payloadMessages,
            "temperature": temperature
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, resp) = try await session.data(for: req)
        try cancelToken.check()

        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Prefer model-supplied error for clarity
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = dict["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw NSError(domain: "OpenAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.init(rawValue: http.statusCode))
        }

        // Minimal extraction of first choice content
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = (choices?.first?["message"] as? [String: Any])?["content"] as? String

        guard let text = content, !text.isEmpty else {
            throw NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response."])
        }
        return text
    }
}

// MARK: - Secrets (dev only)
enum Secrets {
    /// Reads from UserDefaults first (OPENAI_API_KEY), then environment.
    static func openAIAPIKey() -> String? {
        if let key = UserDefaults.standard.string(forKey: "OPENAI_API_KEY"), !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}

