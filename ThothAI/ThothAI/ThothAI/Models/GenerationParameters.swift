//
//  GenerationParameters.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation

/// Parameters for text generation
/// 
/// This is a placeholder structure for Phase 1b.
/// Future phases will add actual sampling parameters (temperature, top-p, etc.)
struct GenerationParameters: Codable {
    /// Maximum number of tokens to generate
    var maxTokens: Int = 256
    
    /// Temperature for sampling (placeholder, not used in stub)
    var temperature: Double = 0.7
    
    /// Top-p sampling parameter (placeholder, not used in stub)
    var topP: Double = 0.9
    
    /// Default parameters
    static let `default` = GenerationParameters()
}

