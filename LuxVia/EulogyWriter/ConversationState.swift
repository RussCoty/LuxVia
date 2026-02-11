import Foundation

/// Represents the current stage of the conversation
enum ConversationState: String, Codable {
    case greeting
    case collectingName
    case collectingRelationship
    case collectingCharacterValues
    case collectingImpact
    case collectingFunnyMemory
    case collectingCharacterMemory
    case collectingHobbies
    case collectingWhatYouWillMiss
    case collectingChallenges
    case collectingSmallDetails
    case collectingBeliefs
    case collectingFinalThoughts
    case readyForDraft
    case reviewingDraft
}

/// Types of questions that can be asked - used to track what has been asked
enum QuestionType: String, Hashable, CaseIterable {
    case name
    case relationship
    case characterValues
    case impact
    case funnyMemory
    case characterMemory
    case hobbies
    case whatYouWillMiss
    case challenges
    case smallDetails
    case beliefs
    case finalThoughts
}
