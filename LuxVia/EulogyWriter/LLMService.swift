import Foundation

// LLMMessage struct is kept for potential future LLM integration
// Currently not used, but retained for backward compatibility
struct LLMMessage: Codable {
    let role: String
    let content: String
}
