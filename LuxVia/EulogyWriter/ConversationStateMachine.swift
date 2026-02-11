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
        
        // Follow new question order
        if form.subjectName == nil {
            return .collectingName
        } else if form.relationship == nil {
            return .collectingRelationship
        } else if form.characterValues == nil {
            return .collectingCharacterValues
        } else if form.impact == nil {
            return .collectingImpact
        } else if form.funnyMemory == nil {
            return .collectingFunnyMemory
        } else if form.characterMemory == nil {
            return .collectingCharacterMemory
        } else if form.hobbies.isEmpty {
            return .collectingHobbies
        } else if form.whatYouWillMiss == nil {
            return .collectingWhatYouWillMiss
        } else if form.challengesOvercome == nil {
            // Optional - can be skipped
            return .collectingChallenges
        } else if form.smallDetails == nil {
            // Optional - can be skipped
            return .collectingSmallDetails
        } else if form.beliefsOrRituals == nil {
            // Optional - can be skipped
            return .collectingBeliefs
        } else if form.finalThoughts == nil {
            // Optional - can be skipped
            return .collectingFinalThoughts
        } else {
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
            return (nil, "Thank you for that. Let me ask you something else.")
            
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
            return (nil, "Thank you for sharing.")
            
        case .collectingCharacterValues:
            if !askedQuestions.contains(.characterValues) {
                askedQuestions.insert(.characterValues)
                let questionText = ResponseTemplates.response(
                    for: .characterValues,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.characterValues, questionText)
            }
            return (nil, "Thank you. Let me ask about something else.")
            
        case .collectingImpact:
            if !askedQuestions.contains(.impact) {
                askedQuestions.insert(.impact)
                let questionText = ResponseTemplates.response(
                    for: .impact,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.impact, questionText)
            }
            return (nil, "Thank you for sharing that.")
            
        case .collectingFunnyMemory:
            if !askedQuestions.contains(.funnyMemory) {
                askedQuestions.insert(.funnyMemory)
                let questionText = ResponseTemplates.response(
                    for: .funnyMemory,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.funnyMemory, questionText)
            }
            return (nil, "That's a wonderful memory.")
            
        case .collectingCharacterMemory:
            if !askedQuestions.contains(.characterMemory) {
                askedQuestions.insert(.characterMemory)
                let questionText = ResponseTemplates.response(
                    for: .characterMemory,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.characterMemory, questionText)
            }
            return (nil, "Thank you for sharing that memory.")
            
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
            return (nil, "Got it, thank you.")
            
        case .collectingWhatYouWillMiss:
            if !askedQuestions.contains(.whatYouWillMiss) {
                askedQuestions.insert(.whatYouWillMiss)
                let questionText = ResponseTemplates.response(
                    for: .whatYouWillMiss,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.whatYouWillMiss, questionText)
            }
            return (nil, "Thank you for sharing.")
            
        case .collectingChallenges:
            if !askedQuestions.contains(.challenges) {
                askedQuestions.insert(.challenges)
                let questionText = ResponseTemplates.response(
                    for: .challenges,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.challenges, questionText)
            }
            return (nil, "Thank you.")
            
        case .collectingSmallDetails:
            if !askedQuestions.contains(.smallDetails) {
                askedQuestions.insert(.smallDetails)
                let questionText = ResponseTemplates.response(
                    for: .smallDetails,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.smallDetails, questionText)
            }
            return (nil, "That's a lovely detail.")
            
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
            // If beliefs question was already asked, ask final thoughts
            return nextQuestion(form: form)
            
        case .collectingFinalThoughts:
            if !askedQuestions.contains(.finalThoughts) {
                askedQuestions.insert(.finalThoughts)
                let questionText = ResponseTemplates.response(
                    for: .finalThoughts,
                    name: form.subjectName,
                    relationship: form.relationship,
                    pronouns: form.pronouns
                )
                return (.finalThoughts, questionText)
            }
            // If all questions asked, offer draft
            return nextQuestion(form: form)
            
        case .readyForDraft:
            draftOffered = true
            let confirmationText = ResponseTemplates.draftConfirmation(name: form.subjectName)
            return (nil, confirmationText)
            
        case .reviewingDraft:
            return (nil, "How would you like me to adjust the draft?")
        }
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
        
        // Check for negation words first
        let negationPatterns = ["\\bnot\\b", "\\bdon't\\b", "\\bno\\b", "\\bnever\\b"]
        for pattern in negationPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
                return false
            }
        }
        
        // Affirmative patterns with word boundaries to avoid false positives
        let affirmativePatterns = [
            "\\byes\\b", "\\byeah\\b", "\\byep\\b", "\\bsure\\b", 
            "\\bok\\b", "\\bokay\\b", "\\bplease\\b",
            "\\bgo ahead\\b", "\\bproceed\\b", "\\bcreate\\b", 
            "\\bgenerate\\b", "\\bready\\b",
            "\\blet's do it\\b", "\\bsounds good\\b", "\\bperfect\\b"
        ]
        
        // Check for pattern matches using word boundaries
        for pattern in affirmativePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Check if user wants to skip optional question (like beliefs)
    func userWantsToSkip(_ text: String) -> Bool {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Skip patterns with word boundaries to avoid false positives
        let skipPatterns = [
            "\\bno\\b", "\\bnope\\b", "\\bskip\\b", "\\bpass\\b", 
            "\\bnone\\b", "\\bnothing\\b",
            "\\bno thanks\\b", "\\bthat's ok\\b", "\\bthat's okay\\b", 
            "\\bnot needed\\b", "\\bnot necessary\\b", "\\bdon't need\\b", 
            "\\bdoesn't matter\\b"
        ]
        
        // Check for pattern matches using word boundaries
        for pattern in skipPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)) != nil {
                return true
            }
        }
        
        return false
    }
}