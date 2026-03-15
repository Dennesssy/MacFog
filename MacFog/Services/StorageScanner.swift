// New: StorageScanner.swift
@MainActor
class StorageScanner: ObservableObject {
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var fileStats: FileStats = FileStats()
    
    private let fileManager = FileManager.default
    
    func scanFileSystem() async throws -> FileStats {
        // Unified scanning logic combining best parts of both services
        // Use proper progress tracking with file counts
    }
}
