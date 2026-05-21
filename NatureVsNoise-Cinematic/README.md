# Cosmic Kubrick - Cinematic Satellite Screensaver

A Kubrick-inspired cinematic screensaver that renders satellites as *light events* rather than data points.

## Philosophy

> "The moon is unremarkable. What matters is what you see while looking at it."

This screensaver doesn't show you satellites. It shows you **moments**:
- A glint of sunlight off a tumbling solar panel
- A constellation of Starlinks drifting in formation
- The orbital shell that humanity has built around Earth

## Modes

The screensaver automatically cycles through five cinematic modes every 20 seconds:

### 1. Glints
Brief specular flashes as satellites tumble in the sunlight. Like stars winking out, but satellites winking *on*.

### 2. Constellations
Network connections between coordinated satellite groups. Starlink forms geometric patterns. GPS birds show their choreography.

### 3. Orbital Shells
Altitude bands (LEO/MEO/GEO) visualized as translucent spherical shells. You see the *structure* of orbital space.

### 4. Density Map
Color-coded congestion visualization. Brighter regions = more satellites.

### 5. Motion Trails
Velocity vectors as fading light trails. The frenetic energy of LEO vs the stately drift of GEO.

## Build

```bash
cd Kubrick.xcodeproj/..
xcodebuild -project Kubrick.xcodeproj -scheme Kubrick -configuration Release build
```

## Install

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/Kubrick-*/Build/Products/Release/Kubrick.saver ~/Library/Screen\ Savers/
```

## Configuration

The screensaver auto-detects texture files. If you have textures from the main NatureVsNoise build, put them in `Sources/8K/`:
- `earth_8k_day.jpg`
- `earth_8k_night.jpg`
- `earth_8k_clouds.png`

Otherwise, it uses procedural fallbacks.

## Credits

- **Design**: Kubrick's *2001: A Space Odyssey* for proving that scale and light matter more than detail
- **Data**: CelesTrak for TLE satellite data
- **Textures**: NASA visible Earth imagery

---

*"I've been around for 4.5 billion years. I've watched life evolve. I don't care about your satellite constellation."* — Earth, probably
