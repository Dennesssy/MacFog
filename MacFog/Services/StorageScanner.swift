import Foundation
import SwiftUI

// MARK: - Scan Result Model

/// Represents the results of a storage scan.
struct ScanResult: Identifiable {
    let id = UUID()
    
    // File counts
    var totalFiles: Int = 0
    var cacheFiles: Int = 0
    var logFiles: Int = 0
    var applicationSupportFiles: Int = 0
    var libraryFiles: Int = 0
    var tempFiles: Int = 0
    var executableFiles: Int = 0
    var gitDirectories: Int = 0
    var iCloudFiles: Int = 0
    var quarantinedFiles: Int = 0
    var permissionDeniedFiles: Int = 0
    
    // Total sizes (bytes)
    var totalSize: Int64 = 0
    var cacheSize: Int64 = 0
    var logSize: Int64 = 0
    var appSupportSize: Int64 = 0
    var librarySize: Int64 = 0
    var tempSize: Int64 = 0
    var executableSize: Int64 = 0
    var iCloudSize: Int64 = 0
    
    // Convenience computed properties
    var sizeInMegabytes: Double { Double(totalSize) / (1024 * 1024) }
    var sizeInGigabytes: Double { sizeInMegabytes / 1024 }
    
    /// Returns a breakdown of size by category for charting.
    var categorySizeBreakdown: [(category: String, size: Int64)] {
        [
            ("Caches", cacheSize),
            ("Logs", logSize),
            ("Application Support", appSupportSize),
            ("Library", librarySize),
            ("Temp", tempSize),
            ("Executables", executableSize),
            ("iCloud", iCloudSize)
        ].filter { $0.size > 0 }
    }
}

// MARK: - Storage Scanner

@MainActor
class StorageScanner: ObservableObject {
    // MARK: Published Properties
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var fileStats: ScanResult = ScanResult()
    @Published var scannedPaths: [String] = []
    @Published var errors: [String] = []
    @Published var foundFiles: [URL] = []
    @Published var selectedFile: URL?
    @Published var searchText: String = ""
    @Published var selectedCategory: ScanCategory = .all
    @Published var showingICloudControls = false
    @Published var showingSettings = false
    
    // MARK: Settings (UserDefaults)
    @AppStorage("highlightExecutables") var highlightExecutables: Bool = false
    @AppStorage("includeGitDirectories") var includeGitDirectories: Bool = false
    @AppStorage("scanICloud") var scanICloud: Bool = false
    @AppStorage("skipSystemPaths") var skipSystemPaths: Bool = true
    @AppStorage("useLoadingAnimation") var useLoadingAnimation: Bool = true
    
    // MARK: Private State
    
    private let fileManager = FileManager.default
    private var cancelAllTasks = false
    private var scannedFileSet = Set<URL>()
    
    // MARK: - Public Interface
    
