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

#ifdef __cplusplus
}
#endif

#endif /* llama_bridge_h */

