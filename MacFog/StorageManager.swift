//
// StorageManager.swift
// MacFog
//
// Created on 4/3/25.
//

import Foundation
import SwiftUI
import Combine

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
    
    /// Start scanning the file system
    func startScan(url: URL) {
        Task {
            do {
                _ = try await scanFileSystem(url: url)
                updateCategoryData()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func requestPermissionAndScan() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Please select a directory to scan."
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                startScan(url: url)
            }
        } else {
            errorMessage = "Permission to access the directory was denied."
        }
    }
    
    /// Scan the file system for storage information
    private func scanFileSystem(url: URL) async throws -> FileStats {
        guard !isScanning else {
            throw NSError(domain: "StorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scan already in progress"])
        }
        
        isScanning = true
        scanProgress = 0.0
        totalSize = 0
        fileStats = FileStats()
        
        let homeURL = URL(fileURLWithPath: NSHomeDirectory())
        var stats = FileStats()
        
        // Documents
        let documentsURL = homeURL.appendingPathComponent("Documents")
        stats.userDocuments = try await scanDirectory(at: documentsURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // Downloads
        let downloadsURL = homeURL.appendingPathComponent("Downloads")
        stats.userDocuments += try await scanDirectory(at: downloadsURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // Desktop
        let desktopURL = homeURL.appendingPathComponent("Desktop")
        stats.userDocuments += try await scanDirectory(at: desktopURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // Applications
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        stats.applications = try await scanDirectory(at: applicationsURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // Media
        let picturesURL = homeURL.appendingPathComponent("Pictures")
        let musicURL = homeURL.appendingPathComponent("Music")
        let moviesURL = homeURL.appendingPathComponent("Movies")
        
        stats.media += try await scanDirectory(at: picturesURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        stats.media += try await scanDirectory(at: musicURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        stats.media += try await scanDirectory(at: moviesURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // Caches
        let libraryURL = homeURL.appendingPathComponent("Library")
        let cachesURL = libraryURL.appendingPathComponent("Caches")
        stats.caches = try await scanDirectory(at: cachesURL) { progress in
            DispatchQueue.main.async {
                self.scanProgress = progress
            }
        }
        
        // System (Approximation as scanning /System is restricted)
        stats.system = 15 * 1024 * 1024 * 1024
        
        let total = stats.system + stats.applications + stats.userDocuments + stats.media + stats.caches + stats.duplicates + stats.other
        self.totalSize = total
        self.fileStats = stats
        
        scanProgress = 1.0
        isScanning = false
        
        return fileStats
    }
    
    /// Scan a directory and calculate its size
    private func scanDirectory(at url: URL, progress: @escaping (Double) -> Void) async throws -> Int64 {
        var totalDirectorySize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        let contents = enumerator.allObjects as? [URL] ?? []
        let fileCount = contents.count
        
        guard fileCount > 0 else {
            DispatchQueue.main.async {
                progress(1.0)
            }
            return 0
        }
        
        var processedFiles = 0
        
        for fileURL in contents {
            if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let fileSize = attrs.fileSize {
                totalDirectorySize += Int64(fileSize)
            }
            
            processedFiles += 1
            
            if processedFiles % 100 == 0 {
                let currentProgress = Double(processedFiles) / Double(fileCount)
                DispatchQueue.main.async {
                    progress(currentProgress)
                }
            }
        }
        
        // Final update
        DispatchQueue.main.async {
            progress(1.0)
        }
        
        return totalDirectorySize
    }
    
    /// Cancel an ongoing scan
    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }
    
    /// Update category data for visualization
    private func updateCategoryData() {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow, .gray]
        var result: [StorageCategoryData] = []
        var colorIndex = 0
        
        for (category, size) in fileStats.categories {
            // Skip categories with zero size
            guard size > 0 else {
                continue
            }
            
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
