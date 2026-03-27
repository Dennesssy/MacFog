//
//  StorageVisualizationView.swift
//  MacFog
//
//  Created on 4/3/25.
//

import SwiftUI
import Charts

@available(macOS 14.0, *)
struct StorageVisualizationView: View {
    @StateObject private var storageManager = StorageManager()
    @State private var selectedNavItem: NavigationItem? = .dashboard

    // State for Native Delete Confirmation
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: String? = nil
    
    // State for file preview URL
    @State private var previewURL: URL?
    
    enum NavigationItem: String, Hashable, CaseIterable {
        case dashboard = "System Telemetry"
        case fileExplorer = "File Explorer"
        case devCaches = "Dev & Build Caches"
        case aiModels = "ML Weights & Datasets"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.xaxis"
            case .fileExplorer: return "folder.fill.badge.gearshape"
            case .devCaches: return "terminal.fill"
            case .aiModels: return "brain.head.profile"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, id: \.self, selection: $selectedNavItem) { item in
                Label {
                    Text(item.rawValue)
                        .font(.system(.body, design: .rounded))
                } icon: {
                    Image(systemName: item.icon)
                        .symbolRenderingMode(.multicolor)
                }
            }
            .navigationTitle("DiskOptimizer Pro")
            .listStyle(.sidebar)
        } detail: {
            Group {
                if storageManager.isScanning {
                    scanningState
                } else if storageManager.totalSize > 0 {
                    detailContent
                } else {
                    emptyState
                }
            }
            .navigationTitle(selectedNavItem?.rawValue ?? "DiskOptimizer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        storageManager.requestPermissionAndScan()
                    }) {
                        Label(storageManager.isScanning ? "Scanning..." : "Scan Storage", systemImage: "arrow.clockwise")
                            .symbolEffect(.pulse, isActive: storageManager.isScanning)
                    }
                    .disabled(storageManager.isScanning)
                }
            }
        }
        .frame(minWidth: 950, minHeight: 650)
        // Native HIG Confirmation Dialog
        .confirmationDialog(
            "Are you sure you want to delete \(itemToDelete ?? "these files")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Perform actual deletion here
                print("Deleted: \(itemToDelete ?? "")")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action will permanently remove the files from your disk and cannot be undone.")
        }
    }
    
    // MARK: - Detail Content Router

    @ViewBuilder
    private var detailContent: some View {
        switch selectedNavItem {
        case .dashboard:
            DashboardGridView(
                storageManager: storageManager,
                onDeleteRequest: triggerDelete
            )
        case .fileExplorer:
            AccordionFileListView(storageManager: storageManager, previewURL: $previewURL)
        case .devCaches, .aiModels:
            OptimizationTargetView(
                categoryTitle: selectedNavItem?.rawValue ?? "",
                onDeleteRequest: triggerDelete
            )
        case .none:
            ContentUnavailableView("Select a category", systemImage: "sidebar.left")
        }
    }
    
    private func triggerDelete(for itemName: String) {
        itemToDelete = itemName
        showingDeleteConfirmation = true
    }
    
    // MARK: - States
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Ready to Optimize", systemImage: "cpu.fill")
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.bounce, options: .repeating)
        } description: {
            Text("Analyze your storage to visualize your disk and reclaim space for new AI models and dev builds.")
                .font(.system(.body, design: .rounded))
        } actions: {
            Button("Initialize Analysis") {
                storageManager.requestPermissionAndScan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.system(.body, design: .monospaced).weight(.semibold))
        }
    }
    
    private var scanningState: some View {
        VStack(spacing: 24) {
            ProgressView(value: storageManager.scanProgress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 350)
                .tint(.blue)
            
            VStack(spacing: 8) {
                Text("Analyzing File System Matrix...")
                    .font(.system(.title3, design: .monospaced).weight(.medium))
                
                Text("\(Int(storageManager.scanProgress * 100))% Compiled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            Button("Abort Task", role: .cancel) {
                storageManager.cancelScan()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .font(.system(.body, design: .monospaced))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Dashboard Grid with Native Charts

@available(macOS 14.0, *)
private struct DashboardGridView: View {
    @ObservedObject var storageManager: StorageManager
    let onDeleteRequest: (String) -> Void
    
    let columns = [
        GridItem(.adaptive(minimum: 340, maximum: 460), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                HStack(alignment: .lastTextBaseline) {
                    Text("System Telemetry")
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Spacer()
                    Text("Utilized Disk: \(StorageManager.formatSize(storageManager.totalSize))")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    
                    // 1. Pie Chart
                    DashboardCard(title: "Allocation Graph", icon: "chart.pie.fill", color: .blue) {
                        Chart(storageManager.categoryData) { item in
                            SectorMark(
                                angle: .value("Size", item.size),
                                innerRadius: .ratio(0.6),
                                angularInset: 2.0
                            )
                            .foregroundStyle(item.color.gradient)
                            .cornerRadius(6)
                        }
                        .chartLegend(position: .trailing, alignment: .center)
                        .padding(.top, 8)
                    }
                    
                    // 2. Bar Chart
                    DashboardCard(title: "Largest Vectors", icon: "chart.bar.fill", color: .purple) {
                        Chart(storageManager.categoryData.prefix(5)) { item in
                            BarMark(
                                x: .value("Size", item.size),
                                y: .value("Category", item.category)
                            )
                            .foregroundStyle(item.color.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis(.hidden)
                        .padding(.top, 8)
                    }
                    
                    // 3. Category Breakdown List
                    DashboardCard(title: "Raw Data Breakdown", icon: "server.rack", color: .orange) {
                        List {
                            ForEach(storageManager.categoryData.prefix(4)) { item in
                                HStack {
                                    Circle()
                                        .fill(item.color.gradient)
                                        .frame(width: 10, height: 10)
                                    Text(item.category)
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Text(StorageManager.formatSize(item.size))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .padding(.horizontal, -16)
                    }
                    
                    // 4. Action Center
                    DashboardCard(title: "Execution Node", icon: "terminal.fill", color: .green) {
                        VStack(spacing: 12) {
                            Button { 
                                onDeleteRequest("Node Modules & Derived Data")
                            } label: { 
                                Label("Purge Build Caches", systemImage: "hammer.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.large)
                            
                            Button { 
                                onDeleteRequest("Orphaned HuggingFace Models")
                            } label: { 
                                Label("Prune Local LLM Weights", systemImage: "brain")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.large)
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Modern Dashboard Card

@available(macOS 14.0, *)
private struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color.gradient)
                    .font(.title3)
                Text(title)
                    .font(.system(.headline, design: .rounded))
            }
            .padding(.bottom, 16)
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
        .frame(height: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

// MARK: - Accordion File List (Native Outline)

@available(macOS 14.0, *)
private struct AccordionFileListView: View {
    @ObservedObject var storageManager: StorageManager
    @Binding var previewURL: URL?
    @State private var selection: String?
    
    // Mock file data with actual paths
    private var mockFiles: [MockFileItem] {
        [
            MockFileItem(name: "core_ml_model_v4.mlmodel", size: "2.4 GB", icon: "cube.fill", color: .purple, path: "~/Library/Mobile Documents/com~apple~CloudDocs/core_ml_model_v4.mlmodel"),
            MockFileItem(name: "xcode_derived_data", size: "14.2 GB", icon: "hammer.fill", color: .blue, path: "~/Library/Developer/Xcode/DerivedData"),
            MockFileItem(name: "huggingface_cache", size: "8.1 GB", icon: "brain", color: .orange, path: "~/.cache/huggingface"),
            MockFileItem(name: "npm_cache", size: "1.2 GB", icon: "shippingbox.fill", color: .green, path: "~/.npm")
        ]
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(storageManager.categoryData, id: \.category) { item in
                DisclosureGroup {
                    ForEach(mockFiles) { file in
                        FileRow(
                            name: file.name,
                            size: file.size,
                            icon: file.icon,
                            color: file.color,
                            filePath: file.path,
                            previewURL: $previewURL
                        )
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.title3)

                        Text(item.category)
                            .font(.system(.body, design: .rounded).weight(.medium))
                        Spacer()
                        Text(StorageManager.formatSize(item.size))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .alternatingRowBackgrounds()
        .navigationTitle("File Explorer")
    }
}

private struct MockFileItem: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let icon: String
    let color: Color
    let path: String
}

private struct FileRow: View {
    let name: String
    let size: String
    let icon: String
    let color: Color
    let filePath: String
    @Binding var previewURL: URL?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color.gradient)
                .frame(width: 20)

            Text(name)
                .font(.system(.body, design: .monospaced))

            Spacer()

            Text(size)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.leading, 8)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            // Update previewURL with the file's path on disk
            let expandedPath = NSString(string: filePath).expandingTildeInPath
            previewURL = URL(fileURLWithPath: expandedPath)
        }
    }
}

// MARK: - Dedicated Deep Clean View

@available(macOS 14.0, *)
private struct OptimizationTargetView: View {
    let categoryTitle: String
    let onDeleteRequest: (String) -> Void
    
    var body: some View {
        Form {
            Section("Safe to Prune") {
                CleanTargetRow(
                    title: "Xcode Derived Data",
                    size: "14.2 GB",
                    icon: "hammer.fill",
                    onDelete: { onDeleteRequest("Xcode Derived Data") }
                )
                
                CleanTargetRow(
                    title: "Node Modules (Global)",
                    size: "3.1 GB",
                    icon: "shippingbox.fill",
                    onDelete: { onDeleteRequest("Node Modules (Global)") }
                )
            }
            
            Section("AI & ML Datasets") {
                CleanTargetRow(
                    title: "HuggingFace Hub Cache",
                    size: "22.5 GB",
                    icon: "brain.head.profile",
                    onDelete: { onDeleteRequest("HuggingFace Hub Cache") }
                )
                
                CleanTargetRow(
                    title: "Ollama Local Weights",
                    size: "18.4 GB",
                    icon: "server.rack",
                    onDelete: { onDeleteRequest("Ollama Local Weights") }
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle(categoryTitle)
    }
}

private struct CleanTargetRow: View {
    let title: String
    let size: String
    let icon: String
    let onDelete: () -> Void
    
    var body: some View {
        LabeledContent {
            Button("Purge", role: .destructive, action: onDelete)
                .buttonStyle(.bordered)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .symbolRenderingMode(.multicolor)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(.body, design: .rounded))
                    Text(size)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
