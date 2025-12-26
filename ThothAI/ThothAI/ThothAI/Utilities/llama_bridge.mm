//
//  llama_bridge.mm
//  ThothAI
//
//  Created by Mike on 12/24/25.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#include "llama.h"
#include "ggml-cpu.h"  // For ggml_backend_cpu_reg()
#import <iostream>
#import <vector>
#import <string>
#include <cstring>  // for strdup

extern "C" bool llama_smoke_test(void) {
    // Get Documents directory path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDir = [paths firstObject];
    NSString* modelPath = [documentsDir stringByAppendingPathComponent:@"qwen2.5-0.5b-q4_k_m.gguf"];
    
    const char* model_path_cstr = [modelPath UTF8String];
    
    // Log the resolved model path
    NSLog(@"Loading model: %s", model_path_cstr);
    
    // Check if model file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:modelPath]) {
        NSLog(@"ERROR: Model file not found at: %s", model_path_cstr);
        NSLog(@"Documents directory: %@", documentsDir);
        
        // List all files in Documents directory for debugging
        NSError* error = nil;
        NSArray* files = [fileManager contentsOfDirectoryAtPath:documentsDir error:&error];
        if (error) {
            NSLog(@"Error listing Documents directory: %@", error);
        } else {
            NSLog(@"Files in Documents directory (%lu):", (unsigned long)[files count]);
            for (NSString* file in files) {
                NSLog(@"  - %@", file);
            }
        }
        
        NSLog(@"Please ensure qwen2.5-0.5b-q4_k_m.gguf is in the app's Documents directory");
        return false;
    }
    
    // Initialize backend
    llama_backend_init();
    // Register CPU backend statically (required on iOS where backends are statically linked)
    ggml_backend_register(ggml_backend_cpu_reg());
    
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
    
    // Raw completion test: no chat templates, direct text continuation
    const llama_vocab* vocab = llama_model_get_vocab(model);
    llama_token eos_token = llama_vocab_eos(vocab);
    
    // Raw completion prompt (no role prefixes, no instructions)
    const char* prompt = "The dog wagged its tail and";
    
    NSLog(@"llama_smoke_test: Raw completion prompt: '%s'", prompt);
    
    // Tokenize as raw string without special tokens (add_special=false for raw completion)
    // This ensures no BOS/EOS or chat template formatting
    const int max_tokens = 512;
    std::vector<llama_token> tokens(max_tokens);
    int n_tokens = llama_tokenize(vocab, prompt, (int)strlen(prompt), tokens.data(), max_tokens, false, false);
    
    if (n_tokens < 0) {
        // Buffer too small, try with actual size needed
        n_tokens = -n_tokens;
        tokens.resize(n_tokens);
        n_tokens = llama_tokenize(vocab, prompt, (int)strlen(prompt), tokens.data(), n_tokens, false, false);
    }
    
    if (n_tokens <= 0) {
        NSLog(@"llama_smoke_test: Failed to tokenize prompt");
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    tokens.resize(n_tokens);
    
    NSLog(@"llama_smoke_test: Tokenized %d tokens (raw mode, no special tokens)", n_tokens);
    
    // Decode prompt tokens
    llama_batch batch = llama_batch_init(512, 0, 1);
    batch.n_tokens = n_tokens;
    
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.seq_id[i][0] = 0;
        batch.n_seq_id[i] = 1;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;  // Enable logits only for last token
    }
    
    if (llama_decode(ctx, batch) != 0) {
        NSLog(@"llama_smoke_test: Failed to decode prompt");
        llama_batch_free(batch);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    llama_batch_free(batch);
    
    // Create sampler with fixed parameters
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler* smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    
    // Generation parameters
    const int max_gen = 16;  // Maximum 16 tokens
    const int min_tokens_before_period = 3;  // Need at least 3 tokens before checking for period
    
    // Generate tokens
    std::vector<llama_token> generated_tokens;
    generated_tokens.reserve(max_gen);
    std::string generated_text;  // Track text as we generate to detect periods
    char buf[256];
    
    for (int i = 0; i < max_gen; i++) {
        // Sample token
        llama_token new_token = llama_sampler_sample(smpl, ctx, -1);
        
        // Check for EOS
        if (new_token == eos_token) {
            break;
        }
        
        generated_tokens.push_back(new_token);
        
        // Convert token to text piece to check for period
        int len = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, false);
        if (len > 0 && len < (int)sizeof(buf)) {
            buf[len] = '\0';
            generated_text += buf;
            
            // Check for period after at least min_tokens_before_period tokens
            // Check if the current token piece contains a period
            if (i >= min_tokens_before_period - 1) {
                if (strchr(buf, '.') != nullptr) {
                    // Found a period in the current token, stop generation
                    break;
                }
            }
        }
        
        // Decode the new token
        batch = llama_batch_init(1, 0, 1);
        batch.n_tokens = 1;
        batch.token[0] = new_token;
        batch.pos[0] = n_tokens + i;
        batch.seq_id[0][0] = 0;
        batch.n_seq_id[0] = 1;
        batch.logits[0] = true;  // Enable logits for sampling
        
        if (llama_decode(ctx, batch) != 0) {
            NSLog(@"llama_smoke_test: Failed to decode generated token");
            llama_batch_free(batch);
            break;
        }
        
        llama_batch_free(batch);
    }
    
    llama_sampler_free(smpl);
    
    // Print output with specified markers
    NSLog(@"=== LLM TEST OUTPUT ===");
    NSLog(@"%s", generated_text.c_str());
    NSLog(@"=======================");
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    
    NSLog(@"llama_smoke_test: Completed successfully");
    return true;
}

