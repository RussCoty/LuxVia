import Foundation

enum LlamaError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(String)
    case contextNotInitialized
    case inferenceNotImplemented
    case inferenceFailed(String)
    case insufficientMemory
    case unsupportedDevice
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model file not found. Please download llama-3.2-3b-instruct-Q4_K_M.gguf to Resources/Models/"
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .contextNotInitialized:
            return "Llama context not initialized"
        case .inferenceNotImplemented:
            return "Llama inference not yet implemented - falling back to templates"
        case .inferenceFailed(let reason):
            return "Inference failed: \(reason)"
        case .insufficientMemory:
            return "Insufficient memory for model inference"
        case .unsupportedDevice:
            return "Device not supported for on-device AI (requires A14 chip or newer)"
        }
    }
}
