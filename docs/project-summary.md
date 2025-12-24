# ThothAI iOS — Project Summary

**Last Updated**: 2024-12-24  
**Current Phase**: Phase 1c-A2 (GGUF inference integration)

## Project Overview

ThothAI iOS is a native iOS app for building local knowledge bases from PDFs and querying them using on-device AI. The app operates in two modes:
- **RAG Mode**: Document-grounded, stateless queries with citations
- **Chatbot Mode**: Conversational responses with optional memory

**Core Principles**:
- Offline-first: all processing on-device
- No user data leaves the device
- Models treated as data assets (not executable code)
- iOS sandbox compliance

## Source of Truth

- **Behavioral Specification**: `docs/behavioral-spec.md` — defines WHAT the app does
- **Task Plan**: `docs/task-plan.md` — defines HOW work is sequenced
- **Cursor Rules**: `.cursor/rules.md` — development guidelines

## Current Implementation Status

### ✅ Phase 0 — App Skeleton & Global State (COMPLETE)
- **AppCore**: Central state management with `AppState` (observable)
- **ModeController**: Enforces mode semantics (RAG → memory off, Chatbot → memory on)
- **StorageManager**: App-managed directories (KnowledgeBases, Models, Settings)
- **UI**: Minimal debug screen showing mode, memory policy, storage paths

### ✅ Phase 1a — ModelManager (COMPLETE)
- **ModelManager**: Manages model files as data assets
- **ModelMetadata**: Model descriptor (id, displayName, format, size, storageURL, source)
- **Features**:
  - Import GGUF/MLX models via Files app
  - Copy to app-managed storage
  - Track metadata (format, size)
  - Set active model (one at a time)
  - Delete inactive models
  - Persist model list across launches
- **UI**: Model list, import button, activate/delete actions

### ✅ Phase 1b — LLMRuntime Skeleton (COMPLETE)
- **LLMRuntime**: Stub implementation with placeholder responses
- **GenerationParameters**: Placeholder struct for future sampling params
- **GenerationResult**: Result with text, timing, token count
- **UI**: Prompt input, generate button, result display

### ✅ Phase 1c-A1 — GGUF Runtime Shell (COMPLETE)
- **GGUFModelHandle**: Validation helper (format, file existence, readability)
- **LLMRuntime**: Updated with GGUF validation path
- Returns deterministic "runtime shell ready" message when validation passes

### 🚧 Phase 1c-A2 — GGUF Inference Integration (IN PROGRESS)
- **llama.cpp**: Vendored in `ThirdParty/llama/` (master branch)
- **llama_bridge.mm**: Objective-C++ bridge to llama.cpp
  - `llama_load_model()`: Loads GGUF models
  - `llama_generate()`: Performs CPU-only inference
  - Uses sampler chain (temperature + distribution)
- **LLMRuntime**: Updated to call bridge functions
- **Status**: Code complete, needs Xcode project configuration

## Project Structure

```
ThothAI/ThothAI/ThothAI/
├── AppCore/
│   └── AppCore.swift              # Central app state management
├── Services/
│   ├── ModeController.swift       # Mode switching & memory policy
│   ├── StorageManager.swift       # File system management
│   ├── ModelManager.swift         # Model file management
│   └── LLMRuntime.swift           # LLM inference runtime
├── Models/
│   ├── AppState.swift             # Global application state
│   ├── GenerationParameters.swift # Generation config
│   └── GenerationResult.swift     # Generation output
├── ThirdParty/
│   └── llama/
│       ├── llama_bridge.h         # C interface
│       ├── llama_bridge.mm         # Objective-C++ implementation
│       ├── include/llama.h         # llama.cpp headers
│       └── src/                    # llama.cpp source (vendored)
├── ThothAI-Bridging-Header.h      # Swift/C interop
├── ContentView.swift               # Main UI (debug screen)
└── ThothAIApp.swift                # App entry point
```

## Key Design Decisions

### Model Management
- Models stored in app-managed storage (`ApplicationSupport/ThothAI/Models/`)
- One active model at a time
- Model compatibility determined by llama.cpp's ability to load
- Supported: LLaMA, Mistral, LLaMA2 architectures; Q4/Q5/Q8 quantization

### Mode Semantics
- **RAG Mode**: Always forces `memoryPolicy = .off`
- **Chatbot Mode**: Defaults to `memoryPolicy = .session`, can use `.persisted`
- Switching Chatbot → RAG immediately disables memory

### llama.cpp Integration
- **Version**: Master branch, pinned to stable commit
- **Configuration**: CPU-only (no Metal/GPU)
- **Target**: iOS Simulator (x86_64, arm64)
- **Model Size**: Tested with ≤1B parameters
- **Performance**: Slow CPU inference acceptable for Phase 1c-A2

## Technical Stack