    /// Starts a full system scan. Returns a result when complete or throws.
    func scanFileSystem() async throws -> ScanResult {
        await MainActor.run {
            self.isScanning = true
            self.scanProgress = 0.0
            self.totalSize = 0
            self.fileStats = ScanResult()
            self.scannedPaths = []
            self.errors = []
            self.foundFiles = []
            self.scannedFileSet.removeAll()
            self.cancelAllTasks = false
        }
        
        defer {
            Task { @MainActor in
                self.isScanning = false
            }
        }
        
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        // Build list of scan targets
        var scanTargets: [(path: String, description: String)] = [
            (homeDirectory.appendingPathComponent("Library/Caches").path, "User Caches"),
            (homeDirectory.appendingPathComponent("Library/Logs").path, "User Logs"),
            (homeDirectory.appendingPathComponent("Library/Application Support").path, "Application Support"),
            (homeDirectory.appendingPathComponent("Library/Containers").path, "App Containers"),
            (homeDirectory.appendingPathComponent("Library/Developer").path, "Developer Files"),
            (homeDirectory.appendingPathComponent("Library/Preferences").path, "Preferences"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.coresymbolication").path, "Symbolication Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.helpd").path, "Help Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.coreservices.appleevents").path, "Apple Events Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.IconServices").path, "Icon Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.finder").path, "Finder Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.dock").path, "Dock Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.mail").path, "Mail Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/com.apple.Safari").path, "Safari Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/Google").path, "Chrome Cache"),
            (homeDirectory.appendingPathComponent("Library/Caches/Mozilla").path, "Firefox Cache"),
            (homeDirectory.appendingPathComponent("Library/Logs/CrashReporter").path, "Crash Reports"),
            (homeDirectory.appendingPathComponent("Library/Logs/DiagnosticReports").path, "Diagnostic Reports"),
            (homeDirectory.appendingPathComponent("Library/Logs/MemoryUsage").path, "Memory Usage Logs"),
            (homeDirectory.appendingPathComponent("Library/Logs/OSDbg").path, "OS Debug Logs"),
            (homeDirectory.appendingPathComponent("Library/Logs/OTACrashLogs").path, "OTA Crash Logs"),
            (homeDirectory.appendingPathComponent("Library/Logs/Unity").path, "Unity Logs"),
            (homeDirectory.appendingPathComponent("Library/Logs/Xcode").path, "Xcode Logs"),
            (NSTemporaryDirectory(), "System Temp Files")
        ]
        
        // Add iCloud if requested
        if scanICloud {
            let icloudDoc = homeDirectory.appendingPathComponent("Library/Mobile Documents").path
            scanTargets.append((icloudDoc, "iCloud Documents"))
        }
        
        let totalTargets = scanTargets.count
        var processedTargets = 0
        var result = ScanResult()
        
        for (path, description) in scanTargets {
            guard !cancelAllTasks else { break }
            
            // Skip known system paths if required
            if skipSystemPaths && (path.hasPrefix("/System") || path.hasPrefix("/usr") || path.hasPrefix("/bin") || path.hasPrefix("/sbin")) {
                processedTargets += 1
                await MainActor.run { self.scanProgress = Double(processedTargets) / Double(totalTargets) }
                continue
            }
            
            do {
                try await scanDirectory(at: URL(fileURLWithPath: path), description: description, result: &result)
                await MainActor.run {
                    self.scannedPaths.append("\(description): \(path)")
                }
            } catch {
                await MainActor.run {
                    self.errors.append("Failed to scan \(description): \(error.localizedDescription)")
                }
            }
            
            processedTargets += 1
            await MainActor.run {
                self.scanProgress = Double(processedTargets) / Double(totalTargets)
            }
        }
        
        await MainActor.run {
            self.totalSize = result.totalSize
            self.fileStats = result
            self.scanProgress = 1.0
        }
        
        return result
    }
    
    // MARK: - Directory Scanning
    
    private func scanDirectory(at directoryURL: URL, description: String, result: inout ScanResult) async throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return
        }
        
