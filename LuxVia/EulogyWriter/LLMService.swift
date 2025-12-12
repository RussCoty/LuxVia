import Foundation

protocol LLMService {
    func chat(messages: [LLMMessage]) async throws -> String
}

struct LLMMessage: Codable {
    let role: String
    let content: String
}

final class OpenAIService: LLMService {
    private let apiKey: String
    private let baseURL: URL
    private let model = "gpt-4o-mini"
    
    init(apiKey: String) {
        self.apiKey = apiKey
        // Safe URL construction with a valid constant
        self.baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    }
    
    func chat(messages: [LLMMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LLMError.apiError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return content
    }
}

final class MockLLMService: LLMService {
    private static let mockResponseDelay: UInt64 = 500_000_000 // 0.5 seconds in nanoseconds
    
    func chat(messages: [LLMMessage]) async throws -> String {
        // Simulate API delay
        try await Task.sleep(nanoseconds: Self.mockResponseDelay)
        
        let lastUserMessage = messages.last(where: { $0.role == "user" })?.content ?? ""
        
        return generateContextualResponse(for: lastUserMessage, messageCount: messages.count)
    }
    
    private func generateContextualResponse(for userMessage: String, messageCount: Int) -> String {
        let lower = userMessage.lowercased()
        
        // Early conversation - just starting
        if messageCount <= 2 {
            return "Thank you for sharing that. I'd love to learn more about them. What stands out to you most about their character or personality?"
        }
        
        // Check if user is providing name information
        if contains(lower, anyOf: ["name"]) || messageCount == 3 {
            return "That's a beautiful name. To help me craft something truly personal, could you tell me about your relationship with them and what made it special?"
        }
        
        // Check if user is sharing relationship
        if contains(lower, anyOf: ["mother", "father", "friend", "relationship"]) {
            return "I can sense how meaningful this relationship was. What were some of their most defining qualities or characteristics that people who knew them would recognize immediately?"
        }
        
        // Check if user is listing traits (multiple items separated by commas)
        if userMessage.split(separator: ",").count > 1 || contains(lower, anyOf: ["kind", "generous", "funny"]) {
            return "Those are wonderful qualities. What were some of the things they loved to do? Their hobbies, passions, or the activities that truly lit them up?"
        }
        
        // Check if user is sharing hobbies/interests
        if contains(lower, anyOf: ["hobby", "love", "enjoy"]) {
            return "That paints such a vivid picture of who they were. Is there a particular story or moment that really captures their essence - something friends and family might smile remembering?"
        }
        
        // Check if user is sharing a story
        if userMessage.count > 100 || contains(lower, anyOf: ["story", "remember", "time"]) {
            return "What a touching memory. Before I help craft the eulogy, would you like to include any spiritual, religious, or humanist elements that would honor their beliefs?"
        }
        
        // Default response
        return "Thank you for sharing that with me. Is there anything else you'd like me to know that would help capture who they truly were?"
    }
    
    private func contains(_ text: String, anyOf keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}

enum LLMError: Error {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
}
