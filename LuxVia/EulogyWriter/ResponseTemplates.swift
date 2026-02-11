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
            
        case .characterValues:
            let templates = [
                "What were some of \(nameRef)'s core values?",
                "What mattered most to \(nameRef) in life?",
                "What principles or values guided \(possessive) life?",
                "What did \(nameRef) believe in or stand for?"
            ]
            return randomChoice(from: templates)
            
        case .impact:
            let templates = [
                "What impact did \(nameRef) have on others?",
                "How did \(nameRef) make a difference in \(possessive) community?",
                "Who or what did \(nameRef) influence most?",
                "What legacy did \(pronoun) leave behind?"
            ]
            return randomChoice(from: templates)
            
        case .funnyMemory:
            let templates = [
                "Can you share a funny or lighthearted memory of \(nameRef)?",
                "What's a humorous moment that shows \(possessive) personality?",
                "Is there a funny story about \(nameRef) that always makes you smile?",
                "What would make \(nameRef) laugh?"
            ]
            return randomChoice(from: templates)
            
        case .characterMemory:
            let templates = [
                "Could you share a memory that shows who \(nameRef) really was?",
                "Is there a moment that captures \(possessive) character?",
                "What's a story that reveals \(possessive) true nature?",
                "Share a memory that shows what made \(nameRef) special."
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
                "What about \(nameRef) will you carry with you?",
                "What will be hardest to live without?",
                "What aspects of \(nameRef) do you wish could continue?"
            ]
            return randomChoice(from: templates)
            
        case .challenges:
            let templates = [
                "Were there any challenges or adversity that \(nameRef) overcame?",
                "What obstacles did \(pronoun) face in life?",
                "How did \(nameRef) handle difficult times?",
                "What did \(pronoun) persevere through?"
            ]
            return randomChoice(from: templates)
            
        case .smallDetails:
            let templates = [
                "Are there small details about \(nameRef) that others might not know?",
                "What little things made \(nameRef) unique?",
                "What quirks or habits did \(pronoun) have?",
                "What small moments or details were meaningful to you?"
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
                "Are there any final thoughts or messages you'd like to include?",
                "Is there anything else you want people to know about \(nameRef)?",
                "What haven't we covered that feels important?",
                "Any last wishes or thoughts to share?"
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
        // Precondition: array must not be empty (all callers pass non-empty arrays)
        precondition(!array.isEmpty, "Cannot select random element from empty array")
        return array.randomElement()!
    }
}
