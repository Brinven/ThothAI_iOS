//
//  GenerationResult.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation

/// Result of a text generation operation
struct GenerationResult {
    /// The generated text
    let text: String
    
    /// Time taken to generate (in seconds)
    let generationTime: TimeInterval
    
    /// Number of tokens generated (placeholder for stub)
    let tokensGenerated: Int
    
    /// Initialize a generation result
    init(text: String, generationTime: TimeInterval, tokensGenerated: Int = 0) {
        self.text = text
        self.generationTime = generationTime
        self.tokensGenerated = tokensGenerated
    }
}

