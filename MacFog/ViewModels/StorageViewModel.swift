//
//  StorageViewModel.swift
//  MacFog
//
//  Created on 4/3/25.
//

import Foundation
import Combine
import SwiftUI

@available(macOS 11.0, *)
class StorageViewModel: ObservableObject {
    private let fileSystemService = FileSystemService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalSize: Int64 = 0
    @Published var categoryData: [StorageCategoryData] = []
    @Published var errorMessage: String?
    
    init() {
        // Bind to the file system service
        fileSystemService.$isScanning
            .assign(to: &$isScanning)
        
        fileSystemService.$scanProgress
            .assign(to: &$scanProgress)
        
        fileSystemService.$totalSize
            .assign(to: &$totalSize)
        
        fileSystemService.$fileStats
            .map { stats -> [StorageCategoryData] in
                self.createCategoryData(from: stats)
            }
            .assign(to: &$categoryData)
    }
    
    /// Start scanning the file system
    func startScan() {
        Task {
            do {
                _ = try await fileSystemService.scanFileSystem()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Cancel an ongoing scan
    func cancelScan() {
        fileSystemService.cancelScan()
    }
    
    /// Format a size in bytes to a human-readable string
    func formatSize(_ bytes: Int64) -> String {
        FileSystemService.formatSize(bytes)
    }
    
    /// Create category data from file stats for visualization
    private func createCategoryData(from stats: FileSystemService.FileStats) -> [StorageCategoryData] {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow, .gray]
        
        var result: [StorageCategoryData] = []
        var colorIndex = 0
        
        for (category, size) in stats.categories {
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
        return result.sorted { $0.size > $1.size }
    }
}

/// Data structure for storage category visualization
struct StorageCategoryData: Identifiable {
    let id: UUID
    let category: String
    let size: Int64
    let percentage: Double
    let color: Color
    
    var formattedSize: String {
        FileSystemService.formatSize(size)
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
}
