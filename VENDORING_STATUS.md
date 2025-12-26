# llama.cpp Vendoring Status Summary

**Date**: 2024-12-25  
**Status**: In Progress - Fixed missing ARM-specific quantization implementations

## What We've Done

### 1. Vendored llama.cpp
- **Location**: `ThothAI/ThothAI/ThothAI/ThirdParty/llama/`
- **Source**: Cloned from `https://github.com/ggerganov/llama.cpp`
- **Files Copied**: ~77+ files including:
  - Core: `llama.h`, `llama.cpp`
  - GGML: All `ggml*.h`, `ggml*.c`, `ggml*.cpp` files
  - Model implementations: All `llama-*.cpp` and `llama-*.h` files from `src/`
  - Models directory: `models/models.h` and all `models/*.cpp` files
  - CPU implementation: `ggml-cpu.cpp`, `ggml-cpu.c`, and all CPU-related files
  - Unicode: `unicode.h`, `unicode.cpp`, `unicode-data.h`, `unicode-data.cpp`
  - Various subdirectories: `amx/`, `ggml-cpu/`, `models/`

### 2. Updated Bridge Files
- **`llama_bridge.mm`**: Changed include from `#import <llama/llama.h>` to `#include "llama.h"`
- **`llama_bridge.h`**: Added `#include <stdbool.h>` for C compatibility
- **`ThothAI-Bridging-Header.h`**: Fixed import path to `"llama_bridge.h"`

### 3. Updated Xcode Project
- **Header Search Path**: Added `"HEADER_SEARCH_PATHS[arch=*]" = "$(PROJECT_DIR)/ThothAI/ThirdParty/llama";`
- **Preprocessor Definitions**: 
  - `GGML_USE_ACCELERATE`
  - `GGML_VERSION="0.9.4"`
  - `GGML_COMMIT="vendored"`
- **C++ Standard**: Set to `c++17`
- **File System Sync**: Project uses `PBXFileSystemSynchronizedRootGroup` (auto-discovers files)

### 4. Fixed Include Paths
- Updated `amx/common.h`: Changed `"ggml-cpu-impl.h"` to `"ggml-cpu/ggml-cpu-impl.h"`
- Updated `common.h`: Changed `"ggml-cpu-impl.h"` to `"ggml-cpu/ggml-cpu-impl.h"`

### 5. Added ARM-Specific Implementations (2024-12-25)
- **Location**: `ThirdParty/llama/arch/arm/`
- **Files Added**:
  - `quants.c` - ARM-optimized quantization functions
  - `repack.cpp` - ARM-optimized matrix repacking functions
  - `cpu-feats.cpp` - ARM CPU feature detection
- **Fixed Include Paths**: Updated relative includes in ARM files to match new directory structure (`../../` to reach root)
- **Purpose**: Provides optimized implementations for iOS (ARM64) architecture, fixing undefined symbol errors for:
  - `ggml_gemm_*` functions (matrix multiplication)
  - `ggml_gemv_*` functions (matrix-vector multiplication)
  - `ggml_quantize_mat_*` functions (matrix quantization)
  - `ggml_vec_dot_*` functions (vector dot products)

### 6. Added Missing CPU Quants Wrapper File (2024-12-25)
- **Location**: `ThirdParty/llama/ggml-cpu/quants.c`
- **Purpose**: Provides wrapper functions that call `_ref` versions from `ggml-quants.c`
- **Functions Provided**: All `quantize_row_*` functions (q4_0, q4_1, q5_0, q5_1, q2_K, q3_K, q4_K, q5_K, q6_K, mxfp4, iq4_nl, iq4_xs, tq1_0, tq2_0)
- **Fixed Include Paths**: Updated `quants.h` include to `../quants.h` (file is in `ggml-cpu/` subdirectory)

## Current Directory Structure

```
ThirdParty/llama/
├── llama.h, llama.cpp
├── ggml*.h, ggml*.c, ggml*.cpp (all GGML files)
├── llama-*.cpp, llama-*.h (all llama source files)
├── unicode.h, unicode.cpp, unicode-data.h, unicode-data.cpp
├── gguf.h, gguf.cpp
├── common.h (from ggml-cpu/)
├── arch-fallback.h
├── simd-mappings.h
├── traits.h, quants.h, repack.h
├── unary-ops.h, binary-ops.h, vec.h, ops.h
├── ggml-common.h, ggml-threading.h, ggml-impl.h, ggml-backend-impl.h
├── ggml-cpu/
│   ├── ggml-cpu-impl.h
│   ├── common.h
│   └── quants.c - Wrapper functions for quantize_row_* (calls _ref versions)
├── amx/
│   ├── amx.h, amx.cpp, mmq.h, mmq.cpp
│   ├── common.h
│   ├── simd-mappings.h, quants.h, ggml-quants.h
│   └── (other amx files)
├── arch/
│   └── arm/
│       ├── quants.c - ARM-optimized quantization
│       ├── repack.cpp - ARM-optimized matrix repacking
│       └── cpu-feats.cpp - ARM CPU feature detection
└── models/
    ├── models.h
    └── *.cpp (101 model implementation files)
```