extern "C" const char * thothai_generate_test(const char * prompt) {
    if (!prompt) {
        return strdup("Error: NULL prompt");
    }
    
    // Get Documents directory path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDir = [paths firstObject];
    NSString* modelPath = [documentsDir stringByAppendingPathComponent:@"qwen2.5-0.5b-q4_k_m.gguf"];
    
    const char* model_path_cstr = [modelPath UTF8String];
    
    // Log the resolved model path
    NSLog(@"Loading model: %s", model_path_cstr);
    
    // Check if model file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:modelPath]) {
        NSLog(@"ERROR: Model file not found at: %s", model_path_cstr);
        NSLog(@"Documents directory: %@", documentsDir);
        
        // List all files in Documents directory for debugging
        NSError* error = nil;
        NSArray* files = [fileManager contentsOfDirectoryAtPath:documentsDir error:&error];
        if (error) {
            NSLog(@"Error listing Documents directory: %@", error);
        } else {
            NSLog(@"Files in Documents directory (%lu):", (unsigned long)[files count]);
            for (NSString* file in files) {
                NSLog(@"  - %@", file);
            }
        }
        
        NSLog(@"Please ensure qwen2.5-0.5b-q4_k_m.gguf is in the app's Documents directory");
        return strdup("Error: Model file not found");
    }
    
    // Initialize backend
    llama_backend_init();
    // Register CPU backend statically (required on iOS where backends are statically linked)
    ggml_backend_register(ggml_backend_cpu_reg());
    
    // Load model
    struct llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;  // Force CPU-only execution
    llama_model* model = llama_model_load_from_file(model_path_cstr, model_params);
    
    if (!model) {
        llama_backend_free();
        return strdup("Error: Failed to load model");
    }
    
    // Initialize context
    struct llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 512;
    ctx_params.n_threads = 4;
    ctx_params.n_threads_batch = 4;
    
    llama_context* ctx = llama_init_from_model(model, ctx_params);
    
    if (!ctx) {
        llama_model_free(model);
        llama_backend_free();
        return strdup("Error: Failed to create context");
    }
    
    // Get vocabulary
    const llama_vocab* vocab = llama_model_get_vocab(model);
    llama_token eos_token = llama_vocab_eos(vocab);
    
    // Tokenize prompt
    const int max_tokens = 512;
    std::vector<llama_token> tokens(max_tokens);
    int n_tokens = llama_tokenize(vocab, prompt, (int)strlen(prompt), tokens.data(), max_tokens, true, false);
    
    if (n_tokens < 0) {
        // Buffer too small, try with actual size needed
        n_tokens = -n_tokens;
        tokens.resize(n_tokens);
        n_tokens = llama_tokenize(vocab, prompt, (int)strlen(prompt), tokens.data(), n_tokens, true, false);
    }
    
    if (n_tokens <= 0) {
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return strdup("Error: Failed to tokenize prompt");
    }
    
    tokens.resize(n_tokens);
    
    // Decode prompt tokens
    llama_batch batch = llama_batch_init(512, 0, 1);
    batch.n_tokens = n_tokens;
    
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.seq_id[i][0] = 0;
        batch.n_seq_id[i] = 1;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;  // Enable logits only for last token
    }
    
    if (llama_decode(ctx, batch) != 0) {
        llama_batch_free(batch);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return strdup("Error: Failed to decode prompt");
    }
    
    llama_batch_free(batch);
    
    // Create sampler
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler* smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.8f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    
    // Generation parameters
    const int n_gen = 16;  // Generate exactly 16 tokens
    
    // Generate tokens
    std::vector<llama_token> generated_tokens;
    generated_tokens.reserve(n_gen);
    
    for (int i = 0; i < n_gen; i++) {
        // Sample token
        llama_token new_token = llama_sampler_sample(smpl, ctx, -1);
        
        // Check for EOS
        if (new_token == eos_token) {
            break;
        }
        
        generated_tokens.push_back(new_token);
        
        // Decode the new token
        batch = llama_batch_init(1, 0, 1);
        batch.n_tokens = 1;
        batch.token[0] = new_token;
        batch.pos[0] = n_tokens + i;
        batch.seq_id[0][0] = 0;
        batch.n_seq_id[0] = 1;
        batch.logits[0] = true;  // Enable logits for sampling
        
        if (llama_decode(ctx, batch) != 0) {
            llama_batch_free(batch);
            break;
        }
        
        llama_batch_free(batch);
    }
    
    llama_sampler_free(smpl);
    
    // Convert tokens to text
    std::string generated_text;
    char buf[256];
    for (llama_token token : generated_tokens) {
        int len = llama_token_to_piece(vocab, token, buf, sizeof(buf), 0, false);
        if (len > 0 && len < (int)sizeof(buf)) {
            buf[len] = '\0';
            generated_text += buf;
        }
    }
    
    // Cleanup
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    
    // Return heap-allocated C string
    return strdup(generated_text.c_str());
}

