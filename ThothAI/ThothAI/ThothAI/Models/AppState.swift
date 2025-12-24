//
//  AppState.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation
import Combine

/// Represents the operational mode of the application
enum AppMode: String, Codable, CaseIterable {
    case rag = "RAG"
    case chatbot = "Chatbot"
}

/// Represents the memory policy for conversation memory
enum MemoryPolicy: String, Codable, CaseIterable {
    case off = "Off"
    case session = "Session"
    case persisted = "Persisted"
}

/// Global application state that holds the current active resources and configuration
@MainActor
class AppState: ObservableObject {
    /// The ID of the currently active knowledge base, if any
    @Published var activeKnowledgeBaseId: String?
    
    /// The ID of the currently active model, if any
    @Published var activeModelId: String?
    
    /// The current operational mode (RAG or Chatbot)
    @Published var activeMode: AppMode
    
    /// The ID of the currently active profile, if any
    @Published var activeProfileId: String?
    
    /// The current memory policy
    @Published var memoryPolicy: MemoryPolicy
    
    /// Initialize with default state
    init(
        activeKnowledgeBaseId: String? = nil,
        activeModelId: String? = nil,
        activeMode: AppMode = .chatbot,
        activeProfileId: String? = nil,
        memoryPolicy: MemoryPolicy = .session
    ) {
        self.activeKnowledgeBaseId = activeKnowledgeBaseId
        self.activeModelId = activeModelId
        self.activeMode = activeMode
        self.activeProfileId = activeProfileId
        self.memoryPolicy = memoryPolicy
    }
}

