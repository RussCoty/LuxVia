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
        
        // Check if we're ready for draft (most important check first!)
        let isReadyForDraft = systemContext.contains("⚠️ DRAFT READY:")
        
        // Parse what information we already have from the system context
        let hasName = systemContext.contains("Name:") && !systemContext.contains("Still need: name")
        let hasRelationship = systemContext.contains("Relationship:") && !systemContext.contains("Still need: relationship")
        let hasPronouns = extractPronouns(from: systemContext)
        let hasTraits = systemContext.contains("Traits:") && !systemContext.contains("Still need: personality traits")
        let hasHobbies = systemContext.contains("Hobbies:") && !systemContext.contains("Still need: hobbies")
        let hasStories = systemContext.contains("Stories shared:") && !systemContext.contains("Still need: at least one story")
        let hasBeliefs = systemContext.contains("Beliefs/Rituals:")
        
        // Extract actual values for context-aware responses
        let name = extractName(from: systemContext)
        let relationship = extractRelationship(from: systemContext)
        
        // Extract what we still need from the system context
        let stillNeed = extractStillNeeded(from: systemContext)
        
        // IF READY FOR DRAFT - prioritize moving toward draft creation
        if isReadyForDraft {
            // Check if user is saying "no" or "nothing else" or similar
            // Use word boundaries to avoid false matches
            let donePatterns = [
                "\\bno\\b", "\\bnope\\b", "\\bnothing\\b", "\\bthat's it\\b", 
                "\\bthat's all\\b", "\\bi think that's everything\\b", 
                "\\bready\\b", "\\bgo ahead\\b", "\\byes\\b", "\\byeah\\b"
            ]
            let seemsDone = donePatterns.contains { pattern in
                (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                    .firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower))) != nil
            }
            
            // If they seem done OR if we've had a lot of back-and-forth (messageCount > 10)
            if seemsDone || messageCount > 10 {
                let nameRef = name ?? "your loved one"
                return "Thank you for sharing all of this about \(nameRef). I have everything I need to create a meaningful draft. Let me put that together for you now."
            }
            
            // Otherwise, acknowledge what they shared and gently offer to proceed
            if trimmed.count > 20 {
                // They shared something substantial
                let nameRef = name ?? "them"
                return "That's a wonderful detail about \(nameRef). Is there anything else you'd like me to include, or should I go ahead and create the draft?"
            } else {
                // Short response
                return "Got it. Is there anything else you'd like to add before I create the draft eulogy?"
            }
        }
        
        // Early conversation - just starting
        if messageCount <= 2 {
            return "Thank you for sharing that. I'd love to learn more about them. What stands out to you most about their character or personality?"
        }
        
        // Use context-aware responses based on what's already collected
        
        // If we just got a name, acknowledge it and move on
        if !hasName && (contains(lower, anyOf: ["name"]) || containsCapitalizedWords(userMessage)) {
            return "That's a beautiful name. To help me craft something truly personal, could you tell me about your relationship with them and what made it special?"
        }
        
        // If we have name but need relationship - REFERENCE the name
        if hasName && !hasRelationship {
            let nameRef = name ?? "them"
            if contains(lower, anyOf: ["mother", "father", "friend", "relationship", "grandmother", "grandfather", "partner", "spouse", "wife", "husband", "mom", "dad", "grandma", "grandpa", "aunt", "uncle", "cousin", "sister", "brother"]) {
                return "I can sense how meaningful your relationship with \(nameRef) was. What were some of \(toPossessive(hasPronouns)) most defining qualities or characteristics that people who knew \(toObject(hasPronouns)) would recognize immediately?"
            }
            return "Thank you for sharing about \(nameRef). Could you tell me about your relationship? For example, were they your mother, father, friend, or another loved one?"
        }
        
        // If we have name and relationship but need traits - REFERENCE both
        if hasName && hasRelationship && !hasTraits {
            let nameRef = name ?? "them"
            let relRef = relationship ?? "your loved one"
            if userMessage.split(separator: ",").count > 1 || contains(lower, anyOf: ["kind", "generous", "funny", "patient", "wise", "caring", "loving", "strong"]) {
                if !hasHobbies {
                    return "Those are wonderful qualities that really capture \(nameRef). What were some of the things \(hasPronouns) loved to do? Any hobbies or passions that brought \(toObject(hasPronouns)) joy?"
                } else if !hasStories {
                    return "Those qualities paint such a vivid picture of \(nameRef) as a \(relRef). Is there a particular story or moment that really captures \(toPossessive(hasPronouns)) essence?"
                } else {
                    return "Those are beautiful qualities. Is there anything about \(nameRef)'s beliefs or values that you'd like to include?"
                }
            }
            return "That's helpful. What were some of \(nameRef)'s most defining qualities? For example, was \(hasPronouns) patient, generous, funny, or something else that made \(toObject(hasPronouns)) special?"
        }
        
        // If we have basics but need hobbies - REFERENCE what we know
        if hasName && hasRelationship && hasTraits && !hasHobbies {
            let nameRef = name ?? "them"
            if contains(lower, anyOf: ["hobby", "love", "enjoy", "passion", "liked", "activity", "garden", "read", "cook"]) {
                if !hasStories {
                    return "That really brings \(nameRef) to life. Is there a particular story or moment that captures \(toPossessive(hasPronouns)) essence - something that makes you smile when you remember it?"
                } else {
                    return "That paints such a clear picture of who \(nameRef) was. Would you like to include any spiritual, religious, or humanist elements that honor \(toPossessive(hasPronouns)) beliefs?"
                }
            }
            return "I'm getting a clear sense of who \(nameRef) was. What did \(hasPronouns) love to do? Any hobbies, passions, or activities that brought \(toObject(hasPronouns)) joy?"
        }
        
        // If we need stories - REFERENCE previous information
        if hasName && hasRelationship && (hasTraits || hasHobbies) && !hasStories {
            let nameRef = name ?? "them"
            if userMessage.count > 50 || contains(lower, anyOf: ["story", "remember", "time", "once", "always"]) {
                if !hasBeliefs {
                    return "What a touching memory of \(nameRef). Before I help craft the eulogy, would you like to include any spiritual, religious, or humanist elements that would honor \(toPossessive(hasPronouns)) beliefs?"
                } else {
                    return "What a beautiful memory to share about \(nameRef). I have a wonderful sense of who \(hasPronouns) was now. Is there anything else you'd like me to know?"
                }
            }
            return "Could you share a story or memory that captures who \(nameRef) was? It could be something small but meaningful that shows \(toPossessive(hasPronouns)) character."
        }
        
        // If we have most information but need beliefs - REFERENCE the person
        if hasName && hasRelationship && hasTraits && hasStories && !hasBeliefs {
            let nameRef = name ?? "them"
            if contains(lower, anyOf: ["catholic", "christian", "jewish", "muslim", "buddhist", "hindu", "spiritual", "atheist", "humanist", "faith", "belief", "church", "temple", "no", "none"]) {
                return "Thank you for sharing that about \(nameRef). I believe I have everything I need to create a meaningful draft. Shall I put that together for you?"
            }
            return "Would you like to include any spiritual, religious, or humanist elements that would honor \(nameRef)'s beliefs? Or if \(hasPronouns) didn't have specific beliefs, that's perfectly fine too."
        }
        
        // If we have comprehensive information
        if hasName && hasRelationship && hasTraits && (hasHobbies || hasStories) {
            let nameRef = name ?? "them"
            return "Thank you for sharing all of this about \(nameRef). I have a wonderful sense of who \(hasPronouns) was. Is there anything else you'd like me to include, or should I create the draft?"
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
    
    private func extractName(from systemContext: String) -> String? {
        // Extract name from "- Name: XYZ" pattern
        guard let nameRange = systemContext.range(of: "- Name: ") else {
            return nil
        }
        let afterName = String(systemContext[nameRange.upperBound...])
        let nameLine = afterName.components(separatedBy: "\n").first ?? ""
        let name = nameLine.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
    
    private func extractRelationship(from systemContext: String) -> String? {
        // Extract relationship from "- Relationship: XYZ" pattern
        guard let relRange = systemContext.range(of: "- Relationship: ") else {
            return nil
        }
        let afterRel = String(systemContext[relRange.upperBound...])
        let relLine = afterRel.components(separatedBy: "\n").first ?? ""
        let relationship = relLine.trimmingCharacters(in: .whitespaces)
        return relationship.isEmpty ? nil : relationship
    }
    
    private func extractPronouns(from systemContext: String) -> String {
        // Extract pronouns from "- Pronouns: XYZ" pattern
        guard let pronounsRange = systemContext.range(of: "- Pronouns: ") else {
            return "they" // default
        }
        let afterPronouns = String(systemContext[pronounsRange.upperBound...])
        let pronounsLine = afterPronouns.components(separatedBy: "\n").first ?? ""
        let pronouns = pronounsLine.trimmingCharacters(in: .whitespaces)
        return pronouns.isEmpty ? "they" : pronouns
    }
    
    // Helper to convert subject pronouns to possessive form
    private func toPossessive(_ pronoun: String) -> String {
        switch pronoun.lowercased() {
        case "she": return "her"
        case "he": return "his"
        case "they": return "their"
        default: return "their"
        }
    }
    
    // Helper to convert subject pronouns to object form
    private func toObject(_ pronoun: String) -> String {
        switch pronoun.lowercased() {
        case "she": return "her"
        case "he": return "him"
        case "they": return "them"
        default: return "them"
        }
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
