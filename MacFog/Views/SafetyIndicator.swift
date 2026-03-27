//
//  SafetyIndicator.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

/// Represents different safety levels for file operations
enum SafetyLevel {
    case protected    // System files that should not be modified
    case safe         // Files that are safe to modify/delete
    case caution      // Files that can be modified but require caution
    case unknown      // Files with unknown safety status
}

/// A visual indicator that shows the safety level of a file or operation
struct SafetyIndicator: View {
    let level: SafetyLevel

    var body: some View {
        HStack(spacing: 8) {
            // Safety icon
            icon
                .font(.system(size: 16))
                .frame(width: 20, height: 20)

            // Safety level text
            Text(levelText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(foregroundColor.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var icon: some View {
        switch level {
        case .protected:
            Image(systemName: "lock.shield.fill")
        case .safe:
            Image(systemName: "checkmark.shield.fill")
        case .caution:
            Image(systemName: "exclamationmark.triangle.fill")
        case .unknown:
            Image(systemName: "questionmark.diamond.fill")
        }
    }

    private var levelText: String {
        switch level {
        case .protected: return "Protected"
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .unknown: return "Unknown"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .protected: return Color.red.opacity(0.15)
        case .safe: return Color.green.opacity(0.15)
        case .caution: return Color.orange.opacity(0.15)
        case .unknown: return Color.gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch level {
        case .protected: return .red
        case .safe: return .green
        case .caution: return .orange
        case .unknown: return .secondary
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 16) {
        SafetyIndicator(level: .protected)
        SafetyIndicator(level: .safe)
        SafetyIndicator(level: .caution)
        SafetyIndicator(level: .unknown)
    }
    .padding()
}
