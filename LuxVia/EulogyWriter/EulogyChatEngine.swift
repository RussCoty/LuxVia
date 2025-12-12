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
""")
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

        // If we have enough information, generate the draft
        if form.isReadyForDraft {
            do {
                let draft = try await generator.generate(from: form)
                messages.append(.init(role: .draft, text: draft))
                messages.append(.init(role: .assistant, text:
"""
I've created a draft eulogy based on what you've shared. Please take a moment to read through it.

Would you like me to make any changes? I can adjust the tone (\(EulogyTone.allCases.map{$0.rawValue}.joined(separator:", "))), length (\(EulogyLength.allCases.map{$0.rawValue}.joined(separator:", "))), add or remove stories, or incorporate different elements.
"""))
            } catch {
                messages.append(.init(role: .assistant, text: "I encountered an issue generating the draft. Could we try again?"))
            }
            return
        }

        // Generate natural conversational response using LLM
        do {
            let response = try await generateLLMResponse()
            messages.append(.init(role: .assistant, text: response))
        } catch {
            // Fallback to asking next question if LLM fails
            messages.append(.init(role: .assistant, text: nextQuestion()))
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
            systemPrompt += "\n- Stories shared: \(form.anecdotes.count)"
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
        if form.relationship == nil { needed.append("relationship") }
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

    private func applyLabel(_ label: String, with text: String) {
        let lower = label.lowercased()
        switch true {
        case lower.contains("name"):
            if form.subjectName == nil { form.subjectName = extractLikelyName(from: text) ?? text }
        case lower.contains("relationship") || lower.contains("relation"):
            if form.relationship == nil { form.relationship = text }
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
        if form.subjectName == nil, let n = extractLikelyName(from: text) { form.subjectName = n }
        if form.relationship == nil,
           text.range(of: "(mother|mum|mom|father|dad|grand|friend|partner|wife|husband|colleague)", options: [.regularExpression, .caseInsensitive]) != nil {
            form.relationship = text
        }
    }

    private func inferPronouns(from text: String) {
        let lower = " " + text.lowercased() + " "
        if lower.contains(" she ") { form.pronouns = .she }
        else if lower.contains(" he ") { form.pronouns = .he }
    }

    private func extractLikelyName(from text: String) -> String? {
        let pattern = #"\b([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)\b"#
        if let r = try? NSRegularExpression(pattern: pattern),
           let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(m.range(at: 1), in: text) {
            return String(text[range])
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
