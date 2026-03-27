# Quick Look Extension Setup Guide

## Files Created

The following files have been created in `/MacFogQuickLook/`:

1. **QuickLookPreviewController.swift** - Main preview controller with custom SwiftUI views
2. **Info.plist** - Extension configuration with UTI declarations
3. **MacFogQuickLook.entitlements** - Sandbox entitlements
4. **README.md** - Detailed documentation

## Manual Xcode Setup

Since I cannot directly modify your Xcode project file, follow these steps:

### 1. Create New Target

1. Open `MacFog.xcodeproj` in Xcode
2. Select **File** > **New** > **Target...**
3. Choose **macOS** > **App Extension** > **Quick Look Preview Extension**
4. Click **Next**
5. Configure:
   - **Product Name**: `MacFogQuickLook`
   - **Team**: Your development team
   - **Bundle Identifier**: `com.yourcompany.MacFog.MacFogQuickLook` (replace with your bundle ID)
   - **Embed in Application**: MacFog
6. Click **Finish**
7. When prompted, click **Activate** to switch to the new scheme

### 2. Replace Generated Files

Xcode will create template files. Replace them:

1. In Finder, navigate to the new `MacFogQuickLook` folder in your project
2. Delete the generated `QuickLookPreviewController.swift`
3. Copy the files from `/MacFogQuickLook/` in this project to the Xcode-created folder

### 3. Configure Build Settings

Select the **MacFogQuickLook** target and verify:

**General Tab:**
- Deployment Target: macOS 11.0+
- Base SDK: macOS

**Build Settings:**
- Swift Version: 5.0+ (match your main target)
- Product Bundle Identifier: Should match what you set in step 1

**Signing & Capabilities:**
- Ensure signing is configured
- Add **App Sandbox** capability if not present

### 4. Add UTI Declarations to Main App

For the extension to work system-wide, add UTI declarations to your main app:

1. Select **MacFog** target (main app)
2. Go to **Info** tab
3. Add **Document Types** array if not present
4. Add entries for each file type you want to support

Example Info.plist entries for main app:

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>ML Model</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>org.huggingface.safetensors</string>
            <string>com.pytorch.model</string>
            <string>com.tensorflow.checkpoint</string>
        </array>
    </dict>
</array>
```

### 5. Build and Run

1. Select **MacFog** scheme (main app)
2. Build and run (⌘R)
3. Navigate to File Explorer
4. Click on any file row
5. The `previewURL` will be updated with the file's path

### 6. Test Quick Look

1. In Finder, navigate to a supported file type
2. Select the file
3. Press **Space** to invoke Quick Look
4. Your custom preview should appear

## Testing the previewURL Feature

The `previewURL` state is now available in `StorageVisualizationView`. To use it:

```swift
// In your view where you want to show the preview
@State private var previewURL: URL?

// When a file is selected, previewURL is automatically updated
// You can use it with QLPreviewPanel or other preview mechanisms
```

Example usage with Quick Look panel:

```swift
import QuickLookUI

struct FilePreviewView: View {
    @Binding var previewURL: URL?
    @State private var showPreview = false
    
    var body: some View {
        Button("Preview") {
            showPreview = true
        }
        .quickLookPreview($previewURL, isPresented: $showPreview)
    }
}
```

## Next Steps

1. **Add Quick Look Panel Integration**: Add a preview button to `FileRow` that opens `QLPreviewPanel`
2. **Real File System Integration**: Connect the mock file paths to actual file system scanning
3. **Enhanced ML Previews**: Integrate with Core ML or Netron for actual model inspection
4. **Add More UTIs**: Extend support for more file types specific to your workflow

## Support

For issues or questions:
- Check Console.app for extension errors
- Verify code signing in Xcode
- Ensure the extension is enabled in System Preferences > Extensions > Quick Look
