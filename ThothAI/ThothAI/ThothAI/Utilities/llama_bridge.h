//
//  llama_bridge.h
//  ThothAI
//
//  Created by Mike on 12/24/25.
//
//  C interface header for llama.cpp bridge
//  This header exposes the bridge functions to Swift via the bridging header

#ifndef llama_bridge_h
#define llama_bridge_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Run a smoke test to verify llama.cpp integration
/// @return true if the smoke test succeeds (model loads, decode works, logits retrieved), false otherwise
bool llama_smoke_test(void);

/// Generate text from a prompt (minimal test function)
/// @param prompt The input prompt text
/// @return Heap-allocated C string with generated text, or error message. Caller must free with free().
///         Returns NULL on critical errors.
const char * thothai_generate_test(const char * prompt);

/// Generate text from a dynamic prompt (raw completion mode)
/// @param prompt_utf8 UTF-8 encoded prompt string from Swift
/// @return true on success, false on failure
bool llama_generate_from_prompt(const char * prompt_utf8);

/// Generate text with token streaming (raw completion mode)
/// @param prompt_utf8 UTF-8 encoded prompt string from Swift
/// @param on_token Callback function called for each generated token (UTF-8 string)
/// @return true on success, false on failure
bool llama_generate_stream(const char * prompt_utf8, void (*on_token)(const char *));

#ifdef __cplusplus
}
#endif

#endif /* llama_bridge_h */

