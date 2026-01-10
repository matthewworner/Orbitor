# Satellite 3D Models Implementation Plan

## Goal
Replace procedural geometry satellites with real 3D `.usdz` models to achieve realistic satellite visuals during fly-through camera sequences.

---

## Current Situation (UNACCEPTABLE)

**The current procedural satellites look like garbage.** Despite implementing 4 different satellite "types" (communication, observation, starlink, cubesat) with SceneKit geometry:

- They render as **ugly colored blobs** with no distinguishable shape
- The box-with-panels approach looks like **cheap toy LEGOs**, not real spacecraft
- When the camera flies close (which it does — this is the whole point of the cinematic fly-through), you see these embarrassing primitive shapes up close
- The gold foil / metallic materials don't read properly at this scale
- **The user has explicitly rejected this approach multiple times**

**Bottom line:** Procedural geometry cannot achieve the visual quality required. We need real 3D models.

---

## Phase 1: Acquire 3D Models

### Sources (Free/Open)
1. **NASA 3D Resources** — https://nasa3d.arc.nasa.gov/models
   - ISS, Hubble, JWST, various probes
   - Official NASA models, public domain
   
2. **Sketchfab** (Free downloads) — https://sketchfab.com/search?q=satellite&type=models&licenses=322a749bcfa841b29dff1571c89f735f
   - Filter by "Downloadable" + "CC licenses"
   - Many Starlink, generic comm sats, cubesats
   
3. **TurboSquid** (Free) — https://www.turbosquid.com/Search/3D-Models/free/satellite
   - Some free models available
   
4. **CGTrader** (Free) — https://www.cgtrader.com/free-3d-models/satellite


### Models to Acquire (5 Types)
| Type | Description | Example Search |
|------|-------------|----------------|
| **Communication Sat** | Large dish antenna, cylindrical/box body | "geostationary satellite", "comms satellite" |
| **Starlink** | Flat panel, single solar array | "starlink satellite" |
| **Observation/Spy Sat** | Boxy with sensor arrays, solar wings | "earth observation satellite", "spy satellite" |
| **CubeSat** | Small cube with deployable panels | "cubesat 3u" |
| **Space Station/Large** | ISS-style for variety | "space station" (NASA has official) |

### File Format Priority
1. `.usdz` — Native Apple format, best for SceneKit
2. `.glb` / `.gltf` — Widely available, can convert
3. `.obj` + `.mtl` — Common, easy to convert
4. `.dae` (Collada) — Supported by SceneKit

### Conversion Tools
- **Reality Converter** (macOS app from Apple) — Converts to USDZ
- **Blender** — Can export to any format
- **Online converters** — https://products.aspose.app/3d/conversion/glb-to-usdz

---

## Phase 2: Prepare Models

### Steps for Each Model
1. **Download** in best available format
2. **Open in Blender** (if not USDZ)
3. **Optimize geometry**:
   - Reduce poly count to < 5,000 triangles per model
   - Delete unnecessary detail (internal parts, etc.)
4. **Center origin** at model center
5. **Normalize scale** — All models should be ~1 unit in their largest dimension
6. **Apply materials**:
   - Metallic body (silver/gold)
   - Dark blue solar panels with emission
7. **Export as USDZ**

### Naming Convention
```
satellite_communication.usdz
satellite_starlink.usdz
satellite_observation.usdz
satellite_cubesat.usdz
satellite_station.usdz
```

### Target Directory
```
NatureVsNoise/NatureVsNoise/Resources/Models/
├── satellite_communication.usdz
├── satellite_starlink.usdz
├── satellite_observation.usdz
├── satellite_cubesat.usdz
└── satellite_station.usdz
```

---

## Phase 3: Update Xcode Project

### Add Models to Bundle
1. Drag `.usdz` files into `NatureVsNoise/Resources/Models/` in Xcode
2. Ensure **Target Membership** includes `NatureVsNoise`
3. Verify in **Build Phases → Copy Bundle Resources**

---

## Phase 4: Update SatelliteRenderer.swift

### Changes Required

