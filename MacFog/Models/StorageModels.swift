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
public struct StorageCategoryData: Identifiable, Sendable {
    public let id: UUID
    public let category: String
    public let size: Int64
    public let percentage: Double
    public let color: Color
    
    public var formattedSize: String {
        Self.formatSize(size)
    }
    
    public var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
    
    /// Format a size in bytes to a human-readable string
    public static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

/// Represents file statistics by category
@available(macOS 11.0, *)
public struct FileStats: Sendable {
    public var system: Int64 = 0
    public var applications: Int64 = 0
    public var userDocuments: Int64 = 0
    public var media: Int64 = 0
    public var caches: Int64 = 0
    public var duplicates: Int64 = 0
    public var other: Int64 = 0
    
    public var categories: [String: Int64] {
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
