# Model Files

This directory should contain the Llama model file for AI-powered responses.

## Download Instructions

1. Download the quantized Llama 3.2 3B model:
   - File: `llama-3.2-3b-instruct-Q4_K_M.gguf`
   - Size: ~2.0 GB
   - URL: https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/blob/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf

2. Place the downloaded file in this directory:
   ```
   LuxVia/Resources/Models/llama-3.2-3b-instruct-Q4_K_M.gguf
   ```

3. In Xcode, drag the file into the project:
   - ✅ Check "Copy items if needed"
   - ✅ Add to LuxVia target
   - ✅ Verify it appears in Build Phases → Copy Bundle Resources
   - ❌ Do NOT add to Compile Sources

## Important Notes

- This file is excluded from Git via `.gitignore` due to its 2GB size
- Each developer must download it separately
- App will fall back to template responses if model is not found
- Minimum device: iPhone 12 (A14 chip) recommended
- Requires ~4GB free RAM during inference

## Alternative Models

You can use different quantization levels:
- `Q4_K_S.gguf` - 1.8 GB (smaller, slightly lower quality)
- `Q4_K_M.gguf` - 2.0 GB (recommended balance)
- `Q5_K_M.gguf` - 2.3 GB (better quality)
- `Q8_0.gguf` - 3.4 GB (highest quality, slower)