        let keys: [URLResourceKey] = [
            .fileSizeKey,
            .isDirectoryKey,
            .isExecutableKey,
            .quarantinePropertiesKey
        ]
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { (url, error) -> Bool in
                return true // Continue scanning despite errors
            }
        ) else {
            return
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if cancelAllTasks {
                return
            }
            
            // Avoid duplicate processing via symlinks etc.
            if scannedFileSet.contains(fileURL) { continue }
            scannedFileSet.insert(fileURL)
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                
                // Check for quarantine attribute
                if let _ = resourceValues.quarantineProperties {
                    result.quarantinedFiles += 1
                }
                
                // Check iCloud status using resourceValues
                if scanICloud {
                    do {
                        let values = try fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                        if let status = values.ubiquitousItemDownloadingStatus, status == .notDownloaded {
                            result.iCloudFiles += 1
                        }
                    } catch {
                        // File might not be in iCloud, ignore error
                    }
                }
                
                // Check for executable
                if highlightExecutables && (resourceValues.isExecutable == true || isExecutableFileAtPath(fileURL.path)) {
                    result.executableFiles += 1
                }
                
                // Check for git directory
                if includeGitDirectories && fileURL.lastPathComponent == ".git" {
                    result.gitDirectories += 1
                }
                
                // File size and count
                if let fileSize = resourceValues.fileSize {
                    result.totalSize += Int64(fileSize)
                    result.totalFiles += 1
                    
                    // Categorize by path
                    let path = fileURL.path.lowercased()
                    if path.contains("caches") {
                        result.cacheFiles += 1
                        result.cacheSize += Int64(fileSize)
                    }
                    if path.contains("logs") || path.contains("log") {
                        result.logFiles += 1
                        result.logSize += Int64(fileSize)
                    }
                    if path.contains("application support") {
                        result.applicationSupportFiles += 1
                        result.appSupportSize += Int64(fileSize)
                    }
                    if path.contains("library") && !path.contains("caches") && !path.contains("logs") {
                        result.libraryFiles += 1
                        result.librarySize += Int64(fileSize)
                    }
                    if path.contains("tmp") || path.contains("temp") {
                        result.tempFiles += 1
                        result.tempSize += Int64(fileSize)
                    }
                    
                    // Collect file URLs for UI listing
                    await MainActor.run {
                        self.foundFiles.append(fileURL)
                    }
                }
            } catch {
                // Permission denied or other error
                result.permissionDeniedFiles += 1
                continue
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a file at the given path is executable by examining its POSIX permissions.
    private func isExecutableFileAtPath(_ path: String) -> Bool {
        let attrs = try? fileManager.attributesOfItem(atPath: path)
        if let permissions = attrs?[.posixPermissions] as? Int16 {
            return (permissions & 0o111) != 0
        }
        return false
    }
    
    /// Checks if a file at the given URL is executable.
    func isExecutable(file url: URL) -> Bool {
        return isExecutableFileAtPath(url.path)
    }
    
    // MARK: - Cancellation
    
    func cancelScanning() {
        cancelAllTasks = true
    }
    
    // MARK: - iCloud Controls (per file)
    
    /// Evicts an iCloud file from local storage (removes local copy, keeps in iCloud)
    func evictICloudFile(at url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try fileManager.evictUbiquitousItem(at: url)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Starts downloading an iCloud file from iCloud to local storage
    func downloadICloudFile(at url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try fileManager.startDownloadingUbiquitousItem(at: url)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Returns the current download status for an iCloud file.
    func iCloudDownloadStatus(for url: URL) -> URLUbiquitousItemDownloadingStatus? {
        do {
            let values = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            return values.ubiquitousItemDownloadingStatus
        } catch {
            return nil
        }
    }
    
    // MARK: - Multi-criteria Search
    
    /// Find files with similar names, extensions, or modification dates.
    /// - Parameters:
    ///   - targetURL: The reference file URL to compare against.
    ///   - maxResults: Maximum number of results to return.
    /// - Returns: Array of similar file URLs.
    func findSimilarFiles(to targetURL: URL, maxResults: Int = 20) -> [URL] {
        // This would need to search through foundFiles and compare name, extension, and modification date.
        // Implementation left as exercise.
        return []
    }
    
    // MARK: - Device Disk Space Check
    
    /// Returns available capacity on the volume containing the home directory.
    func availableDiskSpace() throws -> Int64? {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        return values.volumeAvailableCapacity.map { Int64($0) }
    }
    
    /// Returns total capacity on the volume containing the home directory.
    func totalDiskSpace() throws -> Int64? {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let values = try homeURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
        return values.volumeTotalCapacity.map { Int64($0) }
    }
}

// MARK: - Supporting Types

enum ScanCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case caches = "Caches"
    case logs = "Logs"
    case applications = "Applications"
    case documents = "Documents"
    case downloads = "Downloads"
    case executables = "Executables"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "folder"
        case .caches: return "tray.full"
        case .logs: return "doc.plaintext"
        case .applications: return "app"
        case .documents: return "doc"
        case .downloads: return "arrow.down.circle"
        case .executables: return "hammer"
        }
    }
    
    var color: String {
        switch self {
        case .all: return "blue"
        case .caches: return "orange"
        case .logs: return "gray"
        case .applications: return "purple"
        case .documents: return "blue"
        case .downloads: return "green"
        case .executables: return "red"
        }
    }
}
