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
            // Liquid Glass Toolbar
            HStack {
                Text("DiskOptimizer Pro")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Liquid Glass Visualization Picker
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
                .glassEffectConditional()
                
                // Liquid Glass Scan Button
                Button(action: {
                    storageManager.requestPermissionAndScan()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .symbolEffect(.rotate, isActive: storageManager.isScanning)
                        Text("Scan Storage")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .disabled(storageManager.isScanning)
                .scaleEffect(storageManager.isScanning ? 0.95 : 1.0)
                .animation(.bouncy, value: storageManager.isScanning)
                .glassEffectConditional()
            }
            .padding()
            .background(.ultraThinMaterial)
            .glassEffectConditional()
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            ZStack {
                // Main content
                VStack {
                    // Total storage info
                    if storageManager.totalSize > 0 {
                        Text("Total Storage: \(StorageManager.formatSize(storageManager.totalSize))")
                            .font(.headline)
                            .padding(.top)
                    }
                    
                    // Liquid Glass Progress Container
                    if storageManager.isScanning {
                        VStack(spacing: 16) {
                            ProgressView(value: storageManager.scanProgress)
                                .progressViewStyle(.linear)
                                .tint(.cyan)
                                .scaleEffect(y: 2)
                                .padding(.horizontal)
                            
                            Text("Scanning storage...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(Int(storageManager.scanProgress * 100))% Complete")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Button("Cancel") {
                                storageManager.cancelScan()
                            }
                            .glassEffectConditional()
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(.regularMaterial)
                        .glassEffectConditional()
                        .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 10)
                        .frame(maxWidth: 400)
                        .scaleEffect(1.05)
                        .animation(.bouncy, value: storageManager.scanProgress)
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
                        
                        // Liquid Glass Category Details Panel
                        if let selectedCategory = selectedCategory,
                           let selectedData = storageManager.categoryData.first(where: { $0.category == selectedCategory }) {
                            
                            VStack(alignment: .leading, spacing: 20) {
                                // Category Header with Liquid Glass
                                HStack {
                                    Circle()
                                        .fill(selectedData.color)
                                        .frame(width: 16, height: 16)
                                        .shadow(color: selectedData.color, radius: 4)
                                    
                                    Text(selectedData.category)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(selectedData.formattedSize)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text(selectedData.formattedPercentage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.ultraThinMaterial)
                                            .glassEffectConditional()
                                    }
                                }
                                
                                // Action Buttons with Liquid Glass
                                HStack(spacing: 12) {
                                    switch selectedData.category {
                                    case "System":
                                        SafetyIndicator(level: .protected)
                                        Text("System files are protected and cannot be modified")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                    case "Caches":
                                        Button("Clean Caches") {
                                            // Implementation placeholder
                                        }
                                        .glassEffectConditional()
                                        .tint(.green)
                                        
                                    case "Applications":
                                        Button("View Large Apps") {
                                            // Implementation placeholder
                                        }
                                        .glassEffectConditional()
                                        
                                    case "Duplicates":
                                        Button("Find Duplicates") {
                                            // Implementation placeholder
                                        }
                                        .glassEffectConditional()
                                        .tint(.orange)
                                        
                                    default:
                                        Button("Analyze") {
                                            // Implementation placeholder
                                        }
                                        .glassEffectConditional()
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(20)
                            .background(.regularMaterial)
                            .glassEffectConditional()
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                    } else {
                        // Liquid Glass Welcome State
                        VStack(spacing: 32) {
                            VStack(spacing: 16) {
                                Image(systemName: "externaldrive.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.cyan)
                                    .symbolEffect(.pulse, options: .repeat(.continuous))
                                    .shadow(color: .cyan.opacity(0.5), radius: 20)
                                
                                Text("DiskOptimizer Pro")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text("Unleash the power of Liquid Glass storage visualization")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(32)
                            .background(.ultraThinMaterial)
                            .glassEffectConditional()
                            .shadow(color: .cyan.opacity(0.2), radius: 30, x: 0, y: 15)
                            
                            Button(action: {
                                storageManager.requestPermissionAndScan()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                    Text("Begin Analysis")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                            .tint(.cyan)
                            .controlSize(.large)
                            .shadow(color: .cyan.opacity(0.3), radius: 15, x: 0, y: 8)
                            .scaleEffect(1.1)
                            .glassEffectConditional()
                        }
                        .padding(40)
                    }
                }
                
                // Liquid Glass Error Panel
                if let errorMessage = storageManager.errorMessage {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                            
                            Text("Error Occurred")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Button("Dismiss") {
                            withAnimation(.bouncy) {
                                storageManager.errorMessage = nil
                            }
                        }
                        .glassEffectConditional()
                        .tint(.orange)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .glassEffectConditional()
                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity.combined(with: .scale)),
                        removal: .move(edge: .top).combined(with: .opacity.combined(with: .scale))
                    ))
                    .zIndex(100)
                    .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Supporting Views


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
