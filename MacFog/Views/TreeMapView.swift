//
//  TreeMapView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

// TreeMapView implementation

@available(macOS 11.0, *)

struct TreeMapView: View {
    var data: [StorageCategoryData]
    var selectedCategory: String?
    var onSelectCategory: (String) -> Void
    
    @State private var hoverIndex: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let layout = TreeMapLayout(size: geometry.size, data: data)
            
            ZStack(alignment: .topLeading) {
                // Liquid Glass Container Background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                ForEach(data.indices, id: \.self) { index in
                    let rect = layout.rectFor(index: index)
                    
                    TreeMapCell(
                        title: data[index].category,
                        size: data[index].formattedSize,
                        percentage: data[index].formattedPercentage,
                        rect: rect,
                        color: data[index].color,
                        isSelected: data[index].category == selectedCategory,
                        isHovered: hoverIndex == index
                    )
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            onSelectCategory(data[index].category)
                        }
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoverIndex = hovering ? index : nil
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .padding(8)
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
}

struct TreeMapCell: View {
    let title: String
    let size: String
    let percentage: String
    let rect: CGRect
    let color: Color
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(color.opacity(0.6))
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(isSelected || isHovered ? 0.9 : 0.3)
                        .glassEffect(.regular)
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.8), lineWidth: isSelected || isHovered ? 3 : 1)
                        .shadow(color: color.opacity(0.6), radius: isSelected || isHovered ? 8 : 0)
                )
                .shadow(color: .black.opacity(isSelected || isHovered ? 0.3 : 0.1), radius: isSelected || isHovered ? 15 : 5, x: 0, y: isSelected || isHovered ? 8 : 2)
            
            if rect.width > 80 && rect.height > 60 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: min(16, rect.width / 10)))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .shadow(color: .white.opacity(0.8), radius: 1)
                    
                    Text(size)
                        .font(.system(size: min(14, rect.width / 12)))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text(percentage)
                            .font(.system(size: min(12, rect.width / 14)))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.regularMaterial)
                            .glassEffect(.regular, in: Capsule())
                        
                        Spacer()
                    }
                }
                .padding(8)
            }
        }
        .position(x: rect.midX, y: rect.midY)
        .frame(width: rect.width, height: rect.height)
        .scaleEffect(isSelected || isHovered ? 1.05 : 1.0)
        .zIndex(isSelected || isHovered ? 1 : 0)
        .animation(.bouncy(duration: 0.4), value: isSelected || isHovered)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// Layout algorithm for treemap visualization
struct TreeMapLayout {
    let size: CGSize
    let data: [StorageCategoryData]
    
    func rectFor(index: Int) -> CGRect {
        guard !data.isEmpty else { return .zero }
        
        // Calculate relative sizes
        let totalSize = data.reduce(0) { $0 + $1.size }
        let relativeSizes = data.map { CGFloat($0.size) / CGFloat(totalSize) }
        
        // Create initial rectangle (full size)
        let initialRect = CGRect(origin: .zero, size: size)
        
        // Calculate rectangles for each item
        let rects = squarify(relativeSizes: relativeSizes, container: initialRect)
        
        return index < rects.count ? rects[index] : .zero
    }
    
    /// Squarify algorithm for treemap layout
    private func squarify(relativeSizes: [CGFloat], container: CGRect) -> [CGRect] {
        // Basic square packing algorithm
        var result: [CGRect] = []
        var remainingRect = container
        
        for relativeSize in relativeSizes {
            let area = relativeSize * container.width * container.height
            
            if remainingRect.width >= remainingRect.height {
                // Split horizontally
                let width = area / remainingRect.height
                let rect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: width,
                    height: remainingRect.height
                )
                result.append(rect)
                
                // Update remaining rectangle
                remainingRect = CGRect(
                    x: remainingRect.minX + width,
                    y: remainingRect.minY,
                    width: remainingRect.width - width,
                    height: remainingRect.height
                )
            } else {
                // Split vertically
                let height = area / remainingRect.width
                let rect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: remainingRect.width,
                    height: height
                )
                result.append(rect)
                
                // Update remaining rectangle
                remainingRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY + height,
                    width: remainingRect.width,
                    height: remainingRect.height - height
                )
            }
        }
        
        return result
    }
}

#Preview {
    let mockData = [
        StorageCategoryData(id: UUID(), category: "System", size: 15_000_000_000, percentage: 0.3, color: .blue),
        StorageCategoryData(id: UUID(), category: "Applications", size: 10_000_000_000, percentage: 0.2, color: .green),
        StorageCategoryData(id: UUID(), category: "User Documents", size: 8_000_000_000, percentage: 0.16, color: .orange),
        StorageCategoryData(id: UUID(), category: "Media", size: 12_000_000_000, percentage: 0.24, color: .red),
        StorageCategoryData(id: UUID(), category: "Other", size: 5_000_000_000, percentage: 0.1, color: .gray)
    ]
    
    TreeMapView(
        data: mockData,
        selectedCategory: "System",
        onSelectCategory: { _ in }
    )
    .frame(width: 600, height: 400)
    .padding()
}
