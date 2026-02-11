import Foundation
import Combine
import CoreML

@MainActor
final class EulogyChatEngine: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var form = EulogyForm()
    @Published var isThinking = false

    private let generator: EulogyGenerator
    private let classifier: LuxSlotClassifier
    private let stateMachine = ConversationStateMachine()

    init(generator: EulogyGenerator = TemplateGenerator()) {
        print("EulogyChatEngine initialized with state machine")
        self.generator = generator
        self.classifier = try! LuxSlotClassifier(configuration: MLModelConfiguration())
        
        // Load service details if available
        if let bookletInfo = BookletInfo.load() {
            if !bookletInfo.deceasedName.isEmpty {
                form.subjectName = bookletInfo.deceasedName
            }
            // Calculate age from dates
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: bookletInfo.dateOfBirth, to: bookletInfo.dateOfPassing)
            if let years = ageComponents.year, years >= 0 {
                form.age = years
            }
        }
        
        start()
    }

    func start() {
        print("EulogyChatEngine.start called")
        
        // Customize greeting based on available info
        var greeting = "I'm here to help you create a meaningful eulogy"
        if let name = form.subjectName {
            greeting += " for \(name)"
            if let age = form.age {
                greeting += " (age \(age))"
            }
        }
        greeting += "."
        
        greeting += "\n\nI'll ask you focused questions to gather what's needed. You'll see your progress before each question."
        
        messages = [
            .init(role: .assistant, text: greeting, source: .preWritten)
        ]
        
        // Ask first question
        Task {
            await askNextQuestion()
        }
    }

    func send(_ text: String) {
        print("send called with text: \(text)")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(.init(role: .user, text: text))
        Task { await handle(text) }
    }

    private func handle(_ text: String) async {
        print("handle called with text: \(text)")
        isThinking = true
        defer { isThinking = false }

        // Apply keyword-based relationship detection FIRST (before classifier)
        extractRelationshipFromKeywords(text)
        print("📋 Form state after keyword extraction - relationship: \(form.relationship ?? "nil")")

        // Extract information using ML classifier
        var label = "unknown"
        do {
            let res = try classifier.prediction(text: text)
            label = res.label
            print("Classifier label: \(label)")
        } catch {
            // fall back
        }

        // Apply heuristics and label to extract structured data
        applyHeuristics(from: text)
        applyLabel(label, with: text)
        print("📋 Final form state - name: \(form.subjectName ?? "nil"), relationship: \(form.relationship ?? "nil"), pronouns: \(form.pronouns.rawValue)")

        // Check if we're in the draft readiness state and user wants to proceed
        if stateMachine.currentState == .readyForDraft && stateMachine.userWantsDraft(text) {
            await generateDraft()
            return
        }
        
        // Check if user wants to skip optional questions
        let optionalStates: [ConversationState] = [.collectingChallenges, .collectingSmallDetails, .collectingBeliefs, .collectingFinalThoughts]
        if optionalStates.contains(stateMachine.currentState) && stateMachine.userWantsToSkip(text) {
            // Mark the optional field as skipped by setting it to empty string
            switch stateMachine.currentState {
            case .collectingChallenges:
                form.challengesOvercome = ""
            case .collectingSmallDetails:
                form.smallDetails = ""
            case .collectingBeliefs:
                form.beliefsOrRituals = ""
            case .collectingFinalThoughts:
                form.finalThoughts = ""
            default:
                break
            }
            // Move to next question
            await askNextQuestion()
            return
        }

        // Ask next question based on state machine
        await askNextQuestion()
    }
    
    /// Generate and display the draft eulogy
    private func generateDraft() async {
        do {
            let draft = try await generator.generate(from: form)
            messages.append(.init(role: .draft, text: draft, source: .draft))
            messages.append(.init(role: .assistant, text:
"""
I've created a draft eulogy based on what you've shared. Please take a moment to read through it.

Would you like me to make any changes? I can adjust the tone (\(EulogyTone.allCases.map{$0.rawValue}.joined(separator:", "))), length (\(EulogyLength.allCases.map{$0.rawValue}.joined(separator:", "))), add or remove stories, or incorporate different elements.
""", source: .preWritten))
            stateMachine.markDraftGenerated()
        } catch {
            messages.append(.init(role: .assistant, text: "I encountered an issue generating the draft. Could we try again?", source: .preWritten))
        }
    }
    
    /// Ask the next question based on the state machine
    private func askNextQuestion() async {
        // Get next question from state machine (questionType not currently used but kept for future debugging)
        let (questionType, questionText) = stateMachine.nextQuestion(form: form)
        
        // Add progress checklist before the question
        let checklist = form.checklist()
        let fullMessage = "**Progress:**\n\(checklist)\n\n\(questionText)"
        
        messages.append(.init(role: .assistant, text: fullMessage, source: .preWritten))
    }
    
    private func extractRelationshipFromKeywords(_ text: String) {
        // Skip if relationship already extracted
        guard form.relationship == nil else { return }
        
        let lower = text.lowercased()
        
        // Define relationship keywords with their normalized forms
        let relationshipMap: [(keywords: [String], normalized: String, priority: Int)] = [
            // Family relationships get higher priority (1)
            // Grandparents
            (["grandmother", "grandma", "granny", "nana", "gran"], "grandmother", 1),
            (["grandfather", "grandpa", "granddad", "gramps"], "grandfather", 1),
            
            // Parents
            (["mother", "mom", "mum", "mama", "mommy"], "mother", 1),
            (["father", "dad", "papa", "daddy"], "father", 1),
            
            // Siblings
            (["sister"], "sister", 1),
            (["brother"], "brother", 1),
            
            // Extended family
            (["aunt", "auntie"], "aunt", 1),
            (["uncle"], "uncle", 1),
            (["cousin"], "cousin", 1),
            (["niece"], "niece", 1),
            (["nephew"], "nephew", 1),
            (["daughter"], "daughter", 1),
            (["son"], "son", 1),
            
            // Marriage/Partnership (high priority)
            (["wife"], "wife", 1),
            (["husband"], "husband", 1),
            (["spouse"], "spouse", 1),
            (["partner"], "partner", 1),
            
            // Multi-word must come before single word (check "best friend" before "friend")
            (["best friend", "bestfriend"], "best friend", 2),
            
            // Other relationships (lower priority - 3)
            (["colleague", "coworker", "co-worker"], "colleague", 3),
            (["mentor"], "mentor", 3),
            (["teacher"], "teacher", 3),
            (["neighbor", "neighbour"], "neighbor", 3),
            (["friend"], "friend", 4)  // Lowest priority since it's most general
        ]
        
        // Keep track of all matches
        struct Match {
            let normalized: String
            let position: Int
            let priority: Int
            let hasStrongContext: Bool
        }
        var matches: [Match] = []
        
        // Search for relationship patterns
        for (keywords, normalized, priority) in relationshipMap {
            for keyword in keywords {
                // Use word boundary regex for exact matching
                let pattern = "\\b\(keyword)\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
                
                let nsRange = NSRange(lower.startIndex..<lower.endIndex, in: lower)
                let regexMatches = regex.matches(in: lower, options: [], range: nsRange)
                
                for regexMatch in regexMatches {
                    if let range = Range(regexMatch.range, in: lower) {
                        let position = lower.distance(from: lower.startIndex, to: range.lowerBound)
                        
                        // Check context before the keyword
                        let contextStart = lower.index(range.lowerBound, offsetBy: -30, limitedBy: lower.startIndex) ?? lower.startIndex
                        let context = String(lower[contextStart..<range.upperBound])
                        
                        // Strong context = possessive my/our/the before the keyword
                        let hasStrongContext = context.contains("my \(keyword)") ||
                                             context.contains("our \(keyword)") ||
                                             context.contains("the \(keyword)")
                        
                        matches.append(Match(
                            normalized: normalized,
                            position: position,
                            priority: priority,
                            hasStrongContext: hasStrongContext
                        ))
                    }
                }
            }
        }
        
        // Filter to only strong context matches if we have any
        let strongMatches = matches.filter { $0.hasStrongContext }
        let finalMatches = strongMatches.isEmpty ? matches : strongMatches
        
        // Among matches (preferably with strong context), select based on:
        // 1. Higher priority family relationships (lower number = higher priority)
        // 2. Latest position (for "my mom's sister, my aunt" → pick "aunt")
        if let bestMatch = finalMatches.min(by: { m1, m2 in
            // Lower priority number = higher importance (1 beats 4)
            if m1.priority != m2.priority {
                return m1.priority < m2.priority
            }
            // Later position wins (pick the last/most specific relationship)
            return m1.position < m2.position
        }) {
            form.relationship = bestMatch.normalized
            print("✅ Relationship extracted: '\(bestMatch.normalized)' from text: '\(text)' (priority: \(bestMatch.priority), strong context: \(bestMatch.hasStrongContext))")
            
            // Try to infer pronouns from relationship
            inferPronounsFromRelationship(bestMatch.normalized)
        }
    }
    
    private func inferPronounsFromRelationship(_ relationship: String) {
        // Only infer if pronouns haven't been explicitly set
        guard form.pronouns == .they else { return }
        
        let lower = relationship.lowercased()
        
        // Female relationships
        if ["mother", "grandmother", "sister", "aunt", "niece", "daughter", "wife"].contains(lower) {
            form.pronouns = .she
            print("✅ Pronouns inferred: 'she' from relationship '\(relationship)'")
        }
        // Male relationships
        else if ["father", "grandfather", "brother", "uncle", "nephew", "son", "husband"].contains(lower) {
            form.pronouns = .he
            print("✅ Pronouns inferred: 'he' from relationship '\(relationship)'")
        }
    }

    private func applyLabel(_ label: String, with text: String) {
        let lower = label.lowercased()
        
        // Helper to add anecdote if not already present
        func addAnecdote(_ text: String) {
            if !form.anecdotes.contains(text) {
                form.anecdotes.append(text)
            }
        }
        
        switch true {
        case lower.contains("name"):
            if form.subjectName == nil, let validName = extractValidName(from: text) {
                form.subjectName = validName
            }
        case lower.contains("relationship") || lower.contains("relation"):
            // Extract just the relationship keyword from the text, not the entire message
            if form.relationship == nil {
                extractRelationshipFromKeywords(text)
            }
            if form.pronouns == .they { inferPronouns(from: text) }
        case lower.contains("impact") || lower.contains("difference") || lower.contains("change"):
            form.impact = text
        case lower.contains("funny") || lower.contains("humor") || lower.contains("lighthearted"):
            form.funnyMemory = text
            addAnecdote(text)
        case lower.contains("moment") && (lower.contains("character") || lower.contains("defining") || lower.contains("shows who")):
            form.characterMemory = text
            addAnecdote(text)
        case lower.contains("character") || lower.contains("value") || lower.contains("principle"):
            form.characterValues = text
        case lower.contains("trait"):
            // Keep for backward compatibility
            form.traits.append(text)
            if form.characterValues == nil {
                form.characterValues = text
            }
        case lower.contains("hobby") || lower.contains("interest"):
            form.hobbies.append(text)
        case lower.contains("miss") || lower.contains("remember"):
            form.whatYouWillMiss = text
        case lower.contains("challenge") || lower.contains("hardship") || lower.contains("overcome"):
            form.challengesOvercome = text
        case lower.contains("detail") || lower.contains("quirk") || lower.contains("habit"):
            form.smallDetails = text
        case lower.contains("anecdote") || lower.contains("story"):
            addAnecdote(text)
        case lower.contains("achievement") || lower.contains("milestone"):
            form.achievements.append(text)
        case lower.contains("belief") || lower.contains("faith") || lower.contains("ritual"):
            form.beliefsOrRituals = text
        case lower.contains("final") || lower.contains("else") || lower.contains("add"):
            form.finalThoughts = text
        case lower.contains("tone"):
            if text.range(of: "solemn", options: .caseInsensitive) != nil { form.tone = .solemn }
            else if text.range(of: "celebrat", options: .caseInsensitive) != nil { form.tone = .celebratory }
            else if text.range(of: "humor|humour|light", options: [.caseInsensitive, .regularExpression]) != nil { form.tone = .humorous }
            else { form.tone = .warm }
        case lower.contains("length") || lower.contains("duration"):
            if text.range(of: "short|3 ?min", options: [.caseInsensitive, .regularExpression]) != nil { form.length = .short }
            else if text.range(of: "long|7 ?min|10 ?min", options: [.caseInsensitive, .regularExpression]) != nil { form.length = .long }
            else { form.length = .standard }
        default:
            break
        }
    }

    private func applyHeuristics(from text: String) {
        inferPronouns(from: text)
        if form.subjectName == nil, let n = extractValidName(from: text) { form.subjectName = n }
        
        // Use the robust keyword-based relationship extraction
        if form.relationship == nil {
            extractRelationshipFromKeywords(text)
        }
    }

    private func inferPronouns(from text: String) {
        let lower = " " + text.lowercased() + " "
        if lower.contains(" she ") { form.pronouns = .she }
        else if lower.contains(" he ") { form.pronouns = .he }
    }

    private func extractValidName(from text: String) -> String? {
        // Common greetings and invalid inputs to filter out
        let invalidInputs = [
            "hi", "hello", "hey", "greetings", "good morning", "good afternoon", 
            "good evening", "thanks", "thank you", "yes", "no", "okay", "ok",
            "sure", "alright", "please", "help", "start", "begin"
        ]
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerText = trimmedText.lowercased()
        
        // Filter out common greetings and short inputs
        if invalidInputs.contains(lowerText) || trimmedText.count < 2 {
            return nil
        }
        
        // Filter out single words that are too short to be a name (less than 2 characters)
        if !trimmedText.contains(" ") && trimmedText.count < 2 {
            return nil
        }
        
        // Try to extract a proper name (capitalized words)
        let pattern = #"\b([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)\b"#
        if let r = try? NSRegularExpression(pattern: pattern),
           let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(m.range(at: 1), in: text) {
            let extractedName = String(text[range])
            // Validate the extracted name is not an invalid input
            if !invalidInputs.contains(extractedName.lowercased()) {
                return extractedName
            }
        }
        
        // If no capitalized multi-word name found, check if it's a single capitalized word
        // that's at least 2 characters and not in our invalid list
        let singleWordPattern = #"\b([A-Z][a-z]{1,})\b"#
        if let r = try? NSRegularExpression(pattern: singleWordPattern),
           let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(m.range(at: 1), in: text) {
            let extractedName = String(text[range])
            // Only accept if it's at least 2 characters and not an invalid input
            if extractedName.count >= 2 && !invalidInputs.contains(extractedName.lowercased()) {
                return extractedName
            }
        }
        
        return nil
    }
}
