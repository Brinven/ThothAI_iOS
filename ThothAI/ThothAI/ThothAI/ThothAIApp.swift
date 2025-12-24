//
//  ThothAIApp.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import SwiftUI

@main
struct ThothAIApp: App {
    @StateObject private var appCore = AppCore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(appCore: appCore)
        }
    }
}
