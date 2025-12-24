//
//  LLMRuntime.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation

/// Runtime for LLM inference operations
/// 
/// Phase 1c-A2: GGUF inference using llama.cpp (CPU, one-shot).
/// Loads models and performs real inference.
@MainActor
class LLMRuntime {
    private let modelManager: ModelManager
    private let fileManager = FileManager.default
    
    /// Currently loaded model handle (nil if no model loaded)
    /// Note: LlamaModelHandle is void* in C, which bridges to OpaquePointer? in Swift
    private var loadedModelHandle: OpaquePointer?
    
    /// Path to the currently loaded model (for tracking)
    private var loadedModelPath: String?
    
    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }
    
    deinit {
        // Clean up loaded model on deallocation
        if let handle = loadedModelHandle {
            llama_free_model(handle)
        }
    }
    
    /// Generate text from a prompt
    /// - Parameters:
    ///   - prompt: The user prompt text
    ///   - systemPrompt: Optional system prompt (ignored for now)
    ///   - parameters: Generation parameters
    /// - Returns: Generation result with generated text and timing
    /// - Throws: LLMRuntimeError if generation cannot proceed
    func generate(
        prompt: String,
        systemPrompt: String? = nil,
        parameters: GenerationParameters = .default
    ) async throws -> GenerationResult {
        // Check if active model exists
        guard let activeModelId = modelManager.activeModelId,
              let model = modelManager.getModel(activeModelId) else {
            throw LLMRuntimeError.noActiveModel
        }
        
        // Validate model format and file
        try GGUFModelHandle.validate(model: model, fileManager: fileManager)
        
        // Record start time for timing metadata
        let startTime = Date()
        
        // Phase 1c-A2: Load model if not already loaded or if model changed
        let modelPath = model.storageURL.path
        if loadedModelHandle == nil || loadedModelPath != modelPath {
            // Unload previous model if exists
            if let handle = loadedModelHandle {
                llama_free_model(handle)
                loadedModelHandle = nil
            }
            
            // Load new model
            let cPath = modelPath.cString(using: .utf8)
            guard let path = cPath else {
                throw LLMRuntimeError.modelLoadFailed("Failed to convert model path to C string")
            }
            
            let handle = llama_load_model(path)
            guard let modelHandle = handle else {
                let errorMsg = llama_get_error()
                let errorString = errorMsg != nil ? String(cString: errorMsg!) : "Unknown error"
                throw LLMRuntimeError.modelLoadFailed(errorString)
            }
            
            loadedModelHandle = modelHandle
            loadedModelPath = modelPath
        }
        
        // Perform generation
        let cPrompt = prompt.cString(using: .utf8)
        guard let promptCString = cPrompt else {
            throw LLMRuntimeError.generationFailed("Failed to convert prompt to C string")
        }
        
        // Use fixed generation config: max_tokens=128, temperature=0.7
        // Phase 1c-A2: CPU-only inference, acceptable performance for small models (≤1B params)
        let maxTokens = min(parameters.maxTokens, 128) // Cap at 128 for Phase 1c-A2
        let temperature: Float = 0.7
        
        let generatedCString = llama_generate(loadedModelHandle!, promptCString, maxTokens, temperature)
        
        guard let generated = generatedCString else {
            let errorMsg = llama_get_error()
            let errorString = errorMsg != nil ? String(cString: errorMsg!) : "Unknown error"
            llama_free_string(generatedCString)
            throw LLMRuntimeError.generationFailed(errorString)
        }
        
        // Convert C string to Swift String
        let generatedText = String(cString: generated)
        
        // Free the C string
        llama_free_string(generated)
        
        // Calculate generation time
        let generationTime = Date().timeIntervalSince(startTime)
        
        return GenerationResult(
            text: generatedText,
            generationTime: generationTime,
            tokensGenerated: 0 // TODO: Get actual token count from llama.cpp
        )
    }
    
    /// Check if a model is currently loaded and ready
    /// - Returns: true if an active model is selected, false otherwise
    var hasActiveModel: Bool {
        modelManager.activeModelId != nil && 
        modelManager.getModel(modelManager.activeModelId!) != nil
    }
    
    /// Get the currently active model metadata, if any
    /// - Returns: The active model metadata, or nil
    var activeModel: ModelMetadata? {
        guard let activeModelId = modelManager.activeModelId else {
            return nil
        }
        return modelManager.getModel(activeModelId)
    }
}

// MARK: - GGUF Model Validation Helper

/// Internal helper for validating GGUF model files
/// 
/// Performs basic validation:
/// - Format verification (must be GGUF)
/// - File existence check
/// - File readability check
/// Does NOT parse model contents or validate model structure.
private struct GGUFModelHandle {
    /// Validate a model for GGUF runtime use
    /// - Parameters:
    ///   - model: The model metadata to validate
    ///   - fileManager: The file manager to use for file operations
    /// - Throws: LLMRuntimeError if validation fails
    static func validate(model: ModelMetadata, fileManager: FileManager) throws {
        // Verify model format is GGUF
        guard model.format == .gguf else {
            throw LLMRuntimeError.unsupportedFormat("Model format '\(model.format.rawValue)' is not supported. Only GGUF models are supported at this time.")
        }
        
        // Verify model file exists
        guard fileManager.fileExists(atPath: model.storageURL.path) else {
            throw LLMRuntimeError.modelFileMissing("Model file not found at: \(model.storageURL.path)")
        }
        
        // Verify file is readable
        guard fileManager.isReadableFile(atPath: model.storageURL.path) else {
            throw LLMRuntimeError.modelFileUnreadable("Model file is not readable at: \(model.storageURL.path)")
        }
        
        // Additional basic validation: check file size matches metadata (non-fatal)
        do {
            let attributes = try fileManager.attributesOfItem(atPath: model.storageURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                // Note: We don't fail if sizes don't match, just log for debugging
                if fileSize != model.size {
                    print("Warning: Model file size (\(fileSize)) does not match metadata (\(model.size))")
                }
            }
        } catch {
            // If we can't read attributes, that's okay for now - file exists and is readable
            print("Note: Could not read file attributes: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors

enum LLMRuntimeError: LocalizedError {
    case noActiveModel
    case modelNotFound
    case unsupportedFormat(String)
    case modelFileMissing(String)
    case modelFileUnreadable(String)
    case modelLoadFailed(String)
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveModel:
            return "No active model selected. Please import and activate a model first."
        case .modelNotFound:
            return "Active model not found. The model may have been deleted."
        case .unsupportedFormat(let message):
            return message
        case .modelFileMissing(let message):
            return "Model file missing: \(message). The file may have been moved or deleted."
        case .modelFileUnreadable(let message):
            return "Model file unreadable: \(message). Please check file permissions."
        case .modelLoadFailed(let message):
            return "Failed to load model: \(message)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        }
    }
}