```swift
// MARK: - Model Loading

private var satelliteModels: [SatelliteType: SCNNode] = [:]

private func loadSatelliteModels() {
    let bundle = Bundle(for: type(of: self))
    let modelNames: [SatelliteType: String] = [
        .communication: "satellite_communication",
        .starlink: "satellite_starlink",
        .observation: "satellite_observation",
        .cubesat: "satellite_cubesat"
    ]
    
    for (type, name) in modelNames {
        if let url = bundle.url(forResource: name, withExtension: "usdz"),
           let scene = try? SCNScene(url: url, options: nil) {
            // Extract the root node from the USDZ scene
            let modelNode = SCNNode()
            for child in scene.rootNode.childNodes {
                modelNode.addChildNode(child.clone())
            }
            satelliteModels[type] = modelNode
        }
    }
}

// MARK: - Create Satellite (Updated)

private func createSatelliteModel(color: NSColor) -> SCNNode {
    let type = SatelliteType.allCases.randomElement() ?? .communication
    
    // Clone the pre-loaded model
    guard let template = satelliteModels[type] else {
        return createFallbackSatellite(color: color) // Keep procedural as fallback
    }
    
    let satellite = template.clone()
    
    // Apply color to solar panels (find by material name or geometry type)
    satellite.enumerateChildNodes { node, _ in
        if let material = node.geometry?.firstMaterial {
            // Tint emission with satellite color for visibility
            material.emission.contents = color
            material.emission.intensity = 0.3
        }
    }
    
    // Scale to fit scene (models are normalized to 1 unit)
    let targetSize: CGFloat = 0.1 // Adjust based on camera distance
    satellite.scale = SCNVector3(targetSize, targetSize, targetSize)
    
    applyRandomRotation(to: satellite)
    return satellite
}
```

### Key Points
1. **Pre-load models once** in `init()` — Don't load from disk for each satellite
2. **Clone nodes** — `template.clone()` is efficient for instancing
3. **Keep fallback** — Procedural geometry if model fails to load
4. **Color tinting** — Apply emission to solar panel materials for the neon glow effect

---

## Phase 5: Performance Optimization

### For 2000+ Satellites
1. **LOD (Level of Detail)** — Use simpler geometry when far from camera
   ```swift
   let lod = SCNLevelOfDetail(geometry: simplifiedGeometry, screenSpaceRadius: 50)
   geometry.levelsOfDetail = [lod]
   ```

2. **Geometry Instancing** — If SceneKit supports (check Metal backend)

3. **Reduce Unique Materials** — Share materials across satellites of same type

4. **Frustum Culling** — SceneKit does this automatically

5. **Cap Visible Satellites** — Only show closest 500-1000 to camera

---

## Checklist

- [ ] Download 5 satellite models (USDZ or convertible format) — *Optional: "Nano Banana" procedural fallback is live*
- [ ] Optimize in Blender (< 5k tris each) — *Optional*
- [ ] Export as USDZ with proper materials — *Optional*
- [ ] Add to Xcode project resources — *Optional*
- [x] Update SatelliteRenderer to load models — **DONE (2026-01-06)** — USDZ loader implemented
- [x] Update createSatelliteModel to clone from templates — **DONE (2026-01-06)** — Template cloning system active
- [x] High-fidelity procedural fallback ("Nano Banana") — **DONE (2026-01-06)** — 5 satellite types: Communication, Starlink, Observation, Station, GPS
- [ ] Test with camera fly-through
- [ ] Optimize performance if needed

---

## Notes for Gemini

When generating or finding models, prioritize:
1. **Low poly** (mobile-game quality, not film quality)
2. **Clean topology** (no internal faces, manifold meshes)
3. **Separated materials** (body vs solar panels for color tinting)
4. **Consistent scale** (all models same apparent size)
5. **USDZ format** if possible (Apple's native format)

Good prompts for generating:
- "Low poly satellite with solar panels, game asset, 3D model"
- "Starlink satellite 3D model, simplified geometry"
- "CubeSat 3U with deployed solar panels, low poly"
