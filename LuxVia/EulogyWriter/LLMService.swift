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
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func chat(messages: [LLMMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
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
    func chat(messages: [LLMMessage]) async throws -> String {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let lastUserMessage = messages.last(where: { $0.role == "user" })?.content ?? ""
        
        // Simple conversational responses based on context
        if messages.count <= 2 {
            return "Thank you for sharing that. I'd love to learn more about them. What stands out to you most about their character or personality?"
        } else if lastUserMessage.lowercased().contains("name") || messages.count == 3 {
            return "That's a beautiful name. To help me craft something truly personal, could you tell me about your relationship with them and what made it special?"
        } else if lastUserMessage.lowercased().contains("mother") || lastUserMessage.lowercased().contains("father") || 
                  lastUserMessage.lowercased().contains("friend") || lastUserMessage.lowercased().contains("relationship") {
            return "I can sense how meaningful this relationship was. What were some of their most defining qualities or characteristics that people who knew them would recognize immediately?"
        } else if lastUserMessage.split(separator: ",").count > 1 || lastUserMessage.lowercased().contains("kind") ||
                  lastUserMessage.lowercased().contains("generous") || lastUserMessage.lowercased().contains("funny") {
            return "Those are wonderful qualities. What were some of the things they loved to do? Their hobbies, passions, or the activities that truly lit them up?"
        } else if lastUserMessage.lowercased().contains("hobby") || lastUserMessage.lowercased().contains("love") ||
                  lastUserMessage.lowercased().contains("enjoy") {
            return "That paints such a vivid picture of who they were. Is there a particular story or moment that really captures their essence - something friends and family might smile remembering?"
        } else if lastUserMessage.count > 100 || lastUserMessage.lowercased().contains("story") ||
                  lastUserMessage.lowercased().contains("remember") || lastUserMessage.lowercased().contains("time") {
            return "What a touching memory. Before I help craft the eulogy, would you like to include any spiritual, religious, or humanist elements that would honor their beliefs?"
        } else {
            return "Thank you for sharing that with me. Is there anything else you'd like me to know that would help capture who they truly were?"
        }
    }
}

enum LLMError: Error {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
}
