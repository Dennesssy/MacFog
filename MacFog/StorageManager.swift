//
//  StorageManager.swift
//  MacFog
//
//  Created on 4/3/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

/// Data structure for storage category visualization
struct StorageCategoryData: Identifiable {
    let id: UUID
    let category: String
    let size: Int64
    let percentage: Double
    let color: Color
    
    var formattedSize: String {
        formatSize(size)
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
    
    /// Format a size in bytes to a human-readable string
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Storage Manager

/// Service for handling file system operations
@MainActor
class StorageManager: ObservableObject {
    private let fileManager = FileManager.default
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var fileStats = FileStats()
    @Published var categoryData: [StorageCategoryData] = []
    @Published var errorMessage: String?
    
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
    
    /// Start scanning the file system
    func startScan() {
        Task {
            do {
                _ = try await scanFileSystem()
                updateCategoryData()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Scan the file system for storage information
    private func scanFileSystem() async throws -> FileStats {
        guard !isScanning else { 
            throw NSError(domain: "StorageManager", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Scan already in progress"]) 
        }
        
        isScanning = true
        scanProgress = 0.0
        totalSize = 0
        fileStats = FileStats()
        
        // Start a timer to update the progress
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Simulate progress for now
            if self.scanProgress < 0.99 {
                self.scanProgress += 0.02
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
        
        totalSize = total
        fileStats = stats
        scanProgress = 1.0
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        isScanning = false
        
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
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])
            
            var totalSize: Int64 = 0
            
            for fileURL in contents {
                // Check for cancellation
                try Task.checkCancellation()
                
                // Get file attributes
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    // Recursively scan subdirectories
                    totalSize += try await scanDirectory(at: fileURL)
                } else if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            
            return totalSize
        } catch {
            // Gracefully handle permission errors
            print("Error scanning \(url.path): \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Cancel an ongoing scan
    func cancelScan() {
        scanTask?.cancel()
        
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        isScanning = false
    }
    
    /// Update category data for visualization
    private func updateCategoryData() {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow, .gray]
        
        var result: [StorageCategoryData] = []
        var colorIndex = 0
        
        for (category, size) in fileStats.categories {
            // Skip categories with zero size
            guard size > 0 else { continue }
            
            let percentage = totalSize > 0 ? Double(size) / Double(totalSize) : 0
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            
            result.append(StorageCategoryData(
                id: UUID(),
                category: category,
                size: size,
                percentage: percentage,
                color: color
            ))
        }
        
        // Sort by size (largest first)
        categoryData = result.sorted { $0.size > $1.size }
    }
    
    /// Format a size in bytes to a human-readable string
    static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
