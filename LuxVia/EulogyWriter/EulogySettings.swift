import Foundation

/// User preferences for eulogy writer AI features
class EulogySettings: ObservableObject {
    static let shared = EulogySettings()
    
    @Published var useAIResponses: Bool {
        didSet {
            UserDefaults.standard.set(useAIResponses, forKey: "eulogyUseAI")
        }
    }
    
    private init() {
        self.useAIResponses = UserDefaults.standard.bool(forKey: "eulogyUseAI")
    }
}
