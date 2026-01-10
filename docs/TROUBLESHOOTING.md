# 🔧 Troubleshooting Guide

## 🔴 Build Errors

### 1. "Missing Metal Toolchain"
**Error:** `error: cannot execute tool 'metal' due to missing Metal Toolchain`
**Cause:** The command line tools or Xcode installation is missing the specific Metal compiler components required for the shaders.
**Fix:**
1.  Open Xcode.
2.  Go to **Xcode > Settings > Components**.
3.  Look for "Metal Toolchain" or similar graphics tools and download them.
4.  Alternatively, try running this in Terminal: `xcodebuild -downloadComponent MetalToolchain`

### 2. "Cannot find type 'AudioController' in scope" (or HUDOverlay, SettingsController)
**Error:** Compiler fails to find classes that definitely exist in the source folder.
**Cause:** The files are not added to the **Target Membership** of the `NatureVsNoise` target.
**Fix:**
1.  Open `NatureVsNoise.xcodeproj` in Xcode.
2.  Select the `NatureVsNoise` target (ScreenSaver icon).
3.  Go to the **Build Phases** tab.
4.  Expand **Compile Sources**.
5.  Click **+** and search for the missing files:
    *   `AudioController.swift`
    *   `HUDOverlay.swift`
    *   `SettingsController.swift`
    *   `HardwareCapabilities.swift` (if separated)
    *   `ImageLoader.swift`
6.  Click **Add**.

### 3. "Value of type 'SCNView' has no member 'overlaySKScene'"
**Error:** Compiler error on `sceneView.overlaySKScene`.
**Cause:** Missing `import SpriteKit`.
**Fix:** Ensure `import SpriteKit` is added to the top of `NatureVsNoiseView.swift` (We have applied this fix in patch 1).

---

## 🎨 Asset Issues

### 1. Planets look white or grey
**Cause:** Missing textures. The app defaults to colors if textures fail to load.
**Fix:**
*   Check `Resources/Textures/8K`.
*   Ensure the file names match exactly (e.g., `earth_8k_day.jpg`).
*   **Normal Maps:** If planets look flat, it's because `Textures/Normal_Maps` is empty or not in the loader path.

### 2. No Moons ("Jupiter Encounter" looks empty)
**Cause:** Moon logic is not implemented yet.
**Fix:** This is a known roadmap item ("Implement Moons Code"). It requires writing a `MoonFactory` class and adding it to the scene.

---

## 🔊 Audio Issues

### 1. Silence during playback
**Cause:** Placeholders are currently silent .wav files.
**Fix:** Replace the files in `Resources/Audio` with real audio content.

### 2. "AudioController not found"
**Cause:** See Build Error #2.
