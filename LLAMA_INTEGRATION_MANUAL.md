# Manual Integration Guide: llama.cpp for iOS

This guide explains how to manually integrate llama.cpp into the LuxVia project for Phase 2 completion.

## Overview

The LuxVia project now has all the Swift infrastructure for llama.cpp integration. However, the actual C library integration requires manual steps that cannot be automated via Git.

## Prerequisites

- Xcode 15+
- CMake (install via `brew install cmake`)
- Git
- macOS development machine
- iOS device with A14 chip or newer (iPhone 12+) for testing

## Option A: Swift Package Manager (Recommended if Available)

If llama.cpp provides SPM support:

1. In Xcode, go to **File → Add Packages...**
2. Enter the llama.cpp repository URL
3. Select the appropriate version/branch
4. Add to the LuxVia target

**Note:** As of early 2024, llama.cpp may not have official SPM support. Check the repository for updates.

## Option B: Build llama.cpp as XCFramework

### Step 1: Clone llama.cpp

```bash
cd ~/Developer
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
```

### Step 2: Build for iOS Simulator (arm64)

```bash
cmake -B build-ios-sim \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DLLAMA_METAL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF

cmake --build build-ios-sim --config Release
```

### Step 3: Build for iOS Device (arm64)

```bash
cmake -B build-ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DLLAMA_METAL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=OFF

cmake --build build-ios --config Release
```

### Step 4: Create XCFramework

```bash
xcodebuild -create-xcframework \
  -library build-ios/libllama.a \
  -headers . \
  -library build-ios-sim/libllama.a \
  -headers . \
  -output llama.xcframework
```

### Step 5: Add to Xcode Project

1. Drag `llama.xcframework` into the Xcode project navigator
2. Ensure it's added to the LuxVia target
3. In **Build Settings → Framework Search Paths**, verify the path is included
4. In **Build Settings → Header Search Paths**, add the path to llama.cpp headers

## Option C: Use the Official iOS Example

The llama.cpp repository includes an iOS example that demonstrates integration:

```bash
cd ~/Developer/llama.cpp/examples/ios
open llama.cpp.swift.xcodeproj
```

Study the example project to understand:
- How headers are bridged
- How the Metal backend is configured
- How inference is performed

You can copy the relevant parts into LuxVia.

## Configuring Xcode Build Settings

Once you have the library integrated, configure these settings:

### 1. Bridging Header

In **Build Settings → Swift Compiler - General → Objective-C Bridging Header**, set:
```
LuxVia/EulogyWriter/LLM/LlamaBridge.h
```

### 2. Update LlamaBridge.h

Add the actual llama.cpp headers:

```objective-c
#ifndef LlamaBridge_h
#define LlamaBridge_h

#include "llama.h"
#include "common.h"

#endif /* LlamaBridge_h */
```

### 3. Link Frameworks

Ensure these frameworks are linked:
- **Metal.framework** (for GPU acceleration)
- **Accelerate.framework** (for CPU optimization)
- **Foundation.framework**

### 4. Other Linker Flags

Add these if needed:
```
-lstdc++
```

### 5. Enable Metal

In **Build Settings → Metal Compiler → Enable Metal**, set to **Yes**.

## Implementing LlamaContext.swift

Update the TODO sections in `LuxVia/EulogyWriter/LLM/LlamaContext.swift`:

```swift
import Foundation

class LlamaContext {
    private var modelPath: String
    private var context: OpaquePointer?
    private var model: OpaquePointer?
    
    init(modelPath: String) throws {
        self.modelPath = modelPath
        try loadModel()
    }
    
    private func loadModel() throws {
        // Initialize llama.cpp backend
        llama_backend_init()
        
        // Set up model parameters
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 99 // Use Metal for all layers
        
        // Load the model
        guard let loadedModel = llama_load_model_from_file(modelPath, modelParams) else {
            throw LlamaError.modelLoadFailed("Failed to load model from \(modelPath)")
        }
        self.model = loadedModel
        
        // Create context
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = 2048  // Context size
        ctxParams.n_batch = 512
        ctxParams.n_threads = 4
        
        guard let ctx = llama_new_context_with_model(loadedModel, ctxParams) else {
            throw LlamaError.modelLoadFailed("Failed to create context")
        }
        self.context = ctx
    }
    
    func complete(prompt: String, maxTokens: Int = 150) throws -> String {
        guard let ctx = context, let mdl = model else {
            throw LlamaError.contextNotInitialized
        }
        
        // Tokenize prompt
        let tokens = tokenize(prompt: prompt, model: mdl)
        
        // Run inference
        var result = ""
        var nCur = tokens.count
        let nMax = nCur + maxTokens
        
        // Evaluate prompt tokens
        if llama_decode(ctx, llama_batch_get_one(&tokens, Int32(tokens.count), 0, 0)) != 0 {
            throw LlamaError.inferenceFailed("Failed to decode prompt")
        }
        
        // Generate tokens
        while nCur < nMax {
            // Sample next token
            let newTokenId = sampleNextToken(context: ctx, model: mdl)
            
            // Check for end of generation
            if newTokenId == llama_token_eos(mdl) {
                break
            }
            
            // Convert token to text
            let tokenText = tokenToString(token: newTokenId, model: mdl)
            result += tokenText
            
            // Prepare for next iteration
            var batch = llama_batch_get_one(&[newTokenId], 1, Int32(nCur), 0)
            if llama_decode(ctx, batch) != 0 {
                throw LlamaError.inferenceFailed("Failed to decode token")
            }
            
            nCur += 1
        }
        
        return result
    }
    
    private func tokenize(prompt: String, model: OpaquePointer) -> [llama_token] {
        let utf8Count = prompt.utf8.count
        var tokens = [llama_token](repeating: 0, count: utf8Count + 1)
        let nTokens = llama_tokenize(model, prompt, Int32(utf8Count), &tokens, Int32(tokens.count), true, false)
        tokens.removeLast(tokens.count - Int(nTokens))
        return tokens
    }
    
    private func sampleNextToken(context: OpaquePointer, model: OpaquePointer) -> llama_token {
        let logits = llama_get_logits_ith(context, -1)
        let nVocab = llama_n_vocab(model)
        
        // Simple greedy sampling (can be improved with temperature, top-p, etc.)
        var maxLogit: Float = -Float.infinity
        var bestToken: llama_token = 0
        
        for i in 0..<nVocab {
            let logit = logits[Int(i)]
            if logit > maxLogit {
                maxLogit = logit
                bestToken = llama_token(i)
            }
        }
        
        return bestToken
    }
    
    private func tokenToString(token: llama_token, model: OpaquePointer) -> String {
        var buffer = [CChar](repeating: 0, count: 32)
        llama_token_to_piece(model, token, &buffer, Int32(buffer.count), false)
        return String(cString: buffer)
    }
    
    deinit {
        if let ctx = context {
            llama_free(ctx)
        }
        if let mdl = model {
            llama_free_model(mdl)
        }
        llama_backend_free()
    }
}
```

