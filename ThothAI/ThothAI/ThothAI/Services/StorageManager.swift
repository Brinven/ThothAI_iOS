//
//  StorageManager.swift
//  ThothAI
//
//  Created by Mike on 12/23/25.
//

import Foundation

/// Manages app-managed storage directories and provides file operations
class StorageManager {
    static let shared = StorageManager()
    
    private let fileManager = FileManager.default
    
    /// Base directory for all app-managed storage
    private var appStorageURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ThothAI", isDirectory: true)
    }
    
    /// Directory for knowledge bases
    var knowledgeBasesDirectory: URL {
        appStorageURL.appendingPathComponent("KnowledgeBases", isDirectory: true)
    }
    
    /// Directory for model files
    var modelsDirectory: URL {
        appStorageURL.appendingPathComponent("Models", isDirectory: true)
    }
    
    /// Directory for app settings
    var settingsDirectory: URL {
        appStorageURL.appendingPathComponent("Settings", isDirectory: true)
    }
    
    private init() {
        // Ensure directories exist on first access
        ensureDirectoriesExist()
    }
    
    /// Create directories if they don't exist
    private func ensureDirectoriesExist() {
        let directories = [
            appStorageURL,
            knowledgeBasesDirectory,
            modelsDirectory,
            settingsDirectory
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
    }
    
    /// Get available free space in bytes
    /// - Returns: Available free space in bytes, or nil if unable to determine
    func getFreeSpace() -> Int64? {
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: appStorageURL.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return nil
        }
        return freeSpace
    }
    
    /// Get available free space as a human-readable string
    /// - Returns: Formatted string (e.g., "1.5 GB") or "Unknown" if unable to determine
    func getFreeSpaceString() -> String {
        guard let bytes = getFreeSpace() else {
            return "Unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Atomically write data to a file
    /// - Parameters:
    ///   - data: The data to write
    ///   - url: The destination URL
    /// - Throws: File system errors
    func writeAtomically(_ data: Data, to url: URL) throws {
        // Create parent directory if needed
        let parentDir = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(
                at: parentDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Write atomically using a temporary file
        let tempURL = url.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        try fileManager.moveItem(at: tempURL, to: url)
    }
    
    /// Atomically write a string to a file
    /// - Parameters:
    ///   - string: The string to write
    ///   - url: The destination URL
    /// - Throws: File system errors
    func writeAtomically(_ string: String, to url: URL) throws {
        guard let data = string.data(using: .utf8) else {
            throw NSError(
                domain: "StorageManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode string as UTF-8"]
            )
        }
        try writeAtomically(data, to: url)
    }
}

