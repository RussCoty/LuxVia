import Foundation

/// User preferences for eulogy writer AI features
class EulogySettings: ObservableObject {
    @Published var useAIResponses: Bool {
        didSet {
            UserDefaults.standard.set(useAIResponses, forKey: "eulogyUseAI")
        }
    }
    
    init() {
        // Default to false for now. In the future, this could be:
        // self.useAIResponses = UserDefaults.standard.bool(forKey: "eulogyUseAI")
        // However, bool(forKey:) returns false if the key doesn't exist, which is our desired default
        self.useAIResponses = UserDefaults.standard.bool(forKey: "eulogyUseAI")
    }
}