## Testing

### 1. Download Model

Follow the instructions in `LuxVia/Resources/Models/README.md`:
- Download `llama-3.2-3b-instruct-Q4_K_M.gguf` (~2GB)
- Place in `LuxVia/Resources/Models/`
- Add to Xcode project (Copy Bundle Resources)

### 2. Build and Run

1. Build the project in Xcode
2. Run on a physical iOS device (not simulator for best performance)
3. Check the console for model loading messages

### 3. Enable AI Responses

Currently, the app defaults to template mode. To test AI:
1. Enable the AI toggle in settings (UI to be added)
2. Or temporarily modify `EulogyWriterView.swift` to pass `useLLM: true`

### 4. Expected Behavior

**Without Model:**
- Console: "⚠️ LlamaEngine initialization failed: Model file not found..."
- App: Falls back to template responses gracefully

**With Model:**
- Console: "📦 Found model at: ..."
- Console: "✅ LlamaEngine initialized successfully"
- App: Generates AI responses (marked as `.aiGenerated`)

## Performance Tuning

### Metal Optimization
- Ensure all layers use Metal: `n_gpu_layers = 99`
- Use Metal Performance Shaders for matrix operations

### Memory Management
- Monitor memory usage with Instruments
- Use smaller quantization if needed (Q4_K_S instead of Q4_K_M)
- Reduce context size if memory constrained

### Token Generation
- Implement temperature sampling for more varied responses
- Add top-p (nucleus) sampling for quality
- Use repetition penalty to avoid loops

### Caching
- Cache the model in memory after first load
- Consider pre-loading on app launch
- Use batch processing for multiple requests

## Performance Targets

- **First token latency:** 1-2 seconds
- **Token generation rate:** 10-30 tokens/second on iPhone 14+
- **Memory usage:** <2.5GB during inference
- **Response time:** 2-4 seconds for typical response

## Troubleshooting

### "Model not found"
- Verify file is in `Resources/Models/`
- Check it's added to Copy Bundle Resources in Build Phases
- Ensure file name matches exactly: `llama-3.2-3b-instruct-Q4_K_M.gguf`

### "Failed to load model"
- File might be corrupted - re-download
- Check file permissions
- Verify it's a valid GGUF file

### Build errors
- Ensure bridging header path is correct
- Verify llama.cpp headers are accessible
- Check that Metal framework is linked

### Slow inference
- Enable Metal: `n_gpu_layers = 99`
- Reduce context size: `n_ctx = 1024`
- Use lighter quantization: Q4_K_S

### App crashes
- Insufficient memory - close other apps
- Device too old - requires iPhone 12+ (A14 chip)
- Check crash logs for stack trace

## Alternative Approaches

### 1. Pre-compiled Binary
Some community members may provide pre-compiled xcframeworks. Search for:
- "llama.cpp iOS xcframework"
- "llama.cpp Swift package"

### 2. Rust Bindings
Projects like `llama-cpp-rs` provide Rust bindings that can be called from Swift.

### 3. Cloud API (Not Recommended)
If on-device proves too difficult, consider cloud APIs, but this violates the privacy requirement.

## Resources

- **llama.cpp GitHub:** https://github.com/ggerganov/llama.cpp
- **iOS Example:** https://github.com/ggerganov/llama.cpp/tree/master/examples/ios
- **GGUF Models:** https://huggingface.co/models?library=gguf
- **Metal Documentation:** https://developer.apple.com/metal/

## Support

If you encounter issues:
1. Check the llama.cpp GitHub issues
2. Review the iOS example project
3. Ask in the LuxVia GitHub discussions
4. The Swift infrastructure is ready - issues are likely in the C library integration

---

**Last Updated:** 2026-02-11  
**Author:** LuxVia Development Team
