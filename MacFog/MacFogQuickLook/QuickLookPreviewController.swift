//
//  QuickLookPreviewController.swift
//  MacFogQuickLook
//
//  Created on 3/26/26.
//

import Foundation
import QuickLookUI
import SwiftUI

@available(macOS 11.0, *)
class QuickLookPreviewController: NSObject, QLPreviewingController {
    
    var previewItems: [QLPreviewItem]?
    
    func preparePreviewOfFile(at url: URL) async throws {
        // Get the file attributes and prepare preview based on file type
        let resourceValues = try url.resourceValues(forKeys: [
            .contentTypeKey,
            .isDirectoryKey,
            .contentSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])
        
        let fileType = resourceValues.contentType
        let isDirectory = resourceValues.isDirectory ?? false
        let fileSize = resourceValues.contentSize ?? 0
        let creationDate = resourceValues.creationDate
        let modificationDate = resourceValues.contentModificationDate
        
        // Create preview content based on file type
        let previewView = QuickLookPreviewView(
            fileURL: url,
            fileType: fileType,
            isDirectory: isDirectory,
            fileSize: Int64(fileSize),
            creationDate: creationDate,
            modificationDate: modificationDate
        )
        
        // Set the preview view
        if let hostingController = NSHostingController(rootView: previewView) as? NSViewController {
            self.view = hostingController.view
        }
    }
}

// MARK: - Quick Look Preview View

@available(macOS 11.0, *)
struct QuickLookPreviewView: View {
    let fileURL: URL
    let fileType: UTType?
    let isDirectory: Bool
    let fileSize: Int64
    let creationDate: Date?
    let modificationDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // File Icon and Name
            HStack(spacing: 16) {
                FileIconView(fileType: fileType, isDirectory: isDirectory)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    Text(fileURL.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Divider()
            
            // File Information
            GroupBox("File Information") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(label: "Type", value: fileTypeDescription)
                    InfoRow(label: "Size", value: formatSize(fileSize))
                    
                    if let modificationDate = modificationDate {
                        InfoRow(label: "Modified", value: formatDate(modificationDate))
                    }
                    
                    if let creationDate = creationDate {
                        InfoRow(label: "Created", value: formatDate(creationDate))
                    }
                    
                    InfoRow(label: "Location", value: fileURL.deletingLastPathComponent().path)
                }
                .padding(.vertical, 8)
            }
            
            // Custom Preview Based on File Type
            if isDirectory {
                DirectoryPreviewContent()
            } else if isMLModelFile {
                MLModelPreviewContent(fileURL: fileURL)
            } else if isDeveloperCache {
                DeveloperCachePreviewContent(fileURL: fileURL)
            } else {
                GenericFilePreviewContent()
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
    
    private var fileTypeDescription: String {
        if isDirectory {
            return "Folder"
        }
        return fileType?.description ?? "Unknown Type"
    }
    
    private var isMLModelFile: Bool {
        guard let fileType = fileType else { return false }
        return fileType.conforms(to: .init(filenameExtension: "mlmodel")!) ||
               fileType.conforms(to: .init(filenameExtension: "mlpackage")!) ||
               fileType.conforms(to: .init(filenameExtension: "safetensors")!) ||
               fileType.conforms(to: .init(filenameExtension: "bin")!) ||
               fileType.conforms(to: .init(filenameExtension: "pt")!) ||
               fileType.conforms(to: .init(filenameExtension: "pth")!) ||
               fileType.conforms(to: .init(filenameExtension: "onnx")!)
    }
    
    private var isDeveloperCache: Bool {
        let path = fileURL.path.lowercased()
        return path.contains("deriveddata") ||
               path.contains(".cache") ||
               path.contains("node_modules") ||
               path.contains(".npm") ||
               path.contains("huggingface")
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - File Icon View

struct FileIconView: View {
    let fileType: UTType?
    let isDirectory: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor.gradient)
            
            Image(systemName: iconSymbol)
                .font(.system(size: 32))
                .foregroundStyle(.white)
        }
        .frame(width: 60, height: 60)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
    
    private var iconSymbol: String {
        if isDirectory {
            return "folder.fill"
        }
        
        guard let fileType = fileType else {
            return "doc.fill"
        }
        
        if fileType.conforms(to: .package) {
            return "shippingbox.fill"
        } else if fileType.conforms(to: .image) {
            return "photo.fill"
        } else if fileType.conforms(to: .movie) {
            return "film.fill"
        } else if fileType.conforms(to: .audio) {
            return "music.note.house.fill"
        } else if fileType.conforms(to: .text) {
            return "doc.text.fill"
        } else if fileType.conforms(to: .data) {
            return "binary.fill"
        }
        
        return "doc.fill"
    }
    
    private var iconColor: Color {
        if isDirectory {
            return .blue
        }
        
        guard let fileType = fileType else {
            return .gray
        }
        
        if fileType.conforms(to: .init(filenameExtension: "mlmodel")!) ||
           fileType.conforms(to: .init(filenameExtension: "safetensors")!) {
            return .purple
        } else if fileType.conforms(to: .init(filenameExtension: "bin")!) ||
                  fileType.conforms(to: .init(filenameExtension: "dat")!) {
            return .orange
        } else if fileType.conforms(to: .image) {
            return .green
        } else if fileType.conforms(to: .movie) {
            return .red
        }
        
        return .blue
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
        }
    }
}

// MARK: - Directory Preview Content

struct DirectoryPreviewContent: View {
    var body: some View {
        GroupBox("Directory Contents") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Contains multiple files")
                            .font(.system(.caption, design: .rounded))
                        Text("Use Finder to explore contents")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    StatItem(icon: "cube.fill", label: "Dependencies", value: "~")
                    StatItem(icon: "clock.fill", label: "Last Accessed", value: "Recent")
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - ML Model Preview Content

struct MLModelPreviewContent: View {
    let fileURL: URL
    
    var body: some View {
        GroupBox("Machine Learning Model") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Model Architecture")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                        Text("Custom neural network weights")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    StatItem(icon: "cpu.fill", label: "Parameters", value: "~")
                    StatItem(icon: "memorychip.fill", label: "Precision", value: "FP16")
                    StatItem(icon: "network", label: "Layers", value: "~")
                }
                .padding(.top, 8)
                
                Text("Open in Create ML or Netron for detailed inspection")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Developer Cache Preview Content

struct DeveloperCachePreviewContent: View {
    let fileURL: URL
    
    var body: some View {
        GroupBox("Developer Cache") {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "terminal.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Build/Dependency Cache")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                        Text("Safe to delete for cleanup")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    StatItem(icon: "hammer.fill", label: "Build Artifacts", value: "~")
                    StatItem(icon: "shippingbox.fill", label: "Packages", value: "~")
                }
                .padding(.top, 8)
                
                Text("Can be regenerated on next build")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Generic File Preview Content

struct GenericFilePreviewContent: View {
    var body: some View {
        GroupBox("File Preview") {
            VStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                Text("No custom preview available")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text("Use Quick Look (Space) for standard preview")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
            
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