## Files That Were Copied (Key Missing Headers Fixed)

1. `gguf.h` - GGUF format header
2. `unicode.h`, `unicode.cpp`, `unicode-data.h`, `unicode-data.cpp` - Unicode support
3. `ggml-threading.h`, `ggml-impl.h`, `ggml-backend-impl.h` - Core GGML headers
4. `ggml-common.h`, `ggml-cpu-impl.h` - CPU implementation headers
5. `repack.h`, `traits.h`, `quants.h` - CPU operation headers
6. `unary-ops.h`, `binary-ops.h`, `vec.h`, `ops.h` - Operation headers
7. `arch-fallback.h`, `simd-mappings.h` - Architecture support
8. `common.h` (in both main dir and ggml-cpu/) - Common utilities
9. All `amx/` subdirectory files - AMX instruction support
10. All `models/` subdirectory files - Model implementations
11. `ggml-cpu.c` - CPU implementation (contains all the missing symbols)

## Current Build Status

### ✅ Completed
- llama.cpp vendored
- Bridge files updated
- Xcode project configured
- Header search paths set
- Preprocessor definitions added
- Most missing headers copied

### ⚠️ In Progress
- Fixed undefined symbol errors by adding ARM-specific implementations
- May still encounter missing header errors as we work through dependencies
- Pattern: Each new error reveals another missing header file
- Solution: Copy missing files from `/tmp/llama.cpp/` as errors appear

### 🔧 Build Configuration
- **C++ Standard**: `c++17`
- **Header Search Path**: `$(PROJECT_DIR)/ThothAI/ThirdParty/llama`
- **Framework Search Path**: `$(PROJECT_DIR)/ThothAI/ThirdParty/Frameworks` (for future use)
- **File Discovery**: Automatic via `PBXFileSystemSynchronizedRootGroup`

## Known Issues / Remaining Work

1. **ARM Files Compilation**: Verify that `arch/arm/*.c` and `arch/arm/*.cpp` files are being compiled by Xcode's auto-discovery
2. **CPU Quants File**: Verify that `ggml-cpu/quants.c` is being compiled (provides quantize_row_* wrappers)
2. **Missing Headers**: Continue copying missing header files as build errors reveal them
3. **Include Paths**: Some files may need include path adjustments for subdirectories
4. **C++ Standard Library**: Some headers use C++ standard library (like `<algorithm>`) - should work with C++17
5. **Warnings**: Integer precision warnings in `ggml-impl.h` (non-fatal)

## Next Steps for New Conversation

1. Continue fixing missing header errors as they appear
2. Pattern to follow:
   - Error: `'filename.h' file not found`
   - Find: `find /tmp/llama.cpp -name "filename.h"`
   - Copy: `cp /tmp/llama.cpp/path/to/filename.h ThirdParty/llama/`
   - Fix include paths if needed (check if file is in subdirectory)

3. Once all headers are in place, verify:
   - All `.c` and `.cpp` files compile
   - No undefined symbols remain
   - Smoke test runs successfully

## Key Files Reference

- **Bridge**: `Utilities/llama_bridge.mm`, `Utilities/llama_bridge.h`, `Utilities/ThothAI-Bridging-Header.h`
- **Project Config**: `ThothAI.xcodeproj/project.pbxproj`
- **Vendored Code**: `ThirdParty/llama/` (all llama.cpp files)
- **Smoke Test**: `llama_bridge.mm` contains `llama_smoke_test()` function

## Important Notes

- **Do NOT modify llama.cpp code** - this is a straight vendoring
- **Include paths** may need adjustment for subdirectories (e.g., `ggml-cpu/ggml-cpu-impl.h`)
- **File system sync** means Xcode auto-discovers files - no manual project file editing needed
- **Temporary clone** is at `/tmp/llama.cpp` - can be re-cloned if needed

## Current Error Pattern

The build is revealing missing headers one at a time. Each error follows this pattern:
1. Error: `'filename.h' file not found`
2. Find file in `/tmp/llama.cpp/`
3. Copy to appropriate location in `ThirdParty/llama/`
4. Fix include paths if file is in subdirectory
5. Rebuild to find next missing file

This is expected when vendoring a complex library - we're working through the dependency tree.

