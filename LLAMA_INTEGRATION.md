# Llama 3.2 3B Integration for Eulogy Writer

## Overview

This document describes the infrastructure added to support Llama 3.2 3B integration for the eulogy writer feature. The integration provides natural, empathetic AI-generated responses instead of pre-written templates while maintaining 100% local/private operation.

## Current Implementation (Phase 1)

**Status:** Infrastructure Complete ✅  
**Actual LLM Integration:** Placeholder (Phase 2)

### What's Included

#### 1. LlamaEngine.swift
Defines the protocol and implementations for LLM engines:

- **`LLMEngine` Protocol**: Interface for text generation
  - `generate(prompt: String, maxTokens: Int) async throws -> String`
  
- **`LlamaEngine` Class**: Placeholder for llama.cpp integration
  - Currently returns placeholder text
  - Ready for Phase 2 implementation
  
- **`TemplateEngine` Class**: Fallback to existing template system
  - Throws error to signal template fallback

#### 2. LlamaPromptBuilder.swift
Builds context-aware prompts for the LLM:

```swift
static func buildPrompt(
    state: ConversationState,
    form: EulogyForm,
    lastUserMessage: String? = nil
) -> String
```

**Features:**
- Includes all collected information (name, relationship, traits, hobbies, stories)
- Acknowledges user's last message
- Provides state-specific instructions
- Enforces empathetic, concise responses (1-2 sentences)

**Example Prompt Structure:**
```
You are a compassionate assistant helping someone create a eulogy...

IMPORTANT RULES:
- Be warm, empathetic, and respectful
- Keep responses to 1-2 sentences maximum
- Ask only ONE question at a time
- Acknowledge what the user just shared
- Use the person's name when known

Deceased person's name: John Smith
Relationship to user: father
Personality traits shared: kind, patient, generous
Hobbies/passions shared: gardening, woodworking

User's last message: "He taught me to build furniture"

Ask what they loved to do or what brought them joy. Reference any context already shared.

Your response (1-2 sentences):
```

#### 3. EulogySettings.swift
User preference management:

```swift
class EulogySettings: ObservableObject {
    @Published var useAIResponses: Bool
}
```

- Persisted to `UserDefaults` with key `"eulogyUseAI"`
- Default: `false` (uses template system)
- Ready for UI toggle implementation

#### 4. EulogyChatEngine.swift (Modified)
Core integration changes:

**New Properties:**
- `llmEngine: LLMEngine` - The LLM engine (Llama or Template)
- `lastUserMessage: String?` - Tracks user's last input for context

**Modified Methods:**
- `init(useLLM: Bool = false)` - Initializes appropriate engine
- `send(_ text: String)` - Stores last message for context
- `askNextQuestion()` - Tries LLM first, falls back to templates

**Flow:**
```
1. Try LLM-generated response
   ↓
2. If successful → Use AI response, mark as .aiGenerated
   ↓
3. If fails → Fall back to templates, mark as .preWritten
```

#### 5. EulogyWriterView.swift (Modified)
View layer integration:

- Creates `EulogySettings` instance
- Currently defaults to `useLLM: false` (templates)
- Settings infrastructure ready for UI toggle

## Architecture

```
┌─────────────────────┐
│ EulogyWriterView    │
│ - settings          │
│ - engine            │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ EulogyChatEngine    │
│ - llmEngine         │
│ - lastUserMessage   │
└──────────┬──────────┘
           │
           ↓
    ┌──────┴──────┐
    ↓             ↓
┌─────────┐  ┌──────────────┐
│ Llama   │  │  Template    │
│ Engine  │  │  Engine      │
└─────────┘  └──────────────┘
     ↑              ↑
     │              │
  Phase 2      Current
  (Future)     Fallback
```

## Message Source Tracking

All messages now include a source:

```swift
enum MessageSource {
    case user          // User's message
    case aiGenerated   // LLM-generated response
    case preWritten    // Template response
    case draft         // Eulogy draft
}
```

**UI Implications:**
- Can display different colors/indicators
- Can track which responses are AI vs template
- Enables A/B testing

## Current Behavior

**Default (useLLM = false):**
1. User sends message
2. Engine tries LLM → TemplateEngine throws error
3. Falls back to template system (existing behavior)
4. Message marked as `.preWritten`

