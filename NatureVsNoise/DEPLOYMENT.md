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

## Current signing status (2026-06-06)

A **Developer ID Application: M P Worner (PMJJD98L5C)** certificate now exists on this Mac. The
`.saver` has been signed (hardened runtime + secure timestamp) and installed to
`~/Library/Screen Savers/`, and it **runs in System Settings → Screen Saver preview** — Developer ID
signing alone is enough to run it locally on macOS 26.5.

`spctl -a --type install` still reports **"Unnotarized Developer ID"**. That only matters for
**distribution**: another Mac downloading the `.saver` will be blocked by Gatekeeper until it's
notarized + stapled. To distribute, complete the notarize → staple steps below (needs an app-specific
password or App Store Connect API key, which is not yet configured).

Check what's installed:

```bash
security find-identity -v -p codesigning   # look for "Developer ID Application: ..."
```

## Quick command reference — sign → notarize → staple

Run once a *Developer ID Application* certificate exists. Replace the identity and credentials.

```bash
# 0. Build Release
cd NatureVsNoise
xcodebuild -project NatureVsNoise.xcodeproj -target NatureVsNoise -configuration Release build
SAVER="build/Release/NatureVsNoise.saver"

# 1. Deep-sign with the hardened runtime (bundled .ttf fonts are signed as part of the bundle)
codesign --force --deep --options runtime --timestamp \
  --sign "Developer ID Application: YOUR NAME (TEAMID)" "$SAVER"
codesign --verify --deep --strict --verbose=2 "$SAVER"

# 2. Notarize (one-time: store creds in a keychain profile)
xcrun notarytool store-credentials "AC_NOTARY" \
  --apple-id "matthew.worner@me.com" --team-id "TEAMID" --password "APP_SPECIFIC_PASSWORD"
ditto -c -k --keepParent "$SAVER" "NatureVsNoise.saver.zip"
xcrun notarytool submit "NatureVsNoise.saver.zip" --keychain-profile "AC_NOTARY" --wait

# 3. Staple the ticket and verify Gatekeeper acceptance
xcrun stapler staple "$SAVER"
spctl -a -vvv --type install "$SAVER"

# 4. Install
cp -R "$SAVER" ~/Library/Screen\ Savers/
```

Then verify visually in System Settings → Screen Saver, comparing against the Stitch reference
screenshots in `docs/stitch-base/stitch-output/`.

## Version History

- **1.1.0** (2026-06-06): Astra HUD redesign — native SpriteKit port of the Stitch mockups; bundled
  JetBrains Mono; telemetry dashboard, classification legend, ambient ticker, boot sequence;
  reworked configure sheet. See `docs/ASTRA_HUD.md`.
- **1.0.0**: Initial release
  - Earth-centered satellite visualization
  - SGP4 orbital propagation
  - Metal-accelerated rendering
  - 8K planet textures
  - Mission Control HUD
  - Quality levels (Low/Medium/High/Ultra)