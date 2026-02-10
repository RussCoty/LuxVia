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
        
        // Extract system prompt to understand context
        let systemPrompt = messages.first(where: { $0.role == "system" })?.content ?? ""
        let lastUserMessage = messages.last(where: { $0.role == "user" })?.content ?? ""
        
        return generateContextualResponse(
            for: lastUserMessage,
            systemContext: systemPrompt,
            messageCount: messages.count
        )
    }
    
    private func generateContextualResponse(
        for userMessage: String,
        systemContext: String,
        messageCount: Int
    ) -> String {
        let lower = userMessage.lowercased()
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Detect common greetings and handle them gracefully
        let greetings = ["hi", "hello", "hey", "greetings", "good morning", "good afternoon", 
                        "good evening", "thanks", "thank you"]
        if greetings.contains(trimmed.lowercased()) {
            return "Hello. I'm here to help you create a meaningful eulogy for your loved one. When you're ready, please share their name or tell me about them in your own words."
        }
        
        // Parse what information we already have from the system context
        let hasName = systemContext.contains("Name:")
        let hasRelationship = systemContext.contains("Relationship:")
        let hasTraits = systemContext.contains("Traits:")
        let hasHobbies = systemContext.contains("Hobbies:")
        let hasStories = systemContext.contains("Stories shared:")
        let hasBeliefs = systemContext.contains("Beliefs/Rituals:")
        
        // Extract what we still need from the system context
        let stillNeed = extractStillNeeded(from: systemContext)
        
        // Early conversation - just starting
        if messageCount <= 2 {
            return "Thank you for sharing that. I'd love to learn more about them. What stands out to you most about their character or personality?"
        }
        
        // Use context-aware responses based on what's already collected
        
        // If we just got a name, acknowledge it and move on
        if !hasName && (contains(lower, anyOf: ["name"]) || containsCapitalizedWords(userMessage)) {
            return "That's a beautiful name. To help me craft something truly personal, could you tell me about your relationship with them and what made it special?"
        }
        
        // If we have name but need relationship
        if hasName && !hasRelationship {
            if contains(lower, anyOf: ["mother", "father", "friend", "relationship", "grandmother", "grandfather", "partner", "spouse", "wife", "husband", "mom", "dad", "grandma", "grandpa", "aunt", "uncle", "cousin", "sister", "brother"]) {
                return "I can sense how meaningful this relationship was. What were some of their most defining qualities or characteristics that people who knew them would recognize immediately?"
            }
            return "Thank you for sharing. Could you tell me about your relationship with them? For example, were they your mother, father, friend, or another loved one?"
        }
        
        // If we have name and relationship but need traits
        if hasName && hasRelationship && !hasTraits {
            if userMessage.split(separator: ",").count > 1 || contains(lower, anyOf: ["kind", "generous", "funny", "patient", "wise", "caring", "loving", "strong"]) {
                if !hasHobbies {
                    return "Those are wonderful qualities. What were some of the things they loved to do? Their hobbies, passions, or the activities that truly lit them up?"
                } else if !hasStories {
                    return "Those are wonderful qualities. Is there a particular story or moment that really captures their essence - something friends and family might smile remembering?"
                } else {
                    return "Those are beautiful qualities that paint such a vivid picture. Is there anything else you'd like to add about their beliefs or values?"
                }
            }
            return "That's helpful. What were some of their most defining qualities? For example, were they patient, generous, funny, or something else that made them special?"
        }
        
        // If we have basics but need hobbies
        if hasName && hasRelationship && hasTraits && !hasHobbies {
            if contains(lower, anyOf: ["hobby", "love", "enjoy", "passion", "liked", "activity", "garden", "read", "cook"]) {
                if !hasStories {
                    return "That paints such a vivid picture of who they were. Is there a particular story or moment that really captures their essence - something friends and family might smile remembering?"
                } else {
                    return "That's wonderful. Would you like to include any spiritual, religious, or humanist elements that would honor their beliefs?"
                }
            }
            return "I'm getting a good sense of who they were. What did they love to do? Any hobbies, passions, or activities that brought them joy?"
        }
        
        // If we need stories
        if hasName && hasRelationship && (hasTraits || hasHobbies) && !hasStories {
            if userMessage.count > 50 || contains(lower, anyOf: ["story", "remember", "time", "once", "always"]) {
                if !hasBeliefs {
                    return "What a touching memory. Before I help craft the eulogy, would you like to include any spiritual, religious, or humanist elements that would honor their beliefs?"
                } else {
                    return "What a beautiful memory to share. Thank you for trusting me with these details. I have enough to create a meaningful draft now."
                }
            }
            return "Could you share a story or memory that captures who they were? It could be something small but meaningful that shows their character."
        }
        
        // If we have most information but need beliefs
        if hasName && hasRelationship && hasTraits && hasStories && !hasBeliefs {
            if contains(lower, anyOf: ["catholic", "christian", "jewish", "muslim", "buddhist", "hindu", "spiritual", "atheist", "humanist", "faith", "belief", "church", "temple", "no", "none"]) {
                return "Thank you for sharing that. I believe I have enough information now to create a meaningful draft. Let me put that together for you."
            }
            return "Would you like to include any spiritual, religious, or humanist elements in the eulogy? Or if they didn't have specific beliefs, that's perfectly fine too."
        }
        
        // If we have comprehensive information
        if hasName && hasRelationship && hasTraits && (hasHobbies || hasStories) {
            return "Thank you for sharing all of this with me. I have a wonderful sense of who they were. Is there anything else you'd like me to know before I create the draft?"
        }
        
        // Intelligent default that uses "still need" information
        if !stillNeed.isEmpty {
            let nextNeeded = stillNeed.first ?? "more details"
            return "Thank you for that. To make this truly personal, could you tell me about their \(nextNeeded)?"
        }
        
        // Final fallback
        return "Thank you for sharing that with me. Is there anything else you'd like me to know that would help capture who they truly were?"
    }
    
    private func extractStillNeeded(from systemContext: String) -> [String] {
        // Extract the "Still need:" section from system prompt
        guard let stillNeedRange = systemContext.range(of: "Still need: ") else {
            return []
        }
        let afterStillNeed = String(systemContext[stillNeedRange.upperBound...])
        let firstLine = afterStillNeed.components(separatedBy: "\n").first ?? ""
        
        if firstLine.contains("nothing critical") {
            return []
        }
        
        return firstLine.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private func contains(_ text: String, anyOf keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
    
    private func containsCapitalizedWords(_ text: String) -> Bool {
        // Check if text contains capitalized words (likely a name)
        let pattern = #"\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)*\b"#
        return (try? NSRegularExpression(pattern: pattern).firstMatch(in: text, range: NSRange(text.startIndex..., in: text))) != nil
    }
}

enum LLMError: Error {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
}
