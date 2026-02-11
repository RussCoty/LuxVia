import Foundation

/// Builds context-aware prompts for the LLM based on conversation state
struct LlamaPromptBuilder {
    
    /// Build a prompt for the LLM based on current conversation state
    static func buildPrompt(
        state: ConversationState,
        form: EulogyForm,
        lastUserMessage: String? = nil
    ) -> String {
        var prompt = """
        You are a compassionate assistant helping someone create a eulogy for their loved one.
        
        IMPORTANT RULES:
        - Be warm, empathetic, and respectful
        - Keep responses to 1-2 sentences maximum
        - Ask only ONE question at a time
        - Acknowledge what the user just shared
        - Use the person's name when known
        
        """
        
        // Add collected information to provide context
        if let name = form.subjectName {
            prompt += "\nDeceased person's name: \(name)"
        }
        if let relationship = form.relationship {
            prompt += "\nRelationship to user: \(relationship)"
        }
        if let age = form.age {
            prompt += "\nAge: \(age)"
        }
        if !form.traits.isEmpty {
            prompt += "\nPersonality traits shared: \(form.traits.joined(separator: ", "))"
        }
        if !form.hobbies.isEmpty {
            prompt += "\nHobbies/passions shared: \(form.hobbies.joined(separator: ", "))"
        }
        if !form.anecdotes.isEmpty {
            prompt += "\nStories shared: \(form.anecdotes.count)"
        }
        
        if let lastMessage = lastUserMessage {
            prompt += "\n\nUser's last message: \"\(lastMessage)\""
        }
        
        // Add state-specific instruction
        prompt += "\n\n"
        switch state {
        case .collectingName:
            prompt += "Ask for the deceased person's name in a gentle way."
        case .collectingRelationship:
            prompt += "Ask how the user was related to \(form.subjectName ?? "them")."
        case .collectingCharacterValues:
            prompt += "Ask about their core values or what mattered most to them. Acknowledge any previous details shared."
        case .collectingImpact:
            prompt += "Ask about the impact they had on others or their community."
        case .collectingFunnyMemory:
            prompt += "Ask for a funny or lighthearted memory that captures their personality."
        case .collectingCharacterMemory:
            prompt += "Ask for a memory that shows their character or who they really were."
        case .collectingHobbies:
            prompt += "Ask what they loved to do or what brought them joy. Reference any context already shared."
        case .collectingWhatYouWillMiss:
            prompt += "Ask what the user will miss most about them."
        case .collectingChallenges:
            prompt += "Ask if there were any challenges they overcame or adversity they faced."
        case .collectingSmallDetails:
            prompt += "Ask about small details that others might not know but that were meaningful."
        case .collectingBeliefs:
            prompt += "Ask if there are any spiritual, religious, or cultural elements they'd like included."
        case .collectingFinalThoughts:
            prompt += "Ask if there are any final thoughts or messages they'd like to include."
        case .readyForDraft:
            prompt += "Let them know you have enough to create a meaningful eulogy and ask if they'd like you to create it now."
        case .greeting:
            prompt += "Greet them warmly and explain you'll help create a meaningful eulogy."
        case .reviewingDraft:
            prompt += "Continue the conversation naturally based on their feedback about the draft."
        }
        
        prompt += "\n\nYour response (1-2 sentences):"
        
        return prompt
    }
}
