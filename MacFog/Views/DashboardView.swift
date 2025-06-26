//
//  DashboardView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = StorageViewModel()
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
                    viewModel.startScan()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Storage")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning)
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.8))
            
            ZStack {
                // Main content
                VStack {
                    // Total storage info
                    if viewModel.totalSize > 0 {
                        Text("Total Storage: \(viewModel.formatSize(viewModel.totalSize))")
                            .font(.headline)
                            .padding(.top)
                    }
                    
                    // Progress bar during scanning
                    if viewModel.isScanning {
                        VStack {
                            ProgressView(value: viewModel.scanProgress)
                                .progressViewStyle(.linear)
                                .padding()
                            
                            Text("Scanning storage...")
                                .foregroundColor(.secondary)
                            
                            Button("Cancel") {
                                viewModel.cancelScan()
                            }
                            .padding()
                        }
                        .frame(maxWidth: 400)
                        .padding()
                    } else if viewModel.totalSize > 0 {
                        // Visualization
                        Group {
                            switch visualizationType {
                            case .pieChart:
                                PieChartView(
                                    data: viewModel.categoryData,
                                    selectedCategory: selectedCategory,
                                    onSelectCategory: { category in
                                        selectedCategory = category
                                    }
                                )
                                .padding()
                                
                            case .treeMap:
                                TreeMapView(
                                    data: viewModel.categoryData,
                                    selectedCategory: selectedCategory,
                                    onSelectCategory: { category in
                                        selectedCategory = category
                                    }
                                )
                                .padding()
                                
                            case .list:
                                List {
                                    ForEach(viewModel.categoryData) { item in
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
                           let selectedData = viewModel.categoryData.first(where: { $0.category == selectedCategory }) {
                            
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
                                viewModel.startScan()
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
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.8))
                            )
                        
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
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


#Preview {
    DashboardView()
}
