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
    private let llmService: LLMService

    init(generator: EulogyGenerator = TemplateGenerator(), llmService: LLMService? = nil) {
        print("EulogyChatEngine initialized")
        self.generator = generator
        self.classifier = try! LuxSlotClassifier(configuration: MLModelConfiguration())
        
        // Try to get API key from Keychain (secure storage), otherwise use mock service
        let apiKey: String = {
            if let data = KeychainHelper.standard.read(service: "com.luxvia.eulogy", account: "openai_api_key"),
               let key = String(data: data, encoding: .utf8) {
                return key
            }
            return ""
        }()
        self.llmService = llmService ?? (apiKey.isEmpty ? MockLLMService() : OpenAIService(apiKey: apiKey))
        
        start()
    }

    func start() {
        print("EulogyChatEngine.start called")
        messages = [
            .init(role: .assistant, text:
"""
I'm here to help you create a meaningful and personal eulogy. This is a space where we can talk naturally about your loved one.

Please share whatever feels right to you - their name, who they were to you, what made them special, or any memories that come to mind. I'll listen and ask gentle questions along the way.
""", source: .preWritten)
        ]
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
        // This ensures we catch relationships even if classifier misses them
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

        // If we have enough information, generate the draft
        if form.isReadyForDraft {
            do {
                let draft = try await generator.generate(from: form)
                messages.append(.init(role: .draft, text: draft, source: .draft))
                messages.append(.init(role: .assistant, text:
"""
I've created a draft eulogy based on what you've shared. Please take a moment to read through it.

Would you like me to make any changes? I can adjust the tone (\(EulogyTone.allCases.map{$0.rawValue}.joined(separator:", "))), length (\(EulogyLength.allCases.map{$0.rawValue}.joined(separator:", "))), add or remove stories, or incorporate different elements.
""", source: .preWritten))
            } catch {
                messages.append(.init(role: .assistant, text: "I encountered an issue generating the draft. Could we try again?", source: .preWritten))
            }
            return
        }

        // Generate natural conversational response using LLM
        do {
            let response = try await generateLLMResponse()
            messages.append(.init(role: .assistant, text: response, source: .aiGenerated))
        } catch {
            // Fallback to asking next question if LLM fails
            messages.append(.init(role: .assistant, text: nextQuestion(), source: .preWritten))
        }
    }
    
    private func generateLLMResponse() async throws -> String {
        // Build context for the LLM
        var systemPrompt = """
        You are a compassionate assistant helping someone create a eulogy. Your role is to:
        - Have a natural, warm conversation
        - Ask thoughtful follow-up questions
        - Show empathy and understanding
        - Gently guide them to share: name, relationship, personality traits, hobbies, meaningful stories, achievements, and any spiritual/humanist preferences
        - Keep responses concise (2-3 sentences max)
        - Never be pushy or mechanical
        - Adapt your questions based on what they've already shared
        - If someone sends just a greeting (like "Hi", "Hello", etc.), warmly acknowledge it and guide them to share about their loved one
        - Validate inputs: don't treat greetings or short casual messages as meaningful information
        - When asking for a name, make it clear you need their full name, not just a greeting
        
        Information collected so far:
        """
        
        if let name = form.subjectName {
            systemPrompt += "\n- Name: \(name)"
        }
        if let rel = form.relationship {
            systemPrompt += "\n- Relationship: \(rel)"
        }
        if !form.traits.isEmpty {
            systemPrompt += "\n- Traits: \(form.traits.joined(separator: ", "))"
        }
        if !form.hobbies.isEmpty {
            systemPrompt += "\n- Hobbies: \(form.hobbies.joined(separator: ", "))"
        }
        if !form.anecdotes.isEmpty {
            systemPrompt += "\n- Stories shared (\(form.anecdotes.count)):\n"
            for (index, anecdote) in form.anecdotes.enumerated() {
                systemPrompt += "  \(index + 1). \(anecdote)\n"
            }
        }
        if !form.achievements.isEmpty {
            systemPrompt += "\n- Achievements: \(form.achievements.joined(separator: ", "))"
        }
        if let beliefs = form.beliefsOrRituals {
            systemPrompt += "\n- Beliefs/Rituals: \(beliefs)"
        }
        
        systemPrompt += "\n\nStill need: "
        var needed: [String] = []
        if form.subjectName == nil { needed.append("name") }
        if form.relationship == nil { 
            needed.append("relationship (to the deceased)")
        } else {
            // Explicitly indicate we HAVE the relationship so LLM doesn't ask again
            systemPrompt += "\n\n⚠️ IMPORTANT: Relationship already collected - DO NOT ask about it again."
        }
        if form.traits.isEmpty { needed.append("personality traits") }
        if form.hobbies.isEmpty { needed.append("hobbies/passions") }
        if form.anecdotes.isEmpty { needed.append("at least one story") }
        
        systemPrompt += needed.isEmpty ? "nothing critical, can generate draft soon" : needed.joined(separator: ", ")
        
        // Convert chat history to LLM format
        var llmMessages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt)
        ]
        
        // Add recent conversation context (last 6 messages to keep context window manageable)
        let recentMessages = messages.suffix(6)
        for msg in recentMessages {
            if msg.role == .user {
                llmMessages.append(LLMMessage(role: "user", content: msg.text))
            } else if msg.role == .assistant {
                llmMessages.append(LLMMessage(role: "assistant", content: msg.text))
            }
        }
        
        return try await llmService.chat(messages: llmMessages)
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
            // Lower priority number = higher importance
            if m1.priority != m2.priority {
                return m1.priority > m2.priority
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
        case lower.contains("trait"):
            form.traits.append(text)
        case lower.contains("hobby") || lower.contains("interest"):
            form.hobbies.append(text)
        case lower.contains("anecdote") || lower.contains("story"):
            form.anecdotes.append(text)
        case lower.contains("achievement") || lower.contains("milestone"):
            form.achievements.append(text)
        case lower.contains("belief") || lower.contains("faith") || lower.contains("ritual"):
            form.beliefsOrRituals = text
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

    private func nextQuestion() -> String {
        if form.subjectName == nil { return "What was their **full name**?" }
        if form.relationship == nil { return "And how were you **related**?" }
        if form.traits.isEmpty { return "Tell me a few **qualities** that capture them (e.g., generous, determined, patient)." }
        if form.hobbies.isEmpty { return "What did they **love doing** — hobbies, passions, rituals?" }
        if form.anecdotes.isEmpty { return "Could you share **one short story** that friends/family always mention?" }
        if form.beliefsOrRituals == nil { return "Should we include any **religious or humanist** elements?" }
        return "Would you like a **warm**, **solemn**, **celebratory**, or **light/humorous** tone, and roughly **short/standard/long** length?"
    }
}
