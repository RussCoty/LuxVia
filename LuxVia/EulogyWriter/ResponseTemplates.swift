import Foundation

/// Provides context-aware response templates for conversation
struct ResponseTemplates {
    
    /// Get a randomized response for the given question type with context
    static func response(
        for questionType: QuestionType,
        name: String?,
        relationship: String?,
        pronouns: Pronouns
    ) -> String {
        let nameRef = name ?? "them"
        let pronoun = pronouns.rawValue
        let possessive = possessiveForm(of: pronouns)
        let objective = objectiveForm(of: pronouns)
        let reflexive = reflexiveForm(of: pronouns)
        
        switch questionType {
        case .name:
            return randomChoice(from: [
                "To begin, could you share their name?",
                "What was their name?",
                "Let's start with their name."
            ])
            
        case .relationship:
            let templates = [
                "What was your relationship to \(nameRef)?",
                "How were you connected to \(nameRef)?",
                "Could you tell me about your relationship with \(nameRef)?"
            ]
            return randomChoice(from: templates)
            
        case .characterValues:
            let templates = [
                "What mattered most to \(nameRef) in life?",
                "What values or principles did \(nameRef) live by?",
                "What was most important to \(nameRef)?"
            ]
            return randomChoice(from: templates)
            
        case .impact:
            let templates = [
                "How did \(nameRef) impact your life or the lives of others?",
                "In what ways did \(nameRef) make a difference?",
                "How did knowing \(nameRef) change you or others?"
            ]
            return randomChoice(from: templates)
            
        case .funnyMemory:
            let templates = [
                "Can you share a funny or lighthearted memory of \(nameRef)?",
                "What's a moment with \(nameRef) that always makes you smile?",
                "Do you have a humorous story about \(nameRef) you'd like to share?"
            ]
            return randomChoice(from: templates)
            
        case .characterMemory:
            let reflexivePronoun = reflexive
            let templates = [
                "Share a moment that shows who \(nameRef) really was",
                "What's a story that captures \(nameRef)'s character?",
                "Can you describe a time when \(nameRef) was truly \(reflexivePronoun)?"
            ]
            return randomChoice(from: templates)
            
        case .hobbies:
            let templates = [
                "What did \(nameRef) love to do?",
                "What were some of \(possessive) favorite activities or hobbies?",
                "What brought \(nameRef) joy in life?",
                "What passions or interests did \(pronoun) have?"
            ]
            return randomChoice(from: templates)
            
        case .whatYouWillMiss:
            let templates = [
                "What will you miss most about \(nameRef)?",
                "What about \(nameRef) will stay with you forever?",
                "What do you wish you could experience one more time with \(nameRef)?"
            ]
            return randomChoice(from: templates)
            
        case .challenges:
            let templates = [
                "What challenges or hardships did \(nameRef) overcome? (You can skip this if you'd prefer)",
                "Were there any difficult times that showed \(nameRef)'s strength? (Optional)",
                "What adversity did \(nameRef) face with courage? (Feel free to skip)"
            ]
            return randomChoice(from: templates)
            
        case .smallDetails:
            let wasWere = pronoun == "they" ? "were" : "was"
            let templates = [
                "What's a small detail about \(nameRef) that people might not know? A favorite song, daily habit, or something uniquely \(objective)? (Optional)",
                "Was there a quirk, routine, or little thing that was so \(nameRef)? (You can skip this)",
                "What small detail made \(nameRef) who \(pronoun) \(wasWere)? (Optional)"
            ]
            return randomChoice(from: templates)
            
        case .beliefs:
            let templates = [
                "Should we include any spiritual or humanist elements?",
                "Were there any religious or spiritual beliefs important to \(nameRef)?",
                "Would you like to mention any faith traditions or values that mattered to \(objective)?",
                "Are there any beliefs, rituals, or values you'd like to include?"
            ]
            return randomChoice(from: templates)
            
        case .finalThoughts:
            let templates = [
                "Is there anything else you'd like included in the eulogy?",
                "Any final thoughts or memories you'd like to add?",
                "What else should be said about \(nameRef)?"
            ]
            return randomChoice(from: templates)
        }
    }
    
    /// Get confirmation message for draft readiness
    static func draftConfirmation(name: String?) -> String {
        let nameRef = name ?? "your loved one"
        return "I have everything I need to create a meaningful eulogy for \(nameRef). Would you like me to create the draft now?"
    }
    
    /// Get acknowledgment of new information with transition to next question
    static func acknowledgmentWithTransition(
        collectedInfo: String,
        nextQuestion: String
    ) -> String {
        let acknowledgments = [
            "Thank you for sharing that.",
            "I appreciate you telling me that.",
            "That's helpful, thank you."
        ]
        let ack = randomChoice(from: acknowledgments)
        return "\(ack) \(nextQuestion)"
    }
    
    // MARK: - Helper Functions
    
    private static func possessiveForm(of pronouns: Pronouns) -> String {
        switch pronouns {
        case .she: return "her"
        case .he: return "his"
        case .they: return "their"
        }
    }
    
    private static func objectiveForm(of pronouns: Pronouns) -> String {
        switch pronouns {
        case .she: return "her"
        case .he: return "him"
        case .they: return "them"
        }
    }
    
    private static func reflexiveForm(of pronouns: Pronouns) -> String {
        switch pronouns {
        case .she: return "herself"
        case .he: return "himself"
        case .they: return "themself"
        }
    }
    
    private static func randomChoice<T>(from array: [T]) -> T {
        // Precondition: array must not be empty (all callers pass non-empty arrays)
        precondition(!array.isEmpty, "Cannot select random element from empty array")
        return array.randomElement()!
    }
}