- **Language**: Swift (SwiftUI)
- **Inference**: llama.cpp (C++, bridged via Objective-C++)
- **Storage**: FileManager (app-managed directories)
- **State Management**: Combine (ObservableObject, @Published)
- **Concurrency**: Swift async/await

## Pending Tasks

### Immediate (Phase 1c-A2)
1. **Xcode Configuration**:
   - Add llama.cpp source files to project
   - Configure bridging header path
   - Add compiler flags (`-DGGML_USE_CPU_ONLY`, `-DGGML_USE_ACCELERATE`)
   - Link Accelerate.framework
   - Set C++ language standard

2. **Testing**:
   - Build verification
   - Test with small GGUF model (≤1B params)
   - Verify generation works end-to-end

### Next Phases
- **Phase 1c**: ProfileManager (model-specific generation configs)
- **Phase 2**: Knowledge Bases & PDFs
- **Phase 3**: Ingestion & Retrieval (RAG core)
- **Phase 4**: Query Orchestration & Mode Semantics

## Important Files Reference

### Documentation
- `docs/behavioral-spec.md` — Behavioral specification (source of truth)
- `docs/task-plan.md` — Implementation phases and sequencing
- `.cursor/rules.md` — Development guidelines and constraints

### Core Implementation
- `AppCore/AppCore.swift` — Central state, owns ModelManager, ModeController, LLMRuntime
- `Models/AppState.swift` — Observable state (activeModelId, activeMode, memoryPolicy, etc.)
- `Services/LLMRuntime.swift` — Inference runtime, calls llama.cpp bridge
- `Services/ModelManager.swift` — Model file management and persistence

### Bridge Layer
- `ThirdParty/llama/llama_bridge.h` — C interface for Swift
- `ThirdParty/llama/llama_bridge.mm` — Objective-C++ implementation
- `ThothAI-Bridging-Header.h` — Swift bridging header

## Error Handling Philosophy

All errors must be:
- **User-visible**: Shown in UI, not logged silently
- **Non-destructive**: Never crash the app
- **Actionable**: Provide clear guidance on what to do

Examples:
- "No active model selected. Please import and activate a model first."
- "Model file missing: [path]. The file may have been moved or deleted."
- "Failed to load GGUF model. Model may be incompatible or corrupted."

## Constraints & Limitations

### Phase 1c-A2 Scope
- ✅ CPU-only inference (no Metal/GPU)
- ✅ One-shot generation (no streaming)
- ✅ Synchronous generation (blocking UI acceptable)
- ✅ Fixed generation config (temperature=0.7, max_tokens=128)
- ❌ No chat memory
- ❌ No RAG logic
- ❌ No PDF processing
- ❌ No Hugging Face downloads

### Model Compatibility
- Supported architectures: llama.cpp-compatible (LLaMA, Mistral, LLaMA2, etc.)
- Supported quantizations: Q4, Q5, Q8
- Compatibility determined by llama.cpp's ability to load (no additional validation)

### Performance Expectations
- CPU-only inference is slow (acceptable for Phase 1c-A2)
- Large models may require significant RAM on simulator
- Graceful failure on memory pressure is sufficient

## Quick Start for New Conversation

When starting a new conversation, provide:
1. This summary file
2. Current task/phase you're working on
3. Any specific files you're modifying

Key questions to ask if unclear:
- "What does the behavioral spec say about [feature]?"
- "What phase are we in for [component]?"
- "What are the constraints for [feature]?"

## Build Configuration Notes

### Required Xcode Settings
- **Bridging Header**: `ThothAI/ThothAI-Bridging-Header.h`
- **C++ Language**: C++17 or C++20
- **Compiler Flags**: `-DGGML_USE_CPU_ONLY`, `-DGGML_USE_ACCELERATE`
- **Frameworks**: Accelerate.framework
- **Header Search Paths**: `ThirdParty/llama/include` (recursive)

### llama.cpp Integration
- Source vendored in `ThirdParty/llama/`
- Bridge implementation in `llama_bridge.mm` (Objective-C++)
- C interface exposed via `llama_bridge.h`
- Swift access via bridging header

## Known Issues / TODOs

1. **llama.cpp Integration**: Bridge code complete, needs Xcode project configuration
2. **Token Counting**: GenerationResult.tokensGenerated is placeholder (returns 0)
3. **Model Caching**: Model loaded on first generation, not pre-loaded
4. **Error Messages**: Some C++ exceptions may need better Swift error translation

## Development Workflow

1. **Read First**: behavioral-spec.md (what), task-plan.md (how), .cursor/rules.md (guidelines)
2. **Check Phase**: Verify current phase scope before implementing
3. **Follow Constraints**: Don't add features not in spec
4. **Error Handling**: All errors must be user-visible and actionable
5. **Testing**: Use small models (≤1B params) for Phase 1c-A2

---

**Note**: This summary is a snapshot. Always refer to `docs/behavioral-spec.md` as the source of truth for WHAT the app should do, and `docs/task-plan.md` for implementation sequencing.

