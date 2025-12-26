//
//  ThothAIApp.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import SwiftUI

@_silgen_name("llama_generate_from_prompt")
func llama_generate_from_prompt(_ prompt: UnsafePointer<CChar>) -> Bool

@main
struct ThothAIApp: App {
    @StateObject private var appCore = AppCore()
    
    init() {
        // Run minimal inference test at app launch
        runInferenceTest()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(appCore: appCore)
        }
    }
    
    private func runInferenceTest() {
        // Run test on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            // Test prompt - can be changed to test different prompts
            let prompt = "The dog wagged its tail and"
            
            let success = prompt.withCString { cString in
                llama_generate_from_prompt(cString)
            }
            
            if !success {
                print("=== LLM TEST OUTPUT ===")
                print("Error: Generation failed")
                print("=======================")
            }
        }
    }
}
