# Deployment Guide - NatureVsNoise Screensaver

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Required for Developer ID signing
   - Required for App Store distribution (optional)

2. **Xcode** with Developer ID certificate configured

3. **macOS Machine** with Developer Mode enabled

## Deployment Options

### Option 1: Direct Distribution (Developer ID Signed)

This is the recommended approach for direct distribution to users.

#### Step 1: Obtain Developer ID Certificate

1. Open Xcode → Preferences → Accounts
2. Add your Apple Developer account
3. Click "Manage Certificates" → "+" → "Developer ID Application"

#### Step 2: Sign the Screensaver

```bash
# Navigate to your built screensaver
cd ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release

# Sign with Developer ID
codesign --force --deep \
  --sign "Developer ID Application: Your Name" \
  --options runtime \
  NatureVsNoise.saver
```

#### Step 3: Notarize (Required for macOS 10.15+)

```bash
# Create zip for submission
zip -r NatureVsNoise.zip NatureVsNoise.saver

# Submit for notarization
xcrun notarytool submit NatureVsNoise.zip \
  --apple-id "your@email.com" \
  --team-id "YOURTEAMID" \
  --password "APP-SPECIFIC-PASSWORD"

# Wait for approval (usually 5-10 minutes)
xcrun notarytool wait --uuid <uuid>

# Staple the notarization ticket
xcrun stapler staple NatureVsNoise.saver
```

#### Step 4: Distribute

- Share the `.saver` bundle directly with users
- Users can double-click to install

### Option 2: App Store Distribution

Requires additional setup but provides automatic distribution.

1. Create app in App Store Connect (macOS category: Entertainment > Screen Saver)
2. Archive in Xcode
3. Upload for review
4. Wait for Apple approval

## Installation Instructions for End Users

### Installation

1. **Double-click** `NatureVsNoise.saver`
2. System will prompt: "Are you sure you want to open it?"
3. Click "Install"
4. Screensaver will be installed to `~/Library/Screen Savers/`

### Activation

1. Open **System Settings** → **Screen Saver** (or **Desktop & Screen Saver** on older macOS)
2. Select **"Nature vs Noise"** from the list
3. Click **"Preview"** to test

### Configuration

1. Click **"Screen Saver Options..."** button
2. Configure:
   - Quality level (Low/Medium/High/Ultra)
   - Satellite density
   - HUD display settings
   - Educational facts toggle

## Troubleshooting

### "Cannot be opened because it is from an unidentified developer"

This occurs when the screensaver is not notarized.

**Solution:**
```bash
# Remove quarantine attribute
xattr -rd com.apple.quarantine NatureVsNoise.saver

# Or use Gatekeeper override
sudo xattr -rd com.apple.quarantine NatureVsNoise.saver
```

### "Launch Constraint Violation" Error

This occurs when the screensaver is ad-hoc signed on macOS 10.15+.

**Solution:**
- Re-sign with Developer ID (see Option 1 above)
- Or disable Gatekeeper: System Settings → Privacy & Security → Security → "Allow apps from identified developers"

### Black screen / No rendering

1. Check System Settings → Screen Saver → Preview works
2. Check Graphics acceleration enabled in System Settings → Displays → Advanced
3. Check for "Screen Saver Engine" crash in Console.app

### Performance issues

1. Lower quality level in Screen Saver Options
2. Disable HUD in options
3. Reduce satellite count

## Technical Requirements

- **macOS 13.0 (Ventura) or later**
- **Apple Silicon or Intel with Metal support**
- **Minimum 4GB RAM**
- **Recommended 8GB+ RAM for Ultra quality**

## File Structure

```
NatureVsNoise.saver/
├── Contents/
│   ├── Info.plist           # Bundle configuration
│   ├── MacOS/
│   │   └── NatureVsNoise    # Executable (arm64 + x86_64)
│   ├── Resources/
│   │   ├── *.jpg            # Planet textures (8K resolution)
│   │   ├── *.png            # Cloud maps, rings
│   │   ├── active_satellites.tle  # Orbital elements
│   │   └── default.metallib # Compiled Metal shaders
│   └── _CodeSignature/       # Code signing (notarization)
```

## Version History

- **1.0.0**: Initial release
  - Earth-centered satellite visualization
  - SGP4 orbital propagation
  - Metal-accelerated rendering
  - 8K planet textures
  - Mission Control HUD
  - Quality levels (Low/Medium/High/Ultra)