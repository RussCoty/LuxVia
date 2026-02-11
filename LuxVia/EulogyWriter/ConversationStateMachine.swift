import Foundation

/// State machine that manages conversation flow and prevents repetitive questions
@MainActor
final class ConversationStateMachine {
    
    /// Current state of the conversation
    private(set) var currentState: ConversationState = .greeting
    
    /// Set of questions that have already been asked
    private(set) var askedQuestions: Set<QuestionType> = []
    
    /// Track if draft has been offered to the user
    private(set) var draftOffered: Bool = false
    
    /// Determine the next state based on collected information
    func determineNextState(form: EulogyForm) -> ConversationState {
        // If draft is ready, move to that state
        if form.isReadyForDraft && !draftOffered {
            return .readyForDraft
        }
        
        // If we're reviewing draft, stay there
        if currentState == .reviewingDraft {
            return .reviewingDraft
        }
        
        // Otherwise, determine state based on what's collected
        if form.subjectName == nil {
            return .collectingName
        } else if form.relationship == nil {
            return .collectingRelationship
        } else if form.traits.isEmpty {
            return .collectingTraits
        } else if form.hobbies.isEmpty && form.anecdotes.isEmpty {
            // Need at least one of hobbies or stories
            return .collectingHobbies
        } else if form.hobbies.isEmpty {
            return .collectingHobbies
        } else if form.anecdotes.isEmpty {
            return .collectingStories
        } else if form.beliefsOrRituals == nil {
            // Beliefs are optional, but we'll offer to collect them
            return .collectingBeliefs
        } else {
            // We have everything
            return .readyForDraft
        }
    }
    
    /// Get the next question to ask based on current state and what's been asked
    func nextQuestion(form: EulogyForm) -> (questionType: QuestionType?, text: String) {
        // Update state based on collected info
        currentState = determineNextState(form: form)
        
        switch currentState {
        case .greeting:
            // This shouldn't happen after initial greeting
            return (nil, "I'm here to help you create a meaningful eulogy. Let's begin.")
            
        case .collectingName:
            if !askedQuestions.contains(.name) {
                askedQuestions.insert(.name)
                let questionText = ResponseTemplates.response(
                    for: .name,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.name, questionText)
            }
            
        case .collectingRelationship:
            if !askedQuestions.contains(.relationship) {
                askedQuestions.insert(.relationship)
                let questionText = ResponseTemplates.response(
                    for: .relationship,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.relationship, questionText)
            }
            
        case .collectingTraits:
            if !askedQuestions.contains(.traits) {
                askedQuestions.insert(.traits)
                let questionText = ResponseTemplates.response(
                    for: .traits,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.traits, questionText)
            }
            
        case .collectingHobbies:
            if !askedQuestions.contains(.hobbies) {
                askedQuestions.insert(.hobbies)
                let questionText = ResponseTemplates.response(
                    for: .hobbies,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.hobbies, questionText)
            }
            
        case .collectingStories:
            if !askedQuestions.contains(.stories) {
                askedQuestions.insert(.stories)
                let questionText = ResponseTemplates.response(
                    for: .stories,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.stories, questionText)
            }
            
        case .collectingBeliefs:
            if !askedQuestions.contains(.beliefs) {
                askedQuestions.insert(.beliefs)
                let questionText = ResponseTemplates.response(
                    for: .beliefs,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.beliefs, questionText)
            }
            // If beliefs question was already asked, move to ready state
            currentState = .readyForDraft
            fallthrough
            
        case .readyForDraft:
            draftOffered = true
            let confirmationText = ResponseTemplates.draftConfirmation(name: form.subjectName)
            return (nil, confirmationText)
            
        case .reviewingDraft:
            return (nil, "How would you like me to adjust the draft?")
        }
        
        // Fallback - should not reach here under normal flow
        return (nil, "Is there anything else you'd like to share?")
    }
    
    /// Mark that the draft has been generated
    func markDraftGenerated() {
        currentState = .reviewingDraft
    }
    
    /// Reset the state machine (for testing or restart)
    func reset() {
        currentState = .greeting
        askedQuestions.removeAll()
        draftOffered = false
    }
    
    /// Check if a specific question type has been asked
    func hasAsked(_ questionType: QuestionType) -> Bool {
        return askedQuestions.contains(questionType)
    }
    
    /// Check if user's response indicates they want to proceed with draft
    func userWantsDraft(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Affirmative patterns
        let affirmativePatterns = [
            "yes", "yeah", "yep", "sure", "ok", "okay", "please",
            "go ahead", "proceed", "create", "generate", "ready",
            "let's do it", "sounds good", "perfect"
        ]
        
        // Check for exact matches or common affirmative phrases
        for pattern in affirmativePatterns {
            if lower == pattern || lower.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if user wants to skip optional question (like beliefs)
    func userWantsToSkip(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let skipPatterns = [
            "no", "nope", "skip", "pass", "none", "nothing",
            "no thanks", "that's ok", "that's okay", "not needed",
            "not necessary", "don't need", "doesn't matter"
        ]
        
        for pattern in skipPatterns {
            if lower == pattern || lower.starts(with: pattern) {
                return true
            }
        }
        
        return false
    }
}
