//
//  StorageModels.swift
//  MacFog
//
//  Created on 4/3/25.
//

import Foundation
import SwiftUI

/// Data structure for storage category visualization
@available(macOS 11.0, *)
struct StorageCategoryData: Identifiable, Sendable {
    let id: UUID
    let category: String
    let size: Int64
    let percentage: Double
    let color: Color
    
    var formattedSize: String {
        Self.formatSize(size)
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
    
    /// Format a size in bytes to a human-readable string
    static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

/// Represents file statistics by category
@available(macOS 11.0, *)
struct FileStats: Sendable {
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
