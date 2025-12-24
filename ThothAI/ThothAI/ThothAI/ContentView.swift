//
//  ContentView.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var appCore: AppCore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mode Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mode")
                        .font(.headline)
                    
                    Picker("Mode", selection: Binding(
                        get: { appCore.appState.activeMode },
                        set: { appCore.modeController.switchToMode($0) }
                    )) {
                        ForEach(AppMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Memory Policy Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Memory Policy")
                        .font(.headline)
                    Text(appCore.appState.memoryPolicy.rawValue)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Storage Paths
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage Directories")
                        .font(.headline)
                    
                    StoragePathView(
                        label: "Knowledge Bases",
                        path: StorageManager.shared.knowledgeBasesDirectory.path
                    )
                    
                    StoragePathView(
                        label: "Models",
                        path: StorageManager.shared.modelsDirectory.path
                    )
                    
                    StoragePathView(
                        label: "Settings",
                        path: StorageManager.shared.settingsDirectory.path
                    )
                }
                
                Divider()
                
                // Free Space
                VStack(alignment: .leading, spacing: 8) {
                    Text("Free Space")
                        .font(.headline)
                    Text(StorageManager.shared.getFreeSpaceString())
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct StoragePathView: View {
    let label: String
    let path: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(path)
                .font(.caption)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    ContentView(appCore: AppCore())
}