extern "C" bool llama_generate_from_prompt(const char * prompt_utf8) {
    // Defensive checks: null pointer and empty string
    if (!prompt_utf8) {
        NSLog(@"llama_generate_from_prompt: ERROR - NULL prompt pointer");
        return false;
    }
    
    if (strlen(prompt_utf8) == 0) {
        NSLog(@"llama_generate_from_prompt: ERROR - Empty prompt string");
        return false;
    }
    
    // Log the received prompt before tokenization
    NSLog(@"llama_generate_from_prompt: Received prompt: '%s'", prompt_utf8);
    
    // Get Documents directory path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDir = [paths firstObject];
    NSString* modelPath = [documentsDir stringByAppendingPathComponent:@"qwen2.5-0.5b-q4_k_m.gguf"];
    
    const char* model_path_cstr = [modelPath UTF8String];
    
    // Log the resolved model path
    NSLog(@"Loading model: %s", model_path_cstr);
    
    // Check if model file exists
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:modelPath]) {
        NSLog(@"ERROR: Model file not found at: %s", model_path_cstr);
        NSLog(@"Documents directory: %@", documentsDir);
        
        // List all files in Documents directory for debugging
        NSError* error = nil;
        NSArray* files = [fileManager contentsOfDirectoryAtPath:documentsDir error:&error];
        if (error) {
            NSLog(@"Error listing Documents directory: %@", error);
        } else {
            NSLog(@"Files in Documents directory (%lu):", (unsigned long)[files count]);
            for (NSString* file in files) {
                NSLog(@"  - %@", file);
            }
        }
        
        NSLog(@"Please ensure qwen2.5-0.5b-q4_k_m.gguf is in the app's Documents directory");
        return false;
    }
    
    // Initialize backend
    llama_backend_init();
    // Register CPU backend statically (required on iOS where backends are statically linked)
    ggml_backend_register(ggml_backend_cpu_reg());
    
#if TARGET_OS_SIMULATOR
    NSLog(@"llama_generate_from_prompt: Simulator detected — CPU-only mode");
