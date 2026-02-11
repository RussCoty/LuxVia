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
        // If name question already asked but not collected, acknowledge and move on
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
        return (nil, "Thank you. Let me ask about something else.")
        
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
        return (nil, "Thank you for sharing that.")
        
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
}