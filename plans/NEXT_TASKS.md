# Next Tasks: Build & Test Stability Improvements

**Date:** 2026-01-07
**Status:** Ready for implementation

---

## Overview

The stability framework has been implemented with feature flags, safe presets, and comprehensive logging. The app now has proper controls to isolate and diagnose the black screen issue. Next priority is building and testing to confirm stability.

---

## 🎯 Immediate Tasks (Build & Test)

### 1. Build the Application
**Goal:** Verify no compilation errors with new code

**Steps:**
- Navigate to `NatureVsNoise/` directory
- Run: `xcodebuild -project NatureVsNoise.xcodeproj -scheme NatureVsNoise -configuration Release build`
- Check for successful compilation
- Install `.saver` bundle to `~/Library/Screen Savers/`

**Expected Outcome:** Clean build with no errors

### 2. Test Safe Preset (Default)
**Goal:** Confirm safe preset works without black screen

**Steps:**
- Open System Settings → Desktop & Screen Saver
- Select NatureVsNoise screensaver
- Test thumbnail preview (should show planets)
- Test full-screen preview
- Check `~/Library/Logs/NatureVsNoise.log` for:
  - "Scene setup complete"
  - FPS readings around 60
  - No errors or crashes

**Success Criteria:**
- Full-screen shows planets + starfield + satellites
- No black screen
- Smooth 60fps performance
- Logs show clean initialization

### 3. Analyze Logs for Black Screen
**Goal:** If black screen occurs, identify root cause

**Steps:**
- Compare thumbnail vs full-screen log entries
- Look for differences in:
  - Lifecycle timing (setFrameSize, startAnimation)
  - GPU/Metal initialization
  - Scene setup completion
- Check for sandbox restrictions or GPU access issues

**Expected Outcome:** Clear diagnosis of black screen cause

---

## 🚀 Medium-term Tasks (Feature Enablement)

### 4. Test Feature Combinations
**Goal:** Gradually enable features to find stability limits

**Test Matrix:**
- Toy sats only (50 count) ✅ Already working
- Firefly swarm only (Metal points)
- Combined toy sats + firefly swarm
- Increase satellite count (800 → 2000 → 5000)
- Re-enable labels (nearest only)

**Steps:**
- Modify `FeatureFlags` in code or UserDefaults
- Test each combination full-screen
- Monitor logs for performance/FPS
- Note breaking points

### 5. Debug Metal Rendering
**Goal:** Fix Metal satellite rendering crashes

**Steps:**
- Enable `useMetalSatellites` flag
- Test with small satellite counts first
- Check logs for Metal initialization errors
- Isolate GPU access issues in screensaver sandbox
- Implement fallback to SceneKit if Metal fails

### 6. Tune Camera & Visibility
**Goal:** Improve satellite visibility during fly-through

**Steps:**
- Adjust camera path to get closer to Earth/satellites
- Slow down fly-through during satellite shell passage
- Ensure satellites are visible against starfield
- Test on different display sizes

---

## 🎵 Audio & Polish Tasks

### 7. Implement Basic Audio
**Goal:** Add ambient space sounds

**Steps:**
- Integrate existing audio files from bundle
- Add simple ambient loop playback
- Test AVAudioEngine in screensaver context
- Ensure no performance impact

### 8. Add Settings UI
**Goal:** Allow users to toggle features

**Steps:**
- Implement macOS screensaver preferences
- Add toggles for Metal, labels, satellite count
- Connect to `FeatureFlags` UserDefaults
- Test preference persistence

---

## 📊 Success Metrics

- **Safe Preset:** Works full-screen without black screen ✅
- **Performance:** 60fps with safe preset ✅
- **Stability:** No crashes in 10-minute full-screen test
- **Features:** 50% of satellites visible during fly-through
- **Logs:** Clean initialization with useful diagnostics

---

## 🔧 Risk Mitigation

- **Fallback Plan:** If Metal remains unstable, ship with SceneKit toy sats only
- **Minimum Viable:** Planets + starfield + 800 satellites (current safe preset)
- **Incremental Testing:** Never enable multiple features simultaneously
- **Log Analysis:** Use logs to make data-driven decisions

---

## 📋 Dependencies

- Xcode 15+ with macOS 13+ SDK
- Apple Silicon Mac for Metal testing (Intel fallback available)
- Access to System Settings for screensaver testing

---

## 🎯 Next Milestone

**Stable macOS screensaver launch** with safe preset working reliably.