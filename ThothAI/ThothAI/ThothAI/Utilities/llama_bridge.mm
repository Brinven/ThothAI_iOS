//
//  llama_bridge.mm
//  ThothAI
//
//  Created by Mike on 12/24/25.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#include "llama.h"
#import <iostream>
#import <vector>

extern "C" bool llama_smoke_test(void) {
    // Get Documents directory path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDir = [paths firstObject];
    NSString* modelPath = [documentsDir stringByAppendingPathComponent:@"LFM2-350M-Q4_K_M.gguf"];
    
    // Log the resolved model path
    NSLog(@"llama_smoke_test: Loading model from %@", modelPath);
    
    const char* model_path_cstr = [modelPath UTF8String];
    
    // Initialize backend
    llama_backend_init();
    
#if TARGET_OS_SIMULATOR
    NSLog(@"llama_smoke_test: Simulator detected — CPU-only mode");
#endif
    
    // Load model
    struct llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;  // Force CPU-only execution
    llama_model* model = llama_model_load_from_file(model_path_cstr, model_params);
    
    if (!model) {
        NSLog(@"llama_smoke_test: Failed to load model");
        llama_backend_free();
        return false;
    }
    
    // Initialize context
    struct llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 512;
    ctx_params.n_threads = 4;
    ctx_params.n_threads_batch = 4;
    
    llama_context* ctx = llama_init_from_model(model, ctx_params);
    
    if (!ctx) {
        NSLog(@"llama_smoke_test: Failed to create context");
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    // Minimal smoke test: single decode step with BOS token
    const llama_vocab* vocab = llama_model_get_vocab(model);
    llama_token bos_token = llama_vocab_bos(vocab);
    
    // Create and populate batch
    llama_batch batch = llama_batch_init(1, 0, 1);
    batch.n_tokens = 1;
    batch.token[0] = bos_token;
    batch.pos[0] = 0;
    batch.seq_id[0][0] = 0;
    batch.n_seq_id[0] = 1;
    batch.logits[0] = true;
    
    // Decode
    int decode_result = llama_decode(ctx, batch);
    
    if (decode_result != 0) {
        NSLog(@"llama_smoke_test: llama_decode() failed with code %d", decode_result);
        llama_batch_free(batch);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    // Retrieve logits (only if decode succeeded)
    float* logits = llama_get_logits(ctx);
    if (!logits) {
        NSLog(@"llama_smoke_test: Decode succeeded but logits are NULL");
        llama_batch_free(batch);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    NSLog(@"llama_smoke_test: Successfully decoded token and retrieved logits");
    
    // Cleanup batch
    llama_batch_free(batch);
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    
    NSLog(@"llama_smoke_test: Completed successfully");
    return true;
}
