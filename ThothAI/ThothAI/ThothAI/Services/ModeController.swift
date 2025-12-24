//
//  ModeController.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation

/// Controls mode switching and enforces memory policy semantics
/// 
/// Rules:
/// - RAG mode ALWAYS forces memoryPolicy = .off
/// - Chatbot mode defaults to memoryPolicy = .session
/// - If user previously enabled persisted memory, Chatbot mode may use .persisted
/// - Switching from Chatbot → RAG must immediately disable memory usage
@MainActor
class ModeController {
    private let appState: AppState
    
    /// Tracks the last memory policy used in Chatbot mode (for restoration)
    private var lastChatbotMemoryPolicy: MemoryPolicy = .session
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    /// Switch to the specified mode, enforcing memory policy rules
    /// - Parameter mode: The mode to switch to
    func switchToMode(_ mode: AppMode) {
        switch mode {
        case .rag:
            // RAG mode: ALWAYS disable memory
            // Save current policy if we're coming from Chatbot mode
            if appState.activeMode == .chatbot {
                lastChatbotMemoryPolicy = appState.memoryPolicy
            }
            appState.activeMode = .rag
            appState.memoryPolicy = .off
            
        case .chatbot:
            // Chatbot mode: restore previous memory policy or default to session
            appState.activeMode = .chatbot
            appState.memoryPolicy = lastChatbotMemoryPolicy
        }
    }
    
    /// Set the memory policy (only valid in Chatbot mode)
    /// - Parameter policy: The memory policy to set
    /// - Returns: true if the policy was set, false if it was rejected (e.g., in RAG mode)
    @discardableResult
    func setMemoryPolicy(_ policy: MemoryPolicy) -> Bool {
        // Only allow memory policy changes in Chatbot mode
        guard appState.activeMode == .chatbot else {
            return false
        }
        
        // RAG mode cannot have memory enabled
        if policy != .off {
            appState.memoryPolicy = policy
            lastChatbotMemoryPolicy = policy
            return true
        }
        
        return false
    }
    
    /// Get the current mode
    var currentMode: AppMode {
        appState.activeMode
    }
    
    /// Get the current memory policy
    var currentMemoryPolicy: MemoryPolicy {
        appState.memoryPolicy
    }
}

