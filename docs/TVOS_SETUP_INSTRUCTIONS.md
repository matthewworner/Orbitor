# 📺 tvOS Target Setup Instructions

**Goal:** Configure the Xcode project to build the tvOS app using the existing source files.

Since the `NatureVsNoise.xcodeproj` cannot be safely edited by the agent, you must perform these steps manually in Xcode.

## 1. Add tvOS Target

1.  Open `NatureVsNoise.xcodeproj` in Xcode.
2.  Go to **File > New > Target...**.
3.  Select **tvOS** tab, then **App**.
4.  Click **Next**.
5.  **Product Name:** `NatureVsNoiseTV`
6.  **Organization Identifier:** `com.yourcompany` (Match your macOS bundle ID prefix)
7.  **Interface:** `Storyboard` (We will delete this later and use code-based UI, but easiest to start here) or `SwiftUI` if you prefer, but the code uses `UIKit` view controllers.
8.  **Language:** `Swift`.
9.  Click **Finish**.

## 2. Configure Source Files

1.  In the **Project Navigator** (left sidebar), select the `NatureVsNoiseTV` group.
2.  Delete `ContentView.swift` (if SwiftUI) or `ViewController.swift` (if Storyboard) and `Main.storyboard` created by the template.
3.  **Add Existing Files:**
    *   Right-click `NatureVsNoiseTV` group > **Add Files to "NatureVsNoise"...**
    *   Navigate to `tvOS/Sources` folder.
    *   Select `AppDelegate.swift` and `NatureVsNoiseViewController.swift`.
    *   **IMPORTANT:** Ensure "Add to targets" has `NatureVsNoiseTV` checked.
    *   Click **Add**.

## 3. Link Shared Code

We need to add the shared logic (Planets, Satellites, etc.) to the tvOS target.

1.  Select the `NatureVsNoiseTV` target in the project settings.
2.  Go to **Build Phases** > **Compile Sources**.
3.  Click **+** and add the following files from the `Sources` folder:
    *   `NatureVsNoise/Sources/Planets/PlanetFactory.swift`
    *   `NatureVsNoise/Sources/Satellites/*.swift` (All files: `SGP4Propagator`, `TLEFetcher`, `SatelliteManager`, `SatelliteRenderer`, `MetalSatelliteRenderer`)
    *   `NatureVsNoise/Sources/Camera/CameraController.swift`
    *   `NatureVsNoise/Sources/Audio/AudioController.swift`
    *   `NatureVsNoise/Sources/UI/HUDOverlay.swift`
    *   `NatureVsNoise/Sources/CrossPlatform/ImageLoader.swift`

## 4. Add Metal Shaders

1.  In **Build Phases** > **Copy Bundle Resources** (or **Compile Sources** for `.metal`), verify:
    *   `SatelliteShaders.metal` is present. If not, add it.

## 5. Add Resources

1.  In **Build Phases** > **Copy Bundle Resources**:
    *   Add the `Resources/Textures` folder (Select "Create folder references").
    *   Add the `Resources/Audio` folder (Select "Create folder references").

## 6. Info.plist Configuration

1.  Open `tvOS/Resources/Info.plist` (or the one created by Xcode for the target).
2.  Ensure `UIRequiredDeviceCapabilities` includes `arm64`.
3.  Set `GameController` capabilities if using Siri Remote as a game controller (optional).

## 7. Build & Run

1.  Select the **NatureVsNoiseTV** scheme.
2.  Select a **tvOS Simulator** (e.g., Apple TV 4K).
3.  Press **Cmd+R** to build and run.
4.  Verify the app launches and displays the solar system.

## 8. Capability Check

*   **Metal:** The simulator may use a software renderer or different GPU path. Test on device for true Metal performance.
*   **Audio:** Ensure sound plays (you should hear the placeholder silence or any real files you added).
