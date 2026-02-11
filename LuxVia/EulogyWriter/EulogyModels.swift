import Foundation

enum EulogyTone: String, Codable, CaseIterable { case solemn, warm, celebratory, humorous }
enum EulogyLength: String, Codable, CaseIterable { case short, standard, long }
enum Pronouns: String, Codable { case she, he, they }

struct EulogyForm: Codable {
    var subjectName: String?
    var age: Int?
    var relationship: String?
    var pronouns: Pronouns = .they
    var tone: EulogyTone = .warm
    var length: EulogyLength = .standard

    // NEW: Replace traits with characterValues
    var characterValues: String?
    
    // NEW: Impact field
    var impact: String?
    
    // Enhanced anecdotes with specific story fields
    var anecdotes: [String] = []  // Keep for backward compatibility
    var funnyMemory: String?
    var characterMemory: String?
    
    var hobbies: [String] = []
    
    // NEW: Emotional connection
    var whatYouWillMiss: String?
    
    // NEW: Optional depth fields
    var challengesOvercome: String?
    var smallDetails: String?
    
    var beliefsOrRituals: String?
    
    // NEW: Final thoughts
    var finalThoughts: String?
    
    var achievements: [String] = []
    var audienceNotes: String?
    
    // Legacy field for backward compatibility
    var traits: [String] = []

    var isReadyForDraft: Bool {
        subjectName != nil &&
        relationship != nil &&
        characterValues != nil &&
        impact != nil &&
        (funnyMemory != nil || characterMemory != nil) &&
        !hobbies.isEmpty &&
        whatYouWillMiss != nil
    }
    
    func checklist() -> String {
        var items: [String] = []
        
        func checklistItem(_ condition: Bool, required: String, optional: String? = nil) -> String {
            if let opt = optional {
                return condition ? "✓ \(required)" : "○ \(required) (\(opt))"
            }
            return condition ? "✓ \(required)" : "○ \(required)"
        }
        
        items.append(subjectName != nil ? "✓ Name" : "○ Name")
        if let age = age {
            items.append("✓ Age (\(age))")
        } else {
            items.append("○ Age")
        }
        items.append(checklistItem(relationship != nil, required: "Relationship"))
        items.append(checklistItem(characterValues != nil, required: "Character/values"))
        items.append(checklistItem(impact != nil, required: "Impact"))
        items.append(checklistItem(funnyMemory != nil, required: "Funny memory"))
        items.append(checklistItem(characterMemory != nil, required: "Character moment"))
        items.append(checklistItem(!hobbies.isEmpty, required: "Hobbies/passions"))
        items.append(checklistItem(whatYouWillMiss != nil, required: "What you'll miss"))
        items.append(checklistItem(challengesOvercome != nil, required: "Challenges overcome", optional: "optional"))
        items.append(checklistItem(smallDetails != nil, required: "Small details", optional: "optional"))
        items.append(checklistItem(beliefsOrRituals != nil, required: "Beliefs/rituals", optional: "optional"))
        items.append(checklistItem(finalThoughts != nil, required: "Final thoughts", optional: "optional"))
        
        return items.joined(separator: "\n")
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let text: String
    let source: MessageSource
    
    enum Role { case user, assistant, draft }
    enum MessageSource { case user, aiGenerated, preWritten, draft }
    
    init(role: Role, text: String, source: MessageSource? = nil) {
        self.role = role
        self.text = text
        // Auto-determine source based on role if not explicitly provided
        if let source = source {
            self.source = source
        } else {
            switch role {
            case .user:
                self.source = .user
            case .draft:
                self.source = .draft
            case .assistant:
                self.source = .preWritten // default for assistant
            }
        }
    }
}
