import Foundation

/// Represents the current stage of the conversation
enum ConversationState: String, Codable {
    case greeting
    case collectingName
    case collectingRelationship
    case collectingTraits
    case collectingHobbies
    case collectingStories
    case collectingBeliefs
    case readyForDraft
    case reviewingDraft
}

/// Types of questions that can be asked - used to track what has been asked
enum QuestionType: String, Hashable, CaseIterable {
    case name
    case relationship
    case traits
    case hobbies
    case stories
    case beliefs
}
