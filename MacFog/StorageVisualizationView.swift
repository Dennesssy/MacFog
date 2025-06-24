//
//  StorageVisualizationView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

@available(macOS 11.0, *)
struct StorageVisualizationView: View {
    @StateObject private var storageManager = StorageManager()
    @State private var selectedCategory: String?
    @State private var visualizationType: VisualizationType = .pieChart
    
    enum VisualizationType {
        case pieChart
        case treeMap
        case list
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("DiskOptimizer Pro")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Visualization type picker
                Picker("Visualization", selection: $visualizationType) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .tag(VisualizationType.pieChart)
                    
                    Image(systemName: "square.grid.3x3.fill")
                        .tag(VisualizationType.treeMap)
                    
                    Image(systemName: "list.bullet")
                        .tag(VisualizationType.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                Button(action: {
                    storageManager.startScan()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Storage")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(storageManager.isScanning)
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.8))
            
            ZStack {
                // Main content
                VStack {
                    // Total storage info
                    if storageManager.totalSize > 0 {
                        Text("Total Storage: \(StorageManager.formatSize(storageManager.totalSize))")
                            .font(.headline)
                            .padding(.top)
                    }
                    
                    // Progress bar during scanning
                    if storageManager.isScanning {
                        VStack {
                            ProgressView(value: storageManager.scanProgress)
                                .progressViewStyle(.linear)
                                .padding()
                            
                            Text("Scanning storage...")
                                .foregroundColor(.secondary)
                            
                            Button("Cancel") {
                                storageManager.cancelScan()
                            }
                            .padding()
                        }
                        .frame(maxWidth: 400)
                        .padding()
                    } else if storageManager.totalSize > 0 {
                        // Visualization
                        Group {
                            switch visualizationType {
                            case .pieChart:
                                PieChartView(
                                    data: storageManager.categoryData,
                                    selectedCategory: selectedCategory,
                                    onSelectCategory: { category in
                                        selectedCategory = category
                                    }
                                )
                                .padding()
                                
                            case .treeMap:
                                TreeMapView(
                                    data: storageManager.categoryData,
                                    selectedCategory: selectedCategory,
                                    onSelectCategory: { category in
                                        selectedCategory = category
                                    }
                                )
                                .padding()
                                
                            case .list:
                                List {
                                    ForEach(storageManager.categoryData) { item in
                                        HStack {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 12, height: 12)
                                            
                                            Text(item.category)
                                            
                                            Spacer()
                                            
                                            Text(item.formattedSize)
                                                .foregroundColor(.secondary)
                                            
                                            Text(item.formattedPercentage)
                                                .foregroundColor(.secondary)
                                                .frame(width: 60, alignment: .trailing)
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedCategory = item.category
                                        }
                                        .background(item.category == selectedCategory ? Color.accentColor.opacity(0.1) : Color.clear)
                                    }
                                }
                                .listStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Category details and actions
                        if let selectedCategory = selectedCategory,
                           let selectedData = storageManager.categoryData.first(where: { $0.category == selectedCategory }) {
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(selectedData.category)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(selectedData.formattedSize)
                                        .font(.subheadline)
                                    
                                    Text(selectedData.formattedPercentage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Different actions depending on category
                                HStack {
                                    switch selectedData.category {
                                    case "System":
                                        SafetyIndicator(level: .protected)
                                        Text("System files are protected and cannot be modified")
                                            .foregroundColor(.secondary)
                                        
                                    case "Caches":
                                        Button("Clean Caches") {
                                            // This would be implemented in future phases
                                        }
                                        .buttonStyle(.borderedProminent)
                                        
                                    case "Applications":
                                        Button("View Large Apps") {
                                            // This would be implemented in future phases
                                        }
                                        .buttonStyle(.bordered)
                                        
                                    case "Duplicates":
                                        Button("Find Duplicates") {
                                            // This would be implemented in future phases
                                        }
                                        .buttonStyle(.borderedProminent)
                                        
                                    default:
                                        Button("Analyze") {
                                            // This would be implemented in future phases
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color(.windowBackgroundColor).opacity(0.8))
                        }
                    } else {
                        // Initial state or no data
                        VStack(spacing: 20) {
                            Image(systemName: "externaldrive.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.accentColor.opacity(0.8))
                            
                            Text("DiskOptimizer Pro")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Click 'Scan Storage' to analyze your disk")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                storageManager.startScan()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Scan Storage")
                                }
                                .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.top)
                        }
                        .padding()
                    }
                }
                
                // Error message
                if let errorMessage = storageManager.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.8))
                            )
                        
                        Button("Dismiss") {
                            storageManager.errorMessage = nil
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Supporting Views

@available(macOS 11.0, *)
struct PieChartView: View {
    var data: [StorageCategoryData]
    var selectedCategory: String?
    var onSelectCategory: (String) -> Void
    
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
                        onSelectCategory(data[index].category)
                    }
                    .onHover { hovering in
                        hoverIndex = hovering ? index : nil
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
}

@available(macOS 11.0, *)
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
                        .stroke(Color.white, lineWidth: isSelected || isHovered ? 3 : 1)
                )
                .shadow(color: .black.opacity(isSelected || isHovered ? 0.2 : 0), radius: 5)
            
            if rect.width > 80 && rect.height > 60 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: min(16, rect.width / 10)))
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(size)
                        .font(.system(size: min(14, rect.width / 12)))
                        .lineLimit(1)
                    
                    Text(percentage)
                        .font(.system(size: min(12, rect.width / 14)))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(8)
            }
        }
        .position(x: rect.midX, y: rect.midY)
        .frame(width: rect.width, height: rect.height)
        .scaleEffect(isSelected || isHovered ? 1.02 : 1.0)
        .zIndex(isSelected || isHovered ? 1 : 0)
        .animation(.spring(response: 0.3), value: isSelected || isHovered)
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

@available(macOS 11.0, *)
struct SafetyIndicator: View {
    enum SafetyLevel {
        case safe
        case caution
        case protected
    }
    
    let level: SafetyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var icon: String {
        switch level {
        case .safe:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .protected:
            return "lock.fill"
        }
    }
    
    private var color: Color {
        switch level {
        case .safe:
            return .green
        case .caution:
            return .yellow
        case .protected:
            return .red
        }
    }
    
    private var text: String {
        switch level {
        case .safe:
            return "Safe to Modify"
        case .caution:
            return "Caution"
        case .protected:
            return "Protected"
        }
    }
}

#Preview {
    if #available(macOS 11.0, *) {
        return StorageVisualizationView()
    } else {
        return Text("Requires macOS 11.0 or later")
    }
}
