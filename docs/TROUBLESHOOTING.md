# Troubleshooting Guide

## Build Errors

### 1. "Missing Metal Toolchain"
**Error:** `error: cannot execute tool 'metal' due to missing Metal Toolchain`
**Fix:**
1. Open Xcode
2. Go to **Xcode > Settings > Components**
3. Download "Metal Toolchain" or similar graphics tools
4. Or run: `xcodebuild -downloadComponent MetalToolchain`

### 2. "Cannot find type 'X' in scope"
**Error:** Compiler fails to find classes that exist in source folder.
**Cause:** Files not added to Target Membership.
**Fix:**
1. Open `NatureVsNoise.xcodeproj` in Xcode
2. Select `NatureVsNoise` target
3. Go to **Build Phases** → **Compile Sources**
4. Click **+** and add missing files

### 3. "Value of type 'SCNView' has no member 'overlaySKScene'"
**Fix:** Ensure `import SpriteKit` is in `NatureVsNoiseView.swift`

---

## Rendering Issues

### 1. Black Screen in Full-Screen Mode (RESOLVED)
**Status:** ✅ Fixed in 2026-02-21 update
**Cause:** Metal renderer had no connection to ScreenSaverView's display context
**Fix:** Metal now integrates via `SCNSceneRendererDelegate` using `currentRenderCommandEncoder`

If black screen still occurs:
1. Check `~/Library/Logs/NatureVsNoise.log` for errors
2. Try disabling Metal swarm in settings (use SceneKit-only mode)
3. Verify hardware supports Metal (macOS 13.0+)

### 2. Planets look white or grey
**Cause:** Missing textures
**Fix:**
- Check `Resources/Textures/8K` contains all planet textures
- Verify file names match exactly (e.g., `earth_8k_day.jpg`)

### 3. Low FPS / Stuttering
**Fix:**
- Reduce satellite count in settings
- Disable motion trails
- Use "Safe" preset for older hardware
- Check Activity Monitor for GPU usage

---

## Satellite Issues

### 1. No satellites visible
**Causes:**
- Satellite data files missing from `Resources/Data/`
- Satellite count set too low
- Camera too far from Earth

**Fix:**
- Verify TLE files exist: `active.tle`, `starlink.tle`, `debris.tle`
- Increase satellite count in settings
- Check camera is passing near Earth during fly-through

### 2. Satellites all look the same
**Status:** ✅ Fixed - Classification system implemented
**Expected:** ISS has detailed model, debris is dark chunks, Starlink has flat panels

---

## Audio Issues

### 1. Silence during playback
**Cause:** Audio disabled by default or placeholder files
**Fix:**
- Enable audio in screensaver settings
- Verify audio files exist in `Resources/Audio/`

### 2. Audio stuttering
**Fix:**
- Disable audio for performance
- Check system audio output device

---

## Performance Tuning

| Hardware | Recommended Settings |
|----------|---------------------|
| M1/M2 Mac | All features enabled, 5000+ satellites |
| M1 (base) | High quality, 2000 satellites, trails on |
| Intel Mac | Medium quality, 500 satellites, trails off |
| Older Mac | Safe preset, SceneKit only |

---

## Logs

Check `~/Library/Logs/NatureVsNoise.log` for:
- Initialization errors
- Metal/GPU errors
- Missing resources
- FPS metrics

---

## Reinstallation

```bash
# Remove old version
rm -rf ~/Library/Screen\ Savers/NatureVsNoise.saver

# Build and install fresh
cd /path/to/NatureVsNoise
xcodebuild -scheme NatureVsNoise -configuration Release build
cp -R ~/Library/Developer/Xcode/DerivedData/NatureVsNoise-*/Build/Products/Release/NatureVsNoise.saver ~/Library/Screen\ Savers/
```
