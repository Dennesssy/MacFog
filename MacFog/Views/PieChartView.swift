//
//  PieChartView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

// Import StorageModels for StorageCategoryData
@_exported import class Foundation.ByteCountFormatter

@available(macOS 11.0, *)

struct PieChartView: View {
    var data: [StorageCategoryData]
    var selectedCategory: String?
    var onSelectCategory: (String) -> Void
    
    @State private var activeIndex: Int?
    @State private var hoverIndex: Int?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pie Chart
                ZStack {
                    ForEach(data.indices, id: \.self) { index in
                        PieSlice(
                            startAngle: .degrees(startAngle(for: index)),
                            endAngle: .degrees(endAngle(for: index))
                        )
                        .fill(sliceColor(at: index))
                        .scaleEffect(isActive(at: index) ? 1.05 : 1.0)
                        .shadow(color: .black.opacity(isActive(at: index) ? 0.1 : 0), radius: 5)
                        .animation(.spring(response: 0.3), value: isActive(at: index))
                        .onTapGesture {
                            onSelectCategory(data[index].category)
                        }
                        .onHover { hovering in
                            hoverIndex = hovering ? index : nil
                        }
                    }
                }
                .frame(width: min(geometry.size.width, geometry.size.height) * 0.8,
                       height: min(geometry.size.width, geometry.size.height) * 0.8)
                
                // Center circle (white space)
                Circle()
                    .fill(Color(.windowBackgroundColor))
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.4)
                
                // Selected category info
                if let selectedCategory = selectedCategory,
                   let selectedIndex = data.firstIndex(where: { $0.category == selectedCategory }) {
                    VStack(spacing: 4) {
                        Text(data[selectedIndex].category)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(data[selectedIndex].formattedSize)
                            .font(.subheadline)
                        
                        Text(data[selectedIndex].formattedPercentage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.35)
                    .multilineTextAlignment(.center)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func isActive(at index: Int) -> Bool {
        if let selectedCategory = selectedCategory {
            return data[index].category == selectedCategory
        }
        return hoverIndex == index
    }
    
    private func sliceColor(at index: Int) -> Color {
        if isActive(at: index) {
            return data[index].color.opacity(0.8)
        }
        return data[index].color.opacity(0.6)
    }
    
    private func startAngle(for index: Int) -> Double {
        let preceedingRatios = data.prefix(index).map { $0.percentage }
        let ratio = preceedingRatios.reduce(0.0, +)
        return ratio * 360.0
    }
    
    private func endAngle(for index: Int) -> Double {
        let preceedingRatios = data.prefix(index + 1).map { $0.percentage }
        let ratio = preceedingRatios.reduce(0.0, +)
        return ratio * 360.0
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false)
        path.closeSubpath()
        
        return path
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
    
    return PieChartView(
        data: mockData,
        selectedCategory: "System",
        onSelectCategory: { _ in }
    )
    .frame(width: 300, height: 300)
    .padding()
}
