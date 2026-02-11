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
            
        case .traits:
            let templates = [
                "What were some of \(nameRef)'s most memorable qualities?",
                "How would you describe \(nameRef)'s character or personality?",
                "What qualities made \(nameRef) special to those who knew \(objective)?",
                "What are 2-3 words that best describe \(nameRef)?"
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
            
        case .stories:
            let templates = [
                "Could you share a memory of \(nameRef) that stands out to you?",
                "Is there a particular story that captures who \(nameRef) was?",
                "What's a moment with \(nameRef) that you'll always remember?",
                "Share a story that shows what made \(nameRef) special."
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
    
    private static func randomChoice<T>(from array: [T]) -> T {
        return array.randomElement() ?? array[0]
    }
}
