import Foundation
import SwiftUI

@MainActor
class FileSystemService: ObservableObject {
    // MARK: - Supporting Types
    
    /// Represents file statistics by category
    struct FileStats {
        var system: Int64 = 0
        var applications: Int64 = 0
        var documents: Int64 = 0
        var downloads: Int64 = 0
        var desktop: Int64 = 0
        var media: Int64 = 0
        var caches: Int64 = 0
        var duplicates: Int64 = 0
        var other: Int64 = 0
        
        var categories: [String: Int64] {
            [
                "System": system,
                "Applications": applications,
                "Documents": documents,
                "Downloads": downloads,
                "Desktop": desktop,
                "Media": media,
                "Caches": caches,
                "Duplicates": duplicates,
                "Other": other
            ]
        }
    }

    // MARK: - Published Properties
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var fileStats = FileStats()
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Error>?
    
    // MARK: - Computed Properties
    private var homeURL: URL {
        fileManager.homeDirectoryForCurrentUser
    }
    
    private var applicationsURL: URL {
        URL(fileURLWithPath: "/Applications")
    }
    
    private var documentsURL: URL {
        homeURL.appendingPathComponent("Documents")
    }
    
    private var downloadsURL: URL {
        homeURL.appendingPathComponent("Downloads")
    }
    
    private var desktopURL: URL {
        homeURL.appendingPathComponent("Desktop")
    }
    
    private var mediaURLs: [URL] {
        [
            homeURL.appendingPathComponent("Pictures"),
            homeURL.appendingPathComponent("Music"),
            homeURL.appendingPathComponent("Movies")
        ]
    }
    
    private var cachesURL: URL {
        homeURL.appendingPathComponent("Library/Caches")
    }
    
    // MARK: - Public Interface
    
    /// Scan the file system for storage information
    func scanFileSystem() async throws -> FileStats {
        guard !isScanning else {
            throw NSError(domain: "FileSystemService", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Scan already in progress"])
        }
        
        isScanning = true
        scanProgress = 0.0
        totalSize = 0
        fileStats = FileStats()
        errorMessage = nil
        
        defer {
            isScanning = false
        }
        
        do {
            // Scan directories with progress tracking
            let documentsSize = try await scanDirectory(at: documentsURL) { progress in
                Task { @MainActor in
                    self.scanProgress = progress * 0.2
                }
            }
            fileStats.documents = documentsSize
            
            let downloadsSize = try await scanDirectory(at: downloadsURL) { progress in
                Task { @MainActor in
                    self.scanProgress = 0.2 + progress * 0.2
                }
            }
            fileStats.downloads = downloadsSize
            
            let desktopSize = try await scanDirectory(at: desktopURL) { progress in
                Task { @MainActor in
                    self.scanProgress = 0.4 + progress * 0.2
                }
            }
            fileStats.desktop = desktopSize
            
            let applicationsSize = try await scanDirectory(at: applicationsURL) { progress in
                Task { @MainActor in
                    self.scanProgress = 0.6 + progress * 0.2
                }
            }
            fileStats.applications = applicationsSize
            
            // Scan media directories (combined)
            var mediaTotal: Int64 = 0
            for (index, mediaURL) in mediaURLs.enumerated() {
                let size = try await scanDirectory(at: mediaURL) { progress in
                    Task { @MainActor in
                        let base: Double = 0.8
                        let segment: Double = 0.1 / Double(self.mediaURLs.count)
                        self.scanProgress = base + Double(index) * segment + progress * segment
                    }
                }
                mediaTotal += size
            }
            fileStats.media = mediaTotal
            
            let cachesSize = try await scanDirectory(at: cachesURL) { progress in
                Task { @MainActor in
                    self.scanProgress = 0.9 + progress * 0.1
                }
            }
            fileStats.caches = cachesSize
            
            // Set system as a fixed value (would be scanned in production)
            fileStats.system = 15 * 1024 * 1024 * 1024 // 15 GB
            
            // Calculate total
            totalSize = fileStats.system + fileStats.applications + fileStats.documents + 
                       fileStats.downloads + fileStats.desktop + fileStats.media + 
                       fileStats.caches + fileStats.duplicates + fileStats.other
            
            scanProgress = 1.0
            return fileStats
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Cancel an ongoing scan
    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }
    
    // MARK: - Private Methods
    
    /// Scan a directory and calculate its size
    private func scanDirectory(at url: URL, progress: @escaping (Double) -> Void) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            var totalSize: Int64 = 0
            
            // Check if directory exists
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continuation.resume(returning: 0)
                return
            }
            
            // Get file enumerator
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { (url, error) -> Bool in
                    return true // Continue scanning despite errors
                }
            ) else {
                continuation.resume(returning: 0)
                return
            }
            
            // Collect all file URLs first for progress calculation
            var allFiles: [URL] = []
            for case let fileURL as URL in enumerator {
                allFiles.append(fileURL)
            }
            
            let totalFiles = allFiles.count
            var processedFiles = 0
            
            // Process files
            for fileURL in allFiles {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    // Skip files that can't be accessed
                    continue
                }
                
                processedFiles += 1
                let progressValue = Double(processedFiles) / Double(max(totalFiles, 1))
                progress(progressValue)
            }
            
            continuation.resume(returning: totalSize)
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
