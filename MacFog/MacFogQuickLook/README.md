# MacFog Quick Look Extension

A custom Quick Look Preview Extension for macOS that provides rich previews for AI/ML models and developer files.

## Supported File Types

### Machine Learning Models
- `.mlmodel` / `.mlpackage` - Core ML models
- `.safetensors` - HuggingFace Safetensors
- `.bin` / `.ckpt` / `.index` - TensorFlow checkpoints
- `.pt` / `.pth` - PyTorch models
- `.onnx` - ONNX models

### Developer Files
- Node.js caches (`.npm`, `node_modules`)
- Xcode Derived Data
- HuggingFace cache
- Build artifacts

## Setup Instructions

### Step 1: Add Target in Xcode

1. Open `MacFog.xcodeproj` in Xcode
2. Go to **File** > **New** > **Target...**
3. Select **macOS** > **App Extension** > **Quick Look Preview Extension**
4. Name it: `MacFogQuickLook`
5. Set Bundle Identifier: `com.yourcompany.MacFog.MacFogQuickLook`
6. Click **Finish**

### Step 2: Replace Generated Files

Replace the generated files with the ones in this directory:

1. Replace `QuickLookPreviewController.swift` with the one from this folder
2. Replace `Info.plist` with the one from this folder
3. Replace the entitlements file with `MacFogQuickLook.entitlements`

### Step 3: Configure Target Settings

1. Select the **MacFogQuickLook** target in Xcode
2. In **General** tab:
   - Set **Base SDK** to `macOS`
   - Set **Deployment Target** to `macOS 11.0` or later
3. In **Build Settings**:
   - Set **Product Bundle Identifier** to `com.yourcompany.MacFog.MacFogQuickLook`
   - Ensure **Swift Version** matches your main target

### Step 4: Add UTI Declarations (Optional)

If you want to support additional file types:

1. Open `Info.plist`
2. Add new entries to `QLSupportedContentTypes` array
3. Add corresponding UTI declarations in `UTImportedTypeDeclarations`

### Step 5: Build and Test

1. Select the **MacFogQuickLook** scheme
2. Build the extension (⌘B)
3. Run the main MacFog app
4. Select a file in the File Explorer
5. Press **Space** or use **Quick Look** to see the custom preview

## Architecture

### QuickLookPreviewController
Main entry point that conforms to `QLPreviewingController`. Handles file type detection and preview preparation.

### Preview Views
- `QuickLookPreviewView` - Main preview container
- `FileIconView` - Dynamic file icon based on type
- `MLModelPreviewContent` - Custom preview for ML models
- `DeveloperCachePreviewContent` - Preview for dev caches
- `DirectoryPreviewContent` - Preview for folders

## Customization

### Adding New File Type Previews

1. Add the UTI to `Info.plist`
2. Add detection logic in `QuickLookPreviewView.isMLModelFile` or create new detection method
3. Create a new preview content view
4. Add it to the preview switch in `QuickLookPreviewView.body`

### Styling

All views use SwiftUI with SF Symbols. Customize:
- Colors in `FileIconView.iconColor`
- Icons in `FileIconView.iconSymbol`
- Layout in individual preview content views

## Troubleshooting

### Extension Not Loading
1. Make sure the extension target is included in the scheme
2. Clean build folder (⇧⌘K) and rebuild
3. Check Console.app for extension errors

### Preview Not Showing
1. Verify the file type UTI is registered in `Info.plist`
2. Check that `QLSupportedContentTypes` includes the file type
3. Ensure the extension is code-signed properly

### Sandboxing Issues
The extension has limited file access. If you need more access:
1. Add App Groups in both main app and extension
2. Add file access entitlements as needed

## References

- [Apple Quick Look Programming Guide](https://developer.apple.com/documentation/quicklookui)
- [QLPreviewingController Protocol](https://developer.apple.com/documentation/quicklookui/qlpreviewingcontroller)
- [Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers)