**No Changes:**
- All existing functionality preserved
- Same questions asked
- Same template responses
- Same conversation flow

## Future Enhancement (Phase 2)

### Llama.cpp Integration

**Requirements:**
1. Add llama.cpp Swift bindings
   - Via Swift Package Manager or build from source
   - https://github.com/ggerganov/llama.cpp

2. Model Download/Bundling
   - Llama 3.2 3B Instruct (quantized ~2GB)
   - Q4_K_M quantization recommended
   - Store in app bundle or download on first run

3. LlamaEngine Implementation
```swift
class LlamaEngine: LLMEngine {
    private var context: LlamaContext?
    private let modelPath: String
    
    init(modelPath: String) {
        self.modelPath = modelPath
        // Initialize llama.cpp context
    }
    
    func generate(prompt: String, maxTokens: Int) async throws -> String {
        // Use llama.cpp to generate response
        // Return actual AI-generated text
    }
}
```

### UI Toggle

Add settings screen with toggle:
```swift
struct EulogySettingsView: View {
    @ObservedObject var settings: EulogySettings
    
    var body: some View {
        Toggle("Enable AI Responses", isOn: $settings.useAIResponses)
            .onChange(of: settings.useAIResponses) { newValue in
                // May require app restart or engine recreation
            }
    }
}
```

### Performance Expectations

- First token latency: 1-2 seconds
- Generation time: 2-4 seconds for response
- Memory usage: ~2.5GB (model + context)
- Requires: iPhone 12+ or equivalent (Apple Silicon recommended)

## Testing

### Manual Testing Checklist

1. **Template Mode (Current)**
   - [ ] Conversation starts normally
   - [ ] Questions use templates
   - [ ] All messages marked `.preWritten`
   - [ ] Draft generation works

2. **Infrastructure Verification**
   - [x] LlamaEngine protocol defined
   - [x] Placeholder implementation present
   - [x] TemplateEngine fallback works
   - [x] Prompt builder creates valid prompts
   - [x] Settings persist to UserDefaults
   - [x] Message source tracked correctly

3. **Future LLM Mode**
   - [ ] Toggle setting to enable AI
   - [ ] Llama.cpp generates responses
   - [ ] Responses acknowledge user input
   - [ ] Responses include name/context
   - [ ] Fallback to templates on error
   - [ ] Messages marked `.aiGenerated`

### Unit Tests

Created `test_llama_integration.swift` to document:
- Protocol structure
- Prompt builder logic
- Settings management
- Engine integration
- Backward compatibility

## Privacy & Security

**100% Local Operation:**
- No data sent to cloud servers
- All inference on-device
- Private by design
- HIPAA/GDPR compatible

**Model Security:**
- Model checksum verification (Phase 2)
- Sandboxed execution
- No network access required

## Success Criteria

### Phase 1 (Current) ✅
- [x] Infrastructure in place
- [x] Protocol-based design
- [x] Context-aware prompt builder
- [x] Settings management
- [x] Fallback system
- [x] Message source tracking
- [x] No breaking changes
- [x] Backward compatible

### Phase 2 (Future)
- [ ] Llama.cpp integration
- [ ] Model bundling/download
- [ ] UI toggle implemented
- [ ] Performance optimization
- [ ] Error handling
- [ ] User feedback
- [ ] A/B testing framework

## Migration Path

**From Template to AI:**
1. User enables AI in settings
2. App downloads model (if needed)
3. Initializes LlamaEngine
4. New conversations use AI
5. Can toggle back to templates anytime

**No Breaking Changes:**
- Existing conversations unaffected
- Template mode always available
- Graceful degradation
- User controls experience

## References

- **Llama 3.2 3B:** https://huggingface.co/meta-llama/Llama-3.2-3B
- **llama.cpp:** https://github.com/ggerganov/llama.cpp
- **Swift Bindings:** TBD (Phase 2)
- **Model Quantization:** https://github.com/ggerganov/llama.cpp#quantization

## Support

For questions or issues:
1. Check Phase 1 implementation in this PR
2. Review prompt builder logic in `LlamaPromptBuilder.swift`
3. Test with template mode first
4. Report issues via GitHub

---

**Last Updated:** 2026-02-11  
**Status:** Phase 1 Complete, Phase 2 Pending
