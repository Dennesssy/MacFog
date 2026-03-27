import SwiftUI
import UniformTypeIdentifiers

struct StorageScannerView: View {
    @StateObject private var scanner = StorageScanner()
    @State private var showingICloudSheet = false
    @State private var selectedFiles: Set<URL> = []
    @State private var dragOver = false
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .searchable(text: $scanner.searchText, prompt: "Search files")
        .sheet(isPresented: $showingICloudSheet) {
            if let file = scanner.selectedFile {
                ICloudControlsSheet(scanner: scanner, file: file)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .alert("Scan Complete", isPresented: Binding(
            get: { !scanner.isScanning && scanner.scanProgress == 1.0 && scanner.totalSize > 0 },
            set: { _ in }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Found \(scanner.fileStats.totalFiles.formatted()) files totaling \(scanner.fileStats.sizeInGigabytes.formatted(.number.precision(.fractionLength(2)))) GB")
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $scanner.selectedFile) {
            Section {
                if scanner.isScanning {
                    scanningSection
                } else if scanner.foundFiles.isEmpty {
                    emptyStateSection
                } else {
                    fileResultsSection
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Storage Scanner")
        .navigationSubtitle(subtitle)
        .toolbar {
            ToolbarItemGroup {
                ToolbarItems(
                    scanner: scanner,
                    showingSettings: $showingSettings,
                    startScan: startScan
                )
            }
        }
        .overlay {
            if dragOver {
                DropIndicatorView()
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
            handleDrop(providers: providers)
        }
    }

    private var subtitle: String {
        if scanner.isScanning {
            return "Scanning..."
        } else if !scanner.foundFiles.isEmpty {
            return "\(scanner.foundFiles.count.formatted()) items • \(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))"
        }
        return "No files scanned"
    }

    @ViewBuilder
    private var scanningSection: some View {
        Section("Scanning") {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: scanner.scanProgress) {
                    Text("Analyzing storage...")
                        .font(.headline)
                } currentValueLabel: {
                    Text("\(Int(scanner.scanProgress * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)

                Button("Cancel") {
                    scanner.cancelScanning()
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    Text("No Files Found")
                        .font(.headline)
                    Text("Start a scan to discover files on your Mac")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    startScan()
                } label: {
                    Label("Start Scan", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var fileResultsSection: some View {
        Group {
            Section {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ScanCategory.allCases) { category in
                            CategoryFilterChip(
                                category: category,
                                isSelected: scanner.selectedCategory == category,
                                action: { scanner.selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
            }

            Section("Results") {
                ForEach(filteredFiles, id: \.self) { file in
                    FileListItem(
                        url: file,
                        scanner: scanner,
                        isSelected: scanner.selectedFile == file
                    )
                    .contextMenu {
                        FileContextMenu(
                            file: file,
                            scanner: scanner
                        )
                    }
                }
            }
        }
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailContent: some View {
        if let file = scanner.selectedFile {
            FileInspectorView(file: file, scanner: scanner)
        } else {
            ContentUnavailableView {
                Label("Select a File", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("Choose a file from the sidebar to view its details")
            }
        }
    }

    // MARK: - Actions

    private func startScan() {
        Task { try? await scanner.scanFileSystem() }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil),
                       let url = item as? URL {
                        await MainActor.run {
                            scanner.foundFiles.append(url)
                        }
                    }
                }
            }
        }
        return true
    }

    // MARK: - Filtered Files

    private var filteredFiles: [URL] {
        let searchLower = scanner.searchText.lowercased()
        return scanner.foundFiles.filter { file in
            if !searchLower.isEmpty && !file.lastPathComponent.lowercased().contains(searchLower) {
                return false
            }

            switch scanner.selectedCategory {
            case .all: return true
            case .caches: return file.path.lowercased().contains("caches")
            case .logs: return file.path.lowercased().contains("logs") || file.path.lowercased().contains("log")
            case .applications: return file.pathExtension == "app"
            case .documents: return file.path.contains("Documents") || file.path.contains("application support")
            case .downloads: return file.path.contains("Downloads")
            case .executables: return scanner.isExecutable(file: file)
            }
        }
    }
}

// MARK: - Toolbar Items

private struct ToolbarItems: View {
    let scanner: StorageScanner
    @Binding var showingSettings: Bool
    let startScan: () -> Void

    var body: some View {
        Button {
            showingSettings = true
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
        .help("Scan Settings")

        Button {
            // Show iCloud controls for selected file
        } label: {
            Label("iCloud", systemImage: "icloud")
        }
        .disabled(!scanner.scanICloud || scanner.selectedFile == nil)
        .help("iCloud Controls")

        Button {
            startScan()
        } label: {
            if scanner.isScanning {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Label("Scan", systemImage: "arrow.clockwise")
            }
        }
        .help(scanner.isScanning ? "Scanning..." : "Start Scan")
    }
}

// MARK: - Category Filter Chip

private struct CategoryFilterChip: View {
    let category: ScanCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.rawValue, systemImage: category.icon)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - File List Item

private struct FileListItem: View {
    let url: URL
    let scanner: StorageScanner
    let isSelected: Bool

    private let fileManager = FileManager.default

    var body: some View {
        HStack(spacing: 12) {
            FileIconView(url: url, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(fileSizeString)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(modificationString)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            fileBadges
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var fileBadges: some View {
        HStack(spacing: 4) {
            if scanner.highlightExecutables && scanner.isExecutable(file: url) {
                Image(systemName: "terminal.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .help("Executable")
            }

            if scanner.scanICloud && isICloudFile {
                Image(systemName: "icloud.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .help("Stored in iCloud")
            }
        }
    }

    private var isICloudFile: Bool {
        (try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]))?.ubiquitousItemDownloadingStatus == .notDownloaded
    }

    private var fileSizeString: String {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else {
            return "Unknown size"
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private var modificationString: String {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date else {
            return "Unknown date"
        }
        return date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }
}

// MARK: - File Icon View

struct FileIconView: View {
    let url: URL
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size * 0.6))
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(iconColor.opacity(0.15))
            )
    }

    private var iconName: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "app": return "app.fill"
        case "pdf": return "doc.richtext.fill"
        case "swift": return "swift"
        case "zip", "dmg", "tar", "gz": return "doc.zipper"
        case "jpg", "png", "gif", "heic": return "photo.fill"
        case "mp3", "wav", "m4a": return "music.note"
        case "mp4", "mov", "avi": return "video.fill"
        case "log", "txt": return "doc.plaintext.fill"
        case "json", "plist", "xml": return "doc.badge.gearshape"
        case "h", "m", "mm", "c", "cpp": return "chevron.left.forwardslash.chevron.right"
        case "xcodeproj", "xcworkspace": return "hammer.fill"
        default: return url.hasDirectoryPath ? "folder.fill" : "doc.fill"
        }
    }

    private var iconColor: Color {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "app": return .purple
        case "pdf": return .red
        case "swift": return .orange
        case "zip", "dmg", "tar", "gz": return .brown
        case "jpg", "png", "gif", "heic": return .green
        case "mp3", "wav", "m4a": return .pink
        case "mp4", "mov", "avi": return .blue
        case "json", "plist", "xml": return .cyan
        case "h", "m", "mm", "c", "cpp": return .blue
        case "xcodeproj", "xcworkspace": return .blue
        default: return .secondary
        }
    }
}

// MARK: - File Context Menu

private struct FileContextMenu: View {
    let file: URL
    let scanner: StorageScanner

    var body: some View {
        Group {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([file])
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(file.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "link")
            }

            if scanner.scanICloud {
                Divider()

                Button {
                    Task { try? await scanner.downloadICloudFile(at: file) }
                } label: {
                    Label("Download from iCloud", systemImage: "icloud.and.arrow.down")
                }

                Button {
                    Task { try? await scanner.evictICloudFile(at: file) }
                } label: {
                    Label("Remove Local Copy", systemImage: "icloud.slash")
                }
            }

            Divider()

            Button(role: .destructive) {
                // Delete file
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }
    }
}

// MARK: - File Inspector View

struct FileInspectorView: View {
    let file: URL
    let scanner: StorageScanner

    @State private var fileInfo: FileInfo?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.bottom, 20)

                Divider()
                    .padding(.bottom, 20)

                // Info sections
                VStack(alignment: .leading, spacing: 20) {
                    InfoSection(title: "File Information") {
                        FileInfoGrid(fileInfo: fileInfo)
                    }

                    if scanner.scanICloud {
                        InfoSection(title: "iCloud Status") {
                            ICloudStatusRow(file: file, scanner: scanner)
                        }
                    }

                    InfoSection(title: "Actions") {
                        FileActionsRow(file: file, scanner: scanner)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(file.lastPathComponent)
        .onAppear {
            fileInfo = FileInfo(url: file)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            FileIconView(url: file, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(file.lastPathComponent)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                statusBadges
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusBadges: some View {
        HStack(spacing: 8) {
            if let info = fileInfo, info.isExecutable {
                Label("Executable", systemImage: "terminal.fill")
                    .badgeStyle(color: .orange)
            }

            if let info = fileInfo, info.isQuarantined {
                Label("Quarantined", systemImage: "exclamationmark.shield.fill")
                    .badgeStyle(color: .yellow)
            }
        }
        .font(.caption)
    }
}

// MARK: - Info Section

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            content()
        }
    }
}

// MARK: - File Info Grid

private struct FileInfoGrid: View {
    let fileInfo: FileInfo?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let info = fileInfo {
                InfoCell(title: "Size", value: info.formattedSize, systemImage: "externaldrive")
                InfoCell(title: "Created", value: info.formattedCreationDate, systemImage: "calendar.badge.plus")
                InfoCell(title: "Modified", value: info.formattedModifiedDate, systemImage: "calendar")
                InfoCell(title: "Type", value: info.fileType, systemImage: "doc")
                InfoCell(title: "Location", value: info.parentFolder, systemImage: "folder")
                InfoCell(title: "Permissions", value: info.permissionSummary, systemImage: "lock")
            }
        }
    }
}

// MARK: - Info Cell

private struct InfoCell: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - iCloud Status Row

private struct ICloudStatusRow: View {
    let file: URL
    let scanner: StorageScanner

    @State private var status: URLUbiquitousItemDownloadingStatus?

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "icloud.fill")
                    .foregroundStyle(statusColor)
            }

            Spacer()

            if status == .notDownloaded {
                Button("Download") {
                    Task { try? await scanner.downloadICloudFile(at: file) }
                }
                .buttonStyle(.bordered)
            } else if status == .current || status == .downloaded {
                Button("Remove Local Copy") {
                    Task { try? await scanner.evictICloudFile(at: file) }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            status = scanner.iCloudDownloadStatus(for: file)
        }
    }

    private var statusTitle: String {
        switch status {
        case .current: return "Downloaded"
        case .downloaded: return "Temporarily Downloaded"
        case .notDownloaded: return "In iCloud"
        default: return "Not in iCloud"
        }
    }

    private var statusDescription: String {
        switch status {
        case .current: return "A local copy is available on this Mac"
        case .downloaded: return "A temporary local copy is available"
        case .notDownloaded: return "This file is stored only in iCloud"
        default: return "This file is not stored in iCloud"
        }
    }

    private var statusColor: Color {
        switch status {
        case .current, .downloaded: return .green
        case .notDownloaded: return .blue
        default: return .secondary
        }
    }
}

// MARK: - File Actions Row

private struct FileActionsRow: View {
    let file: URL
    let scanner: StorageScanner

    var body: some View {
        HStack(spacing: 12) {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([file])
            } label: {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                NSWorkspace.shared.open(file)
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                // Move to trash
            } label: {
                Label("Move to Trash", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - File Info Model

private struct FileInfo {
    let url: URL
    let size: UInt64?
    let creationDate: Date?
    let modificationDate: Date?
    let contentType: UTType?
    let isExecutable: Bool
    let isQuarantined: Bool

    init(url: URL) {
        self.url = url
        let resourceValues = try? url.resourceValues(forKeys: [
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .contentTypeKey,
            .isExecutableKey,
            .quarantinePropertiesKey
        ])

        self.size = resourceValues?.fileSize.map { UInt64($0) }
        self.creationDate = resourceValues?.creationDate
        self.modificationDate = resourceValues?.contentModificationDate
        self.contentType = resourceValues?.contentType
        self.isExecutable = resourceValues?.isExecutable ?? false
        self.isQuarantined = resourceValues?.quarantineProperties != nil
    }

    var formattedSize: String {
        guard let size else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var formattedCreationDate: String {
        guard let date = creationDate else { return "Unknown" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedModifiedDate: String {
        guard let date = modificationDate else { return "Unknown" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var fileType: String {
        contentType?.localizedDescription ?? url.pathExtension.uppercased()
    }

    var parentFolder: String {
        url.deletingLastPathComponent().lastPathComponent
    }

    var permissionSummary: String {
        let fileManager = FileManager.default
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let permissions = attrs[.posixPermissions] as? Int else {
            return "Unknown"
        }

        var parts: [String] = []
        if (permissions & 0o400) != 0 { parts.append("Read") }
        if (permissions & 0o200) != 0 { parts.append("Write") }
        if (permissions & 0o100) != 0 { parts.append("Execute") }

        return parts.isEmpty ? "None" : parts.joined(separator: ", ")
    }
}

// MARK: - Drop Indicator

private struct DropIndicatorView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            .foregroundStyle(Color.accentColor)
            .padding(8)
    }
}

// MARK: - Badge Style Extension

private extension View {
    func badgeStyle(color: Color) -> some View {
        self
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

// MARK: - iCloud Controls Sheet

struct ICloudControlsSheet: View {
    let scanner: StorageScanner
    let file: URL

    @Environment(\.dismiss) private var dismiss
    @State private var status: URLUbiquitousItemDownloadingStatus?
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 24) {
            header

            Divider()

            content

            Divider()

            footer
        }
        .padding(24)
        .frame(width: 360)
        .onAppear { updateStatus() }
    }

    private var header: some View {
        HStack {
            Image(systemName: "icloud.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.lastPathComponent)
                    .font(.headline)
                Text("iCloud Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.body)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if isProcessing {
                ProgressView {
                    Text("Processing...")
                        .font(.caption)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                dismiss()
            }

            Spacer()

            if status == .notDownloaded {
                Button("Download") {
                    performAction { try? await scanner.downloadICloudFile(at: file) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            } else if status == .current || status == .downloaded {
                Button("Remove Local Copy") {
                    performAction { try? await scanner.evictICloudFile(at: file) }
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
            }
        }
    }

    private var statusTitle: String {
        switch status {
        case .current: return "Downloaded"
        case .downloaded: return "Temporarily Downloaded"
        case .notDownloaded: return "In iCloud"
        default: return "Not in iCloud"
        }
    }

    private var statusDescription: String {
        switch status {
        case .current: return "This file is downloaded and available locally."
        case .downloaded: return "A temporary local copy is available."
        case .notDownloaded: return "This file is only stored in iCloud."
        default: return "This file is not stored in iCloud."
        }
    }

    private var statusColor: Color {
        switch status {
        case .current, .downloaded: return .green
        case .notDownloaded: return .orange
        default: return .gray
        }
    }

    private func updateStatus() {
        status = scanner.iCloudDownloadStatus(for: file)
    }

    private func performAction(action: @escaping () async throws -> Void) {
        isProcessing = true
        Task {
            try? await action()
            await MainActor.run {
                isProcessing = false
                updateStatus()
            }
        }
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @AppStorage("highlightExecutables") private var highlightExecutables = false
    @AppStorage("includeGitDirectories") private var includeGitDirectories = false
    @AppStorage("scanICloud") private var scanICloud = false
    @AppStorage("skipSystemPaths") private var skipSystemPaths = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Scan Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Form {
                Section {
                    Toggle("Highlight Executables", isOn: $highlightExecutables)
                    Toggle("Include Git Directories", isOn: $includeGitDirectories)
                    Toggle("Scan iCloud Files", isOn: $scanICloud)
                    Toggle("Skip System Paths", isOn: $skipSystemPaths)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400, height: 320)
    }
}
