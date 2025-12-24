//
//  AppCore.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation
import Combine

/// Central application core that manages global state
@MainActor
class AppCore: ObservableObject {
    /// The shared application state
    @Published var appState: AppState
    
    /// The mode controller for managing mode switching and memory policy
    let modeController: ModeController
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize AppCore with default state
    init() {
        // Initialize with safe defaults
        let initialState = AppState(
            activeKnowledgeBaseId: nil,
            activeModelId: nil,
            activeMode: .chatbot,
            activeProfileId: nil,
            memoryPolicy: .session
        )
        
        // Initialize stored properties
        self.appState = initialState
        self.modeController = ModeController(appState: initialState)
        
        // Forward appState changes to AppCore's objectWillChange
        // This must happen after all stored properties are initialized
        initialState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

