//
//  PieChartView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

// PieChartView implementation

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
                        .overlay(
                            // Liquid glass overlay for active slices
                            PieSlice(
                                startAngle: .degrees(startAngle(for: index)),
                                endAngle: .degrees(endAngle(for: index))
                            )
                            .fill(.ultraThinMaterial)
                            .opacity(isActive(at: index) ? 0.8 : 0)
                            .glassEffect(.regular)
                        )
                        .scaleEffect(isActive(at: index) ? 1.08 : 1.0)
                        .shadow(
                            color: isActive(at: index) ? data[index].color.opacity(0.4) : .clear,
                            radius: isActive(at: index) ? 15 : 0,
                            x: 0,
                            y: isActive(at: index) ? 8 : 0
                        )
                        .animation(.bouncy(duration: 0.4), value: isActive(at: index))
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
                .frame(width: min(geometry.size.width, geometry.size.height) * 0.8,
                       height: min(geometry.size.width, geometry.size.height) * 0.8)
                
                // Liquid Glass Center Circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.prominent, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.4)
                
                // Liquid Glass Selected Category Info
                if let selectedCategory = selectedCategory,
                   let selectedIndex = data.firstIndex(where: { $0.category == selectedCategory }) {
                    VStack(spacing: 8) {
                        // Category indicator with glass effect
                        HStack(spacing: 8) {
                            Circle()
                                .fill(data[selectedIndex].color)
                                .frame(width: 12, height: 12)
                                .shadow(color: data[selectedIndex].color, radius: 6)
                            
                            Text(data[selectedIndex].category)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .glassEffect(.regular, in: Capsule())
                        
                        Text(data[selectedIndex].formattedSize)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(data[selectedIndex].formattedPercentage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.regularMaterial)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.35)
                    .multilineTextAlignment(.center)
                    .scaleEffect(1.1)
                    .animation(.bouncy, value: selectedCategory)
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
        let precedingRatios = data.prefix(index).map { $0.percentage }
        let ratio = precedingRatios.reduce(0.0, +)
        return ratio * 360.0
    }
    
    private func endAngle(for index: Int) -> Double {
        let precedingRatios = data.prefix(index + 1).map { $0.percentage }
        let ratio = precedingRatios.reduce(0.0, +)
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
