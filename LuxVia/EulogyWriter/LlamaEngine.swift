import Foundation

protocol LLMEngine {
    func generate(prompt: String, maxTokens: Int) async throws -> String
}

class LlamaEngine: LLMEngine {
    private var context: LlamaContext?
    private let modelName = "llama-3.2-3b-instruct-Q4_K_M"
    
    init() {
        do {
            try loadModel()
        } catch {
            print("⚠️ LlamaEngine initialization failed: \(error.localizedDescription)")
            print("   App will fall back to template responses")
        }
    }
    
    private func loadModel() throws {
        // Try to find bundled model
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "gguf") else {
            throw LlamaError.modelNotFound
        }
        
        // Verify file exists and is readable
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw LlamaError.modelNotFound
        }
        
        print("📦 Found model at: \(modelPath)")
        
        // Initialize llama context
        context = try LlamaContext(modelPath: modelPath)
        
        print("✅ LlamaEngine initialized successfully")
    }
    
    func generate(prompt: String, maxTokens: Int = 150) async throws -> String {
        guard let ctx = context else {
            throw LlamaError.contextNotInitialized
        }
        
        // Run inference on background thread
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let result = try ctx.complete(prompt: prompt, maxTokens: maxTokens)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

/// Fallback engine that throws to signal template use
class TemplateEngine: LLMEngine {
    func generate(prompt: String, maxTokens: Int) async throws -> String {
        // Always throw to signal fallback to templates
        throw LlamaError.inferenceNotImplemented
    }
}