#endif
    
    // Load model
    struct llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;  // Force CPU-only execution
    llama_model* model = llama_model_load_from_file(model_path_cstr, model_params);
    
    if (!model) {
        NSLog(@"llama_generate_from_prompt: Failed to load model");
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
        NSLog(@"llama_generate_from_prompt: Failed to create context");
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    // Raw completion: tokenize the provided prompt
    const llama_vocab* vocab = llama_model_get_vocab(model);
    llama_token eos_token = llama_vocab_eos(vocab);
    
    // Tokenize as raw string without special tokens (add_special=false for raw completion)
    const int max_tokens = 512;
    std::vector<llama_token> tokens(max_tokens);
    int n_tokens = llama_tokenize(vocab, prompt_utf8, (int)strlen(prompt_utf8), tokens.data(), max_tokens, false, false);
    
    if (n_tokens < 0) {
        // Buffer too small, try with actual size needed
        n_tokens = -n_tokens;
        tokens.resize(n_tokens);
        n_tokens = llama_tokenize(vocab, prompt_utf8, (int)strlen(prompt_utf8), tokens.data(), n_tokens, false, false);
    }
    
    if (n_tokens <= 0) {
        NSLog(@"llama_generate_from_prompt: Failed to tokenize prompt");
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    tokens.resize(n_tokens);
    
    NSLog(@"llama_generate_from_prompt: Tokenized %d tokens (raw mode, no special tokens)", n_tokens);
    
    // Decode prompt tokens
    llama_batch batch = llama_batch_init(512, 0, 1);
    batch.n_tokens = n_tokens;
    
    for (int i = 0; i < n_tokens; i++) {
        batch.token[i] = tokens[i];
        batch.pos[i] = i;
        batch.seq_id[i][0] = 0;
        batch.n_seq_id[i] = 1;
        batch.logits[i] = (i == n_tokens - 1) ? 1 : 0;  // Enable logits only for last token
    }
    
    if (llama_decode(ctx, batch) != 0) {
        NSLog(@"llama_generate_from_prompt: Failed to decode prompt");
        llama_batch_free(batch);
        llama_free(ctx);
        llama_model_free(model);
        llama_backend_free();
        return false;
    }
    
    llama_batch_free(batch);
    
    // Create sampler with fixed parameters
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler* smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    
    // Generation parameters
    const int max_gen = 16;  // Maximum 16 tokens
    const int min_tokens_before_period = 3;  // Need at least 3 tokens before checking for period
    
    // Generate tokens
    std::vector<llama_token> generated_tokens;
    generated_tokens.reserve(max_gen);
    std::string generated_text;  // Track text as we generate to detect periods
    char buf[256];
    
    for (int i = 0; i < max_gen; i++) {
        // Sample token
        llama_token new_token = llama_sampler_sample(smpl, ctx, -1);
        
        // Check for EOS
        if (new_token == eos_token) {
            break;
        }
        
        generated_tokens.push_back(new_token);
        
        // Convert token to text piece to check for period
        int len = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, false);
        if (len > 0 && len < (int)sizeof(buf)) {
            buf[len] = '\0';
            generated_text += buf;
            
            // Check for period after at least min_tokens_before_period tokens
            // Check if the current token piece contains a period
            if (i >= min_tokens_before_period - 1) {
                if (strchr(buf, '.') != nullptr) {
                    // Found a period in the current token, stop generation
                    break;
                }
            }
        }
        
        // Decode the new token
        batch = llama_batch_init(1, 0, 1);
        batch.n_tokens = 1;
        batch.token[0] = new_token;
        batch.pos[0] = n_tokens + i;
        batch.seq_id[0][0] = 0;
        batch.n_seq_id[0] = 1;
        batch.logits[0] = true;  // Enable logits for sampling
        
        if (llama_decode(ctx, batch) != 0) {
            NSLog(@"llama_generate_from_prompt: Failed to decode generated token");
            llama_batch_free(batch);
            break;
        }
        
        llama_batch_free(batch);
    }
    
    llama_sampler_free(smpl);
    
    // Print output with specified markers (same as current behavior)
    NSLog(@"=== LLM TEST OUTPUT ===");
    NSLog(@"%s", generated_text.c_str());
    NSLog(@"=======================");
    
    // Cleanup
    llama_free(ctx);
    llama_model_free(model);
    llama_backend_free();
    
    return true;
}
