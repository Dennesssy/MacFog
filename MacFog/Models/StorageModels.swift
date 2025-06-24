//
//  StorageModels.swift
//  MacFog
//
//  Created on 4/3/25.
//

import Foundation
import SwiftUI

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
