//
//  FileSystemService.swift
//  MacFog
//
//  Created on 4/3/25.
//

import Foundation
import Combine

/// Service for handling file system operations
@MainActor
class FileSystemService: ObservableObject {
    private let fileManager = FileManager.default
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var fileStats: FileStats = FileStats()
    
    private var scanTask: Task<Void, Error>?
    private var progressUpdateTimer: Timer?
    
    /// Represents file statistics by category
    struct FileStats {
        var system: Int64 = 0
        var applications: Int64 = 0
        var userDocuments: Int64 = 0
        var media: Int64 = 0
        var caches: Int64 = 0
        var duplicates: Int64 = 0
        var other: Int64 = 0
        
        var categories: [String: Int64] {
            [
                "System": system,
                "Applications": applications,
                "User Documents": userDocuments,
                "Media": media,
                "Caches": caches,
                "Duplicates": duplicates,
                "Other": other
            ]
        }
    }

    /// Scan the file system for storage information
    func scanFileSystem() async throws -> FileStats {
        guard !isScanning else { throw NSError(domain: "FileSystemService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scan already in progress"]) }
        
        DispatchQueue.main.async {
            self.isScanning = true
            self.scanProgress = 0.0
            self.totalSize = 0
            self.fileStats = FileStats()
            
            // Start a timer to update the progress
            self.progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                // Simulate progress for now
                DispatchQueue.main.async {
                    if self.scanProgress < 0.99 {
                        self.scanProgress += 0.02
                    }
                }
            }
        }
        
        // Get home directory
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        
        var stats = FileStats()
        
        // Scan Applications
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        stats.applications = try await scanDirectory(at: applicationsURL)
        
        // Scan User Documents
        let documentsURL = homeURL.appendingPathComponent("Documents")
        stats.userDocuments = try await scanDirectory(at: documentsURL)
        
        // Scan Downloads
        let downloadsURL = homeURL.appendingPathComponent("Downloads")
        stats.userDocuments += try await scanDirectory(at: downloadsURL)
        
        // Scan Desktop 
        let desktopURL = homeURL.appendingPathComponent("Desktop")
        stats.userDocuments += try await scanDirectory(at: desktopURL)
        
        // Scan Media
        let picturesURL = homeURL.appendingPathComponent("Pictures")
        let musicURL = homeURL.appendingPathComponent("Music")
        let moviesURL = homeURL.appendingPathComponent("Movies")
        
        stats.media += try await scanDirectory(at: picturesURL)
        stats.media += try await scanDirectory(at: musicURL)
        stats.media += try await scanDirectory(at: moviesURL)
        
        // Scan Caches
        let libraryURL = homeURL.appendingPathComponent("Library")
        let cachesURL = libraryURL.appendingPathComponent("Caches")
        stats.caches = try await scanDirectory(at: cachesURL)
        
        // For the purpose of this demo, set a reasonable value for system files
        stats.system = 15 * 1024 * 1024 * 1024 // Approximately 15GB for system
        
        // Calculate total size
        let total = stats.system + stats.applications + stats.userDocuments + 
                    stats.media + stats.caches + stats.duplicates + stats.other
        
        DispatchQueue.main.async {
            self.totalSize = total
            self.fileStats = stats
            self.scanProgress = 1.0
            self.progressUpdateTimer?.invalidate()
            self.progressUpdateTimer = nil
            self.isScanning = false
        }
        
        return stats
    }
    
    /// Scan a directory and calculate its size
    private func scanDirectory(at url: URL) async throws -> Int64 {
        // Check if directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return 0
        }
        
        // Get directory contents
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])
        
        var totalSize: Int64 = 0
        
        for fileURL in contents {
            // Get file attributes
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            
            if let isDirectory = resourceValues.isDirectory, isDirectory {
                // Recursively scan subdirectories
                totalSize += try await scanDirectory(at: fileURL)
            } else if let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
            
            // Check for cancellation
            try Task.checkCancellation()
        }
        
        return totalSize
    }
    
    /// Cancel an ongoing scan
    func cancelScan() {
        scanTask?.cancel()
        
        DispatchQueue.main.async {
            self.progressUpdateTimer?.invalidate()
            self.progressUpdateTimer = nil
            self.isScanning = false
        }
    }
    
    /// Format a size in bytes to a human-readable string
    static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
