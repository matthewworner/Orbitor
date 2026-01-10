# Product Requirements Document
## "Nature's Calm vs. Humanity's Noise" - macOS/tvOS Screensaver

**Version:** 1.0  
**Date:** December 25, 2025  
**Status:** Planning Phase

---

## Executive Summary

A thought-provoking screensaver for macOS and tvOS that creates a powerful visual and emotional contrast between the serene, timeless beauty of our solar system and the chaotic, growing swarm of human-made objects orbiting Earth. Through cinematic 3D visualization, real satellite data, and subtle educational elements, the screensaver serves as both a meditative ambient experience and a quiet commentary on humanity's expanding footprint in space.

**Full Experience Runtime:** 12-15 minutes per complete cycle before looping, designed for both desktop idle time and living room ambient viewing.

---

## Vision & Core Concept

### The Duality

**Nature's Calm (60-70% runtime, ~8-10 minutes)**  
Peaceful, wide-angle view of the solar system with planets orbiting in their natural majesty. Slow camera movements, serene rotations, cosmic tranquility. The camera takes a grand tour from the outer solar system inward, spending time with each planet.

**Humanity's Noise (30-40% runtime, ~4-6 minutes)**  
Zoomed view of Earth surrounded by a dense, chaotic swarm of 40,000+ tracked objects—satellites, debris, rocket bodies—all moving at realistic velocities with visual effects that emphasize the "noise." The overwhelming contrast is visceral and immediate.

### Emotional Arc

The screensaver should evoke:

- Wonder and awe at cosmic scale
- Meditative calm during planetary views
- Subtle unease during Earth zoom-ins
- Contemplation about humanity's relationship with space
- Educational curiosity about orbital mechanics and space policy
- Conversation-starting moments for viewers and guests

---

## Feature Requirements

### 1. Visual Modes & Camera Behavior

#### Complete Experience Timeline (12-15 minute loop)

**Act I: The Grand Tour - Nature's Calm (8-10 minutes)**

*Outer Solar System (3 minutes)*
- **Neptune Approach (45 sec):** Camera slowly approaches from deep space, Neptune grows from a dot to fill 1/4 of screen. Deep blue, subtle atmospheric features visible in 8K detail.
- **Neptune Contemplation (30 sec):** Slow orbit around Neptune, Great Dark Spot visible, thin rings catch sunlight.
- **Uranus Transition (45 sec):** Camera pulls back and drifts toward Uranus, shows its unique 98° axial tilt.
- **Uranus Moment (30 sec):** Pale blue-green sphere, faint rings, serene and alien.
- **Saturn Approach (30 sec):** Camera accelerates gently toward the jewel of the solar system.

*Saturn Showcase (2 minutes)*
- **Ring Reveal (45 sec):** Camera approaches from an angle that showcases the rings' majesty. 16K ring texture shows Cassini Division clearly. Light plays through the rings.
- **Saturn Close-up (45 sec):** Orbit the planet, subtle bands visible, ring shadows on the surface, Titan visible in background.
- **Ring Dive (30 sec):** Camera passes through ring plane (from above to below), ethereal moment as particles surround the view.

*Gas Giant Power (2 minutes)*
- **Jupiter Approach (45 sec):** Camera accelerates toward the largest planet, Great Red Spot becomes visible.
- **Jupiter Majesty (60 sec):** Close orbit showing turbulent cloud bands, lightning flashes in atmosphere (rare), Galilean moons in background orbiting.
- **Io Flyby (15 sec):** Quick pass by volcanic Io showing sulfur-yellow surface.

*Inner System (2-3 minutes)*
- **Asteroid Belt Transit (30 sec):** Camera drifts through sparse asteroid field (subtle, not dense Hollywood version).
- **Mars Arrival (45 sec):** Red planet grows, polar ice caps visible, Olympus Mons casts long shadow.
- **Mars to Earth (45 sec):** Camera begins its fateful journey toward our home.
- **Venus Pass (30 sec):** Brief glimpse of cloud-shrouded Venus before continuing to Earth.

**Act II: The Reveal - Humanity's Noise (4-6 minutes)**

*The Approach (90 seconds)*
- **Earth First Glimpse (30 sec):** Beautiful blue marble, clouds swirling, looks peaceful and isolated.
- **First Signs (30 sec):** As camera gets closer, a few bright dots become visible near Earth.
- **The Swarm Emerges (30 sec):** Suddenly, thousands of additional dots appear as the camera crosses a threshold. The density is shocking.

*Peak Chaos (2 minutes)*
- **Full Debris Field (60 sec):** Earth now surrounded by a dense, glittering, chaotic cloud of 40,000 objects. Fast-moving LEO satellites streak across view. Slower GEO satellites appear stationary. ISS visible as slightly larger object. Motion trails everywhere.
- **Color-Coded Revelation (30 sec):** If enabled, debris colors shift to show country of origin—reds (Russia), blues (USA), yellows (China) dominate.
- **Stats Overlay (30 sec):** If enabled, statistics fade in showing the numbers. The scale is overwhelming.

*Orbital Dance (90 seconds)*
- **Different Altitudes (45 sec):** Camera orbits Earth at different heights, showing how satellites cluster in specific bands (LEO, MEO, GEO).
- **Night Side (45 sec):** Camera rotates to Earth's night side. City lights glow below (if enabled), radio waves pulse outward from ground stations, satellites flash in sunlight above the dark Earth. Both beautiful and unsettling.

*The Escape (60 seconds)*
- **Pulling Back (30 sec):** Camera slowly zooms out. The debris cloud becomes a hazy glow around Earth.
- **Perspective Restored (30 sec):** As camera retreats, Earth becomes small again, the debris invisible from this distance. The solar system's calm returns.

**Act III: The Return (30-60 seconds)**
- **Mercury Pass (optional, 15 sec):** Quick glimpse of innermost planet as camera swings back out.
- **Return to Deep Space (30 sec):** Camera drifts back out toward Neptune, the cycle begins anew. Seamless loop point.

#### Mode Variations

**Mode 1: Balanced (Default) - 12-15 min cycle**
- Full grand tour as described above
- Best for first-time viewers and living room ambient
- Shows complete contrast

**Mode 2: Pure Nature - 10-12 min cycle**
- Solar system grand tour only, no Earth debris layer
- Extended planetary views (30-60 sec each)
- Continuous slow pan through the solar system, seamless loop
- Perfect for meditation, background ambiance, bedtime wind-down

**Mode 3: Human Footprint - 8-10 min cycle**
- Earth-focused with persistent debris visualization
- Orbit variations with different camera angles and altitudes around Earth
- Optional feature: More time on night-side Earth with glowing city lights + satellite swarm
- Camera never leaves Earth's vicinity
- Perfect for educational settings, advocacy, conversation-starting

---

### 2. Solar System Visualization (Nature's Calm)

#### Sun
- High-quality textured sphere with corona glow effect
- Subtle surface animation (solar flares, rotation)
- Radial gradient lighting emanating outward

#### Planets (Mercury → Neptune)

**Orbital Mechanics:**
- Accurate relative orbital speeds (scaled for visibility)
- Proper orbital distances (compressed for framing)
- Elliptical orbits with correct eccentricity
- Realistic axial tilt and rotation speeds

**Visual Quality:**
- 8K resolution texture maps (8192×4096 minimum) from NASA
- Multiple texture layers per planet (diffuse, specular, normal maps)
- Atmospheric effects for gas giants (cloud bands, storms)
- Specular highlights and PBR (Physically Based Rendering) materials
- Dynamic cloud layers for Earth and gas giants
- Subtle seasonal changes over long runtime
- Night-side illumination for Earth (city lights)

**Planets to Include:**
- **Mercury:** Cratered, gray, 8K NASA texture
- **Venus:** Bright yellow, thick atmosphere, 8K
- **Earth:** Blue marble, dynamic clouds, day/night terminator, city lights, 8K
- **Mars:** Rusty red, polar caps, Olympus Mons visible, 8K
- **Jupiter:** Banded, Great Red Spot animated, dynamic cloud motion, 8K
- **Saturn:** Subtle bands, storm systems, 8K
- **Uranus:** Tilted 98°, pale blue-green, faint rings, 8K
- **Neptune:** Deep blue, dynamic Great Dark Spot, 8K

#### Moons & Rings

**Major Moons:**
- Jupiter's Galilean moons (Io, Europa, Ganymede, Callisto)
- Saturn's Titan
- Earth's Moon
- All with 4K+ textures

**Saturn's Rings:**
- High-resolution ring texture (16K circumference map)
- Multi-layered with proper transparency and particle distribution
- Cassini Division clearly visible
- Ring shadows cast on Saturn
- Subtle color variations (A, B, C rings)
- Ring particles catch sunlight realistically

**Orbital Paths:** Faint, elegant circular/elliptical guides (toggleable)

#### Aesthetic Elements
- Starfield background (static or slowly parallaxing)
- Subtle lens flare effects when camera passes near Sun
- Minimal UI: Optional planet name labels that fade in/out
- Color grading: Cool blues and purples for space, warm tones for planets

---

### 3. Earth Debris Visualization (Humanity's Noise)

#### Data Sources

**Primary: CelesTrak Two-Line Element (TLE) sets**
- Active satellites (~11,000)
- Debris objects (~29,000 tracked pieces >10cm)
- Rocket bodies and defunct satellites

**Update Frequency:** Daily automated fetch with local caching  
**Propagation:** SGP4/SDP4 algorithm for real-time position calculation

#### Particle System Design

**Rendering Approach:**
- GPU-instanced geometry for 40,000+ objects
- Level-of-detail (LOD) system: detailed when close, billboards when distant
- Particle size based on object type (satellites larger than debris)

**Visual Effects:**
- Motion trails (short, fading streaks showing velocity)
- Occasional tumbling flashes (simulating debris catching sunlight)
- Orbital path visualization (faint curves showing trajectory)
- Radio pulse effects (symbolic communication "noise")
- Collision warnings (rare, dramatic visual when objects pass close)

#### Debris Coloring Schemes

**Option 1: By Country (Default)**
- **Red/Orange:** Russia/Soviet Union (~35% of debris)
  - Includes 2021 ASAT test fragments
  - Legacy Soviet-era satellites and rocket bodies
- **Blue:** United States (~30%)
  - Commercial constellations (Starlink, OneWeb)
  - Military and civil satellites
- **Yellow:** China (~20%)
  - 2007 ASAT test (massive fragmentation event)
  - Recent expansion of domestic programs
- **Teal/Green:** Other nations (~15%)
  - ESA, India, Japan, private companies

**Option 2: By Type**
- **Bright white:** Active, functioning satellites
- **Dim gray:** Inactive/defunct satellites
- **Red:** Confirmed debris fragments
- **Orange:** Rocket bodies and large derelict objects

**Option 3: By Altitude**
- **Cyan:** LEO (Low Earth Orbit, 200-2,000 km) - fastest moving
- **Yellow:** MEO (Medium Earth Orbit, 2,000-35,786 km) - GPS region
- **Magenta:** GEO (Geostationary, 35,786 km) - appears stationary
- **White:** HEO (Highly Elliptical Orbit)

**Option 4: Monochrome**
- Pure white particles for aesthetic minimalism

#### Orbital Dynamics

**Velocity Scaling:** Visible motion at accelerated time (50-500× real-time)

**Realistic Behavior:**
- LEO satellites complete visible orbits in seconds
- GEO satellites remain relatively fixed above Earth's equator
- Polar orbits cross over poles
- Sun-synchronous orbits maintain dawn-dusk terminator alignment

#### Special Highlighting

- **ISS (International Space Station):** Slightly larger, labeled, distinctive color
- **Recent Launches:** "Train" effect for fresh Starlink deployments (first 24-48 hours)
  - Show characteristic linear formation before dispersion
  - Fade effect as satellites separate to operational orbits
- **Notable Satellites:** Option to highlight Hubble, James Webb (when visible), major commercial satellites

---

### 4. Educational Overlays & Data Display

#### Statistics HUD (Toggleable)

Appears during Earth zoom-in mode:

```
HUMANITY'S ORBITAL FOOTPRINT (as of Dec 2025)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tracked Objects:        ~40,000
  Active Satellites:    ~11,000
  Debris Fragments:     ~29,000
  
Estimated Untracked:
  >1cm pieces:          ~1.2 million
  >1mm pieces:          ~140 million

Primary Contributors:
  ■ Russia  ■ USA  ■ China
```

#### Launch Notifications

When real launches occur (data from APIs):
- Brief on-screen notification: "SpaceX Starlink Group 12-8 deployed"
- Show deployment animation
- Update active satellite count

#### Accumulation Timeline (Optional Feature)

Animated graph showing debris growth 1957→2025

**Key events marked:**
- 1957: Sputnik (beginning)
- 2007: Chinese ASAT test (massive spike)
- 2009: Iridium-Cosmos collision
- 2021: Russian ASAT test
- 2020-2025: Mega-constellation era (steep curve)

#### Context Overlays

Subtle educational text that fades in/out:
- "One Starlink launch adds 20-60 satellites"
- "Kessler Syndrome: chain reaction risk threshold"
- "~100 tons of space debris re-enters atmosphere annually"
- "Active debris removal missions: ClearSpace-1 (2026)"

---

### 5. Configuration Options

#### Settings Panel (macOS System Preferences integration)

**Viewing Mode**
- ☑ Balanced (Nature ↔ Noise)
- ☐ Pure Nature (Planets Only)
- ☐ Human Footprint (Earth Focus)

**Debris Visualization**
- ☑ Show satellite/debris swarm
- Coloring scheme: [Country ▼] [Type] [Altitude] [Monochrome]

**Orbital Dynamics**
- Time acceleration: [slider: 10× — 500×] (default: 100×)
- ☑ Show orbital paths
- ☑ Highlight recent launches
- ☑ Show ISS and named satellites

**Information Display**
- ☑ Statistics overlay
- ☑ Planet/object labels
- ☑ Launch notifications
- Info density: [Minimal ▼] [Moderate] [Educational]

**Visual Effects**
- ☑ Motion trails on debris
- ☑ Radio pulse effects
- ☑ City lights on Earth (night side)
- ☑ Lens flares and atmospheric effects

**Audio**
- ☐ Enable ambient soundtrack
- Mix balance: [More Natural ←→ More Human]
- ☐ Include mission voice clips
- ☐ Enhance bass for subwoofers
- Volume: [slider: 0-100%] (default: 80%)

**Performance**
- Particle count: [Full 40K ▼]
- Texture quality: [8K ▼] [4K] [2K]
- Metal rendering: [Always enabled on Apple Silicon]

---

### 6. Audio Design & Soundscape

#### Core Philosophy

Use authentic NASA and ESA space recordings (all public domain) to create a layered soundscape that reinforces the nature vs. noise duality. The audio should be:

- Scientifically accurate (real mission recordings)
- Legally clean (no licensing issues)
- Thematically powerful (supports the visual narrative)
- Optional but recommended (off by default, easy to enable)

#### Audio Architecture: Four-Layer System

**Layer 1: Deep Space Ambient (Always Playing)**
- Low-frequency rumble (10-100 Hz) from solar wind plasma waves
- Creates meditative foundation, felt more than heard
- Long seamless loops (10-15 minutes)
- Sources: Voyager solar wind recordings, cosmic background
- Volume: Subtle, -18dB to -12dB

**Layer 2: Planetary Tones (During Solar System View)**

Each planet has its own electromagnetic "voice":

- **Jupiter:** Deep electrical crackling, auroral emissions (powerful, dramatic)
- **Saturn:** High-pitched chirps and whistles from radio emissions (ethereal)
- **Earth:** Magnetosphere hum, bow shock crossings (familiar yet alien)
- **Mars:** Thin atmospheric static (sparse, lonely)
- **Venus:** Thick cloud interference (dense, oppressive)
- **Neptune/Uranus:** Eerie low-frequency tones (mysterious)

*Behavior:*
- Crossfade between planetary sounds as camera moves
- 5-10 second fade duration for smooth transitions
- Each planet audio snippet: 30-60 seconds, seamlessly looping

**Layer 3: "Human Noise" (During Earth Zoom Mode)**

Progressive layering that intensifies as camera zooms to debris field:

- Radio static (multiple frequency bands)
- Telemetry beeps (satellite data transmissions)
- Radar pings (tracking stations)
- Morse code (old satellite protocols)
- GPS signals (navigation constellation chatter)
- Mission audio snippets (optional, ISS/ground control fragments)

*Behavior:*
- Starts silent during solar view
- Fades in over 20 seconds during Earth transition
- Reaches peak density when fully zoomed on debris swarm
- Creates sense of "overwhelm"
- Gradually reduces planetary layer to 30% volume (nature overwhelmed by noise)

**Layer 4: Special Events (Occasional, Rare)**
- Solar flare burst: When camera passes near sun (~5% chance)
- Satellite deployment sounds: Mechanical clicks/whirs for launch animations
- Collision warning tones: Rare dramatic moment when debris passes close

#### Audio Contrast: The Core Experience

**During "Nature's Calm" (Solar System Mode):**
```
Deep ambient rumble (40% volume)
  + Planetary radio emissions (100% volume, crossfading)
    + Very sparse cosmic ray "ticks" (10% volume)
      = Meditative, vast, timeless feeling
```

**During "Humanity's Noise" (Earth Debris Mode):**
```
Deep ambient rumble (40% volume - constant)
  + Planetary sounds (reduced to 30% - overwhelmed)
    + Radio static (60% volume)
      + Telemetry beeps (50% volume)
        + Radar pings (40% volume)
          + Morse code (30% volume)
            + GPS signals (20% volume)
              = Anxious, crowded, urgent cacophony
```

**Transition Between Modes:**
- 20-30 second smooth crossfade
- Easing curve: slow start, quick middle, slow end
- Audio transition slightly leads visual (sound changes first, primes emotional response)

#### Curated Audio Journey (Full Session Example)

**Act I: Nature's Calm (8-10 minutes)**

*Deep Space Approach (2 min)*
- Pure solar wind, minimal texture
- Establishes vast emptiness
- Occasional cosmic ray "tick"

*Outer Planets (3 min)*
- Neptune's whispers fade in
- Uranus's eerie low tones
- Saturn's chirping rings crescendo
- Camera drifts past gas giants

*Jupiter Encounter (2 min)*
- Powerful electrical crackling
- Auroral storm rumbles
- Most dramatic planetary sound

*Inner System (3 min)*
- Mars's thin atmospheric wisps
- Earth's magnetosphere hum (foreshadowing)
- Approaching the "noise"...

**Act II: Humanity's Noise (5 minutes)**

*The Swarm Revealed (2 min)*
- Radio static fades in (first sign of human presence)
- Single telemetry beeps emerge
- Radar pings begin
- Camera starts zooming toward Earth

*Communication Overload (2 min)*
- Multiple satellite frequencies layering
- GPS signal chatter
- Morse code patterns
- ISS ambient sounds
- Debris field fills view

*Peak Chaos (1 min)*
- All human noise layers at full volume
- Natural space sounds buried underneath
- Almost uncomfortable density
- Visual swarm at maximum

**Act III: Return to Calm (2 minutes)**

*Perspective Restored*
- Camera slowly zooms back out
- Human noise gradually fades (20 sec)
- Natural space sounds reemerge
- Relief and contemplation
- Return to peaceful solar system view

#### Audio Sources & Attribution

**Primary Source: NASA (Public Domain)**
- Voyager Plasma Wave Data: https://voyager.jpl.nasa.gov/audio/
  - Jupiter's magnetosphere
  - Saturn's radio emissions
  - Interstellar plasma
  - Solar wind variations
- Cassini Saturn Recordings: https://saturn.jpl.nasa.gov/
- Juno Jupiter Audio: https://www.nasa.gov/juno
- Solar Dynamics Observatory: Solar flare recordings
- Van Allen Probes: Earth's radiation belt sounds

**Secondary Sources:**
- University of Iowa Radio & Plasma Wave Group: Planetary radio emissions
- ESA Rosetta Mission: Comet 67P "singing" (public domain)
- SETI Institute: Radio telescope recordings, pulsar signals
- International Space Station: Ambient station sounds (public domain)

**Processing & Licensing:**
- All sources verified as US Government work (public domain) or CC0
- No royalty obligations
- Commercial use permitted
- Attribution required (displayed in About screen)

#### Technical Implementation

**File Structure:**
```
Resources/Audio/
├── Ambient/
│   ├── solar_wind_loop_10min.mp3 (seamless)
│   ├── deep_space_rumble_15min.mp3 (seamless)
│   └── cosmic_background_20min.mp3 (seamless)
├── Planetary/
│   ├── jupiter_auroral_emissions_60sec.mp3
│   ├── saturn_radio_chirps_45sec.mp3
│   ├── earth_magnetosphere_30sec.mp3
│   ├── mars_atmospheric_30sec.mp3
│   ├── venus_static_30sec.mp3
│   └── outer_planets_blend_40sec.mp3
├── Human/
│   ├── radio_static_layer1.mp3 (loop)
│   ├── radio_static_layer2.mp3 (loop)
│   ├── telemetry_beeps_varied.mp3 (loop)
│   ├── radar_pings.mp3 (loop)
│   ├── morse_code_patterns.mp3 (loop)
│   ├── gps_signal_chatter.mp3 (loop)
│   └── iss_ambient_optional.mp3 (loop)
├── Events/
│   ├── solar_flare_burst.mp3 (one-shot)
│   ├── satellite_deploy_mechanical.mp3 (one-shot)
│   └── collision_warning_tone.mp3 (one-shot)
└── Credits/
    └── audio_attribution.txt
```

**AVAudioEngine Architecture (Swift):**

```swift
class AudioManager {
    var audioEngine = AVAudioEngine()
    
    // Layer players
    var ambientPlayer: AVAudioPlayerNode
    var planetaryPlayer: AVAudioPlayerNode
    var humanNoisePlayer: AVAudioPlayerNode
    var eventsPlayer: AVAudioPlayerNode
    
    // Mixer nodes for volume control
    var ambientMixer = AVAudioMixerNode()
    var planetaryMixer = AVAudioMixerNode()
    var humanNoiseMixer = AVAudioMixerNode()
    
    func transitionToEarthMode(duration: TimeInterval = 20.0) {
        // Fade in human noise
        humanNoiseMixer.volume.ramp(to: 1.0, duration: duration)
        
        // Reduce planetary sounds (overwhelmed)
        planetaryMixer.volume.ramp(to: 0.3, duration: duration)
        
        // Ambient stays constant (nature persists)
        // ambientMixer.volume remains at 0.4
    }
    
    func transitionToSolarMode(duration: TimeInterval = 20.0) {
        // Fade out human noise
        humanNoiseMixer.volume.ramp(to: 0.0, duration: duration)
        
        // Restore planetary sounds
        planetaryMixer.volume.ramp(to: 1.0, duration: duration)
    }
    
    func crossfadePlanet(to newPlanet: String, duration: TimeInterval = 5.0) {
        // Load new planetary audio
        let newAudio = loadAudio(named: newPlanet)
        
        // Crossfade using two players
        // [Implementation details...]
    }
    
    func triggerEvent(type: EventType) {
        switch type {
        case .solarFlare:
            playOneShot("solar_flare_burst")
        case .satelliteDeploy:
            playOneShot("satellite_deploy_mechanical")
        case .collision:
            playOneShot("collision_warning_tone")
        }
    }
}
```

**Audio Processing Guidelines:**
- **Normalization:** Keep all files at consistent -12dB to -6dB peak
- **EQ Processing:**
  - High-pass filter at 30Hz (remove subsonic rumble artifacts)
  - Subtle boost at 100-300Hz for "cosmic weight"
  - Gentle cut at 3-5kHz to reduce harshness
- **Reverb:** Very subtle space reverb on planetary sounds (1-2 second decay)
- **Stereo Field:**
  - Ambient: Wide stereo (spacious)
  - Planetary: Moderate stereo (localized)
  - Human noise: Narrow stereo (claustrophobic when dense)
- **Loop Points:**
  - Crossfade last 2 seconds with first 2 seconds
  - Analyze waveform to find zero-crossings
  - Test for seamless playback

**Performance Considerations:**
- Pre-load all audio files at launch (total ~50-100MB)
- Use compressed MP3/AAC (not WAV) to reduce memory
- Stream longest ambient loops if needed
- Limit simultaneous audio nodes to 8-10
- Use audio engine's built-in mixing (hardware accelerated)

#### Phase 1 Audio Implementation (MVP)

Minimal viable audio experience:
- One 10-minute ambient loop (solar wind + deep space blend)
- Three planetary snippets (Jupiter, Saturn, Earth - most distinctive)
- One human noise layer (mixed radio static + telemetry beeps)
- Simple crossfade logic (based on camera mode only)
- Volume controls (master + enable/disable toggle)

**Why this works:**
- Establishes the core audio concept
- Legally clean and easy to source
- Low complexity, high impact
- Can expand in future updates

#### Future Audio Enhancements (Post-Launch)

**Phase 2:**
- Individual sounds for all 8 planets
- Multiple human noise layers (separately controllable)
- Event-triggered audio (solar flares, satellite launches)

**Phase 3:**
- Mission voice clips (optional, with toggle)
- Dynamic mixing based on object proximity
- Spatial audio (objects passing "by" the listener)
- Binaural processing for headphones

**Phase 4:**
- Real-time audio synthesis (procedural space sounds)
- User-uploadable audio packs
- Integration with music apps (gentle crossfade when user plays music)

---

### 7. Technical Architecture

#### Core Technologies

**macOS Version:**
- **3D Engine:** SceneKit (native macOS, GPU-accelerated)
- **Language:** Swift 5.9+
- **Minimum OS:** macOS 13.0 (Ventura)
- **Minimum Hardware:** Apple Silicon (M1 or newer)
- **Target Performance:** 60fps on all Apple Silicon Macs
- **Deployment:** .saver bundle for System Preferences

**tvOS Version (Apple TV):**
- **3D Engine:** SceneKit (same codebase, optimized for TV)
- **Language:** Swift 5.9+
- **Minimum OS:** tvOS 17.0
- **Minimum Hardware:** Apple TV 4K (2nd gen or newer, A12 chip+)
- **Target Performance:** 60fps at 4K output, 30fps at 8K output (future Apple TV)
- **Deployment:** .app bundle for tvOS App Store
- **Input:** Siri Remote for settings access, auto-starts after idle timeout

#### Data Pipeline

```
CelesTrak TLE API → Daily fetch → Local cache (JSON) 
                                      ↓
                   SGP4 Propagator → Real-time positions
                                      ↓
                   SceneKit Particle System → GPU Rendering
```

#### Platform-Specific Considerations

**macOS (Desktop/Laptop):**
- Settings accessed via System Preferences
- Audio defaults to OFF (work environment consideration)
- Info overlays show by default (educational context)
- Can run indefinitely
- Typical session: 5-30 minutes

**tvOS (Apple TV - Living Room):**
- Settings accessed via Siri Remote or iPhone/iPad companion app
- Audio defaults to ON (home theater environment)
- Info overlays minimal by default (less intrusive on big screen)
- Optimized for 4K HDR displays
- Conversation-starting mode: Maximum visual impact
  - Longer dwell time on each planet (guests can appreciate detail)
  - More dramatic Earth debris reveal
  - Optional: Brief text prompts like "40,000 objects orbiting Earth" that fade in
  - Designed to make people stop mid-conversation
- Typical session: 20 minutes to all evening
- Integrates with Apple TV's native screensaver system
- Can preview in tvOS Settings → Screen Saver

**Shared Codebase:**
- 95% code reuse between platforms
- Platform-specific UI adaptations
- Different default configurations
- Shared texture and audio assets

#### Performance Optimization

- Instanced rendering for satellites (single draw call)
- Frustum culling (only render visible objects)
- LOD system (detailed models when close, points when far)
- High-resolution texture streaming (8K planetary textures)
- Metal-accelerated particle systems for Apple Silicon
- Lazy loading of high-res assets
- Target: Consistent 60fps on M1 and newer Macs
- No performance compromises - built exclusively for Apple Silicon's GPU capabilities

#### File Structure

```
NatureVsNoise.saver/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── NatureVsNoise (executable)
│   └── Resources/
│       ├── Textures/
│       │   ├── 8K/ (8192x4096 main textures)
│       │   │   ├── sun_8k.jpg
│       │   │   ├── mercury_8k.jpg
│       │   │   ├── venus_surface_8k.jpg
│       │   │   ├── venus_atmosphere_8k.jpg
│       │   │   ├── earth_8k_day.jpg
│       │   │   ├── earth_8k_night.jpg
│       │   │   ├── earth_8k_clouds.png (transparency)
│       │   │   ├── earth_8k_specular.jpg
│       │   │   ├── earth_8k_normal.jpg
│       │   │   ├── mars_8k.jpg
│       │   │   ├── jupiter_8k.jpg
│       │   │   ├── saturn_8k.jpg
│       │   │   ├── saturn_rings_16k.png (transparency)
│       │   │   ├── uranus_8k.jpg
│       │   │   └── neptune_8k.jpg
│       │   ├── 4K/ (4096x2048 for moons)
│       │   │   ├── moon_4k.jpg
│       │   │   ├── io_4k.jpg
│       │   │   ├── europa_4k.jpg
│       │   │   ├── ganymede_4k.jpg
│       │   │   ├── callisto_4k.jpg
│       │   │   └── titan_4k.jpg
│       │   └── Normal_Maps/
│       │       ├── earth_normal_4k.jpg
│       │       ├── mars_normal_4k.jpg
│       │       └── moon_normal_4k.jpg
│       ├── Data/
│       │   ├── tle_cache.json
│       │   └── launch_schedule.json
│       └── Audio/
│           ├── Ambient/
│           ├── Planetary/
│           ├── Human/
│           └── Events/
```

---

## User Stories

### Primary Audience

**The Contemplative User**  
*"I want a screensaver that makes me think about humanity's place in the universe while being beautiful to watch."*

**The Space Enthusiast**  
*"I want to see real satellite data and learn about orbital mechanics in an engaging way."*

**The Minimalist**  
*"I just want serene, beautiful planets without any clutter or information overload."*

**The Educator**  
*"I want something I can use in a classroom to spark discussion about space sustainability."*

### Use Cases

- **Idle Display at Work:** Professional setting, subtle and non-distracting
- **Home Entertainment:** Conversation starter, guests ask "what is that?"
- **Educational Setting:** Classroom or museum exhibit mode
- **Meditation/Focus:** Pure nature mode during work breaks
- **Advocacy Tool:** Environmental/space policy discussions

---

## Success Metrics

### Qualitative
- User reports feeling "meditative" or "contemplative"
- Generates conversation about space debris
- Users choose to watch actively rather than just letting it run

### Quantitative
- Average session length >5 minutes (user actively watching)
- <1% crash rate
- Maintains 30+ fps on target hardware
- Downloads/installs (if distributed publicly)

### Engagement Indicators
- Settings panel opened (users exploring options)
- Mode switching frequency
- Feature toggles used most (indicates which features resonate)

---

## Development Phases

### Phase 1: Core Visuals (MVP)
**Goal:** Prove the concept works and feels right

- Basic solar system with 8 planets
- Complete 12-15 minute camera choreography (full grand tour)
- Mock satellite particle system (no real data)
- Basic configuration panel
- macOS screensaver (.saver bundle)
- Phase 1 Audio: Single ambient loop + 3 planetary sounds + basic human noise layer

**Timeline:** 3-4 weeks

### Phase 2: Real Data Integration
**Goal:** Make it scientifically accurate

- TLE data fetching and parsing
- SGP4 propagation implementation
- Realistic satellite motion
- Country-based coloring

**Timeline:** 2-3 weeks

### Phase 3: Polish & Features (macOS completion)
**Goal:** Make it beautiful and informative

- High-quality planetary textures (8K)
- Statistics overlay
- Launch notifications
- Enhanced visual effects (trails, flashes, pulses)
- Full audio implementation: All planetary sounds, layered human noise, event triggers
- Performance optimization

**Timeline:** 2-3 weeks

### Phase 4: Apple TV Port
**Goal:** Bring it to the living room

- Port to tvOS with platform-specific optimizations
- 4K HDR output pipeline
- Apple TV Settings integration
- Siri Remote controls
- Living room-optimized defaults (audio ON, minimal overlays)
- Conversation-starting mode refinements
- App Store submission preparation

**Timeline:** 3-4 weeks

### Phase 5: Advanced Features (Post-Launch, Both Platforms)
**Goal:** Differentiate and add depth

- Mission voice clips (optional toggle)
- Spatial/binaural audio for headphones
- Historical timeline animation
- City lights on Earth (enhanced night mode)
- Collision warnings
- Advanced camera choreography variations
- Dynamic audio mixing based on proximity
- tvOS exclusive: Dolby Atmos audio support

**Timeline:** Ongoing

---

## Technical Challenges & Solutions

### Challenge 1: Rendering 40,000 Objects
**Problem:** Too many particles for real-time 3D

**Solution:**
- GPU instancing for identical geometries
- Render only visible objects (frustum culling)
- Use billboard sprites for distant objects
- Statistical sampling (show representative subset)

### Challenge 2: Accurate Orbital Mechanics
**Problem:** SGP4 is computationally expensive for 40K objects

**Solution:**
- Pre-compute positions for next 24 hours at 1-minute intervals
- Interpolate between cached positions
- Update cache daily in background

### Challenge 3: Smooth Transitions
**Problem:** Jarring switch between calm/chaos

**Solution:**
- 20-30 second zoom with easing curves
- Depth-of-field blur during transition
- Gradual particle fade-in/out
- Audio crossfade (if enabled)

### Challenge 4: Data Freshness
**Problem:** TLE data goes stale, launches happen frequently

**Solution:**
- Daily automatic updates via background task
- Graceful degradation if fetch fails (use cached data)
- Optional manual refresh in settings
- Show "last updated" timestamp

### Challenge 5: High-Resolution Textures on Apple Silicon
**Problem:** 8K textures are large (50-150MB each), could impact memory/performance

**Solution:**
- Apple Silicon's unified memory architecture handles large textures efficiently
- Use GPU texture compression (ASTC for Metal)
- Stream textures progressively (load lower-res first, upgrade to 8K)
- Metal's shared memory pool allows textures to stay resident
- Total texture memory budget: 2-3GB (acceptable on Apple Silicon with 8GB+ unified memory)
- Pre-compress textures at build time for optimal loading

---

## Open Questions & Decisions Needed

### Distribution Method
- **Option A:** GitHub open-source (free, community-driven)
- **Option B:** Mac App Store ($2.99, easier updates)
- **Option C:** Direct download from website (donation-ware)

**Recommendation:** Hybrid approach (see Distribution Strategy section)

### Audio Default State
- Audio OFF by default (safer, less intrusive)?
- Audio ON by default (stronger experience, might surprise users)?

**Recommendation:** OFF with prominent "Try with sound!" prompt on first launch

### Mission Voice Clips
- Include sparse ISS/Apollo audio fragments?
- **Pro:** Adds human element, atmospheric
- **Con:** Could break immersion

**Recommendation:** Optional toggle, OFF by default

### Planet Selection
- Include dwarf planets (Pluto, Ceres, Eris)?
- Show asteroid belt?
- Include Kuiper Belt objects?

**Recommendation:** Start with 8 major planets, add dwarf planets in Phase 4

### Debris Visualization Philosophy
- Accurate = overwhelming (40K dots)
- Representative = clearer message (5K dots)
- Hybrid approach based on camera distance?

**Recommendation:** Adaptive based on GPU capability and camera distance

### Educational Tone
- Neutral/scientific only?
- Subtle advocacy for space sustainability?
- Include solutions (debris removal tech)?

**Recommendation:** Neutral facts with optional "solutions" toggle in settings

### Future Features
- VR/AR mode?
- Interactive mode (click to learn about satellites)?
- Social sharing (screenshot with stats)?
- Integration with live ISS tracking?

**Recommendation:** Assess after v1.0 launch based on user feedback

---

## Distribution & Monetization Strategy

### Recommended Approach: Multi-Platform Hybrid Model

#### Open Source Core on GitHub (Free)

**Repository:** github.com/yourusername/nature-vs-noise-screensaver  
**License:** MIT (allows commercial use, community contributions)

- Free for personal use
- macOS only in open-source version
- Includes basic audio (1 ambient loop + 3 planetary sounds)
- Builds community credibility and trust
- Great for portfolio/resume

#### Premium Version (Paid) - macOS

**Where to Sell:**

**Primary: Gumroad ($4.99-9.99)**
- 10% fee (much better than App Store's 30%)
- Simple checkout, handles VAT/taxes
- License key generation
- URL: gumroad.com/yourusername/nature-vs-noise

**Secondary: Own website with Stripe**
- Domain: naturevsnoise.app or spaceserenity.app
- Keep 95%+ of revenue (just Stripe fees ~2.9%)
- Full control over branding
- Build email list for future products

**Premium Features (macOS):**
- Ultra-high-resolution 8K planetary textures (compressed to ~2-3GB total)
- Multi-layer textures (diffuse, specular, normal maps for Earth and Mars)
- Animated cloud layers for Earth and gas giants
- Dynamic city lights on Earth's night side
- Full audio suite (all planetary sounds, layered human noise)
- Mission voice clips (optional)
- Advanced camera choreography
- Real-time launch notifications
- Historical timeline animations
- Priority support & updates
- Educational institution license option

#### Apple TV Version - tvOS App Store

**Where to Sell:**  
Exclusive: tvOS App Store ($4.99 one-time or $0.99/month subscription)

Apple takes 30% cut, but provides:
- Built-in payment processing
- Automatic updates
- Easy discovery on Apple TV
- Family Sharing support
- Legitimacy and trust

**Why Apple TV is Perfect for This:**
- **Living Room Impact:** Big screen 4K/8K display makes visuals stunning
- **Social Experience:** Guests will ask "what is that debris cloud?"
- **Ambient Entertainment:** Perfect for dinner parties, background at gatherings
- **Conversation Starter:** Natural lead-in to space sustainability discussions
- **Premium Market:** Apple TV owners skew toward people who pay for quality apps
- **Underserved Category:** Very few high-quality screensavers on tvOS
- **Viral Potential:** "You have to see this on my Apple TV" word-of-mouth

**tvOS-Specific Features:**
- 4K HDR output optimized for OLED/QLED TVs
- Audio defaults to ON (designed for home theater)
- "Ambient mode" that runs all evening
- Siri integration: "Hey Siri, show me space debris"
- Minimal overlays (cleaner for TV viewing)
- "Party Mode": More dramatic reveals, longer planet dwell times, conversation-stopping moments

### Pricing Tiers

#### macOS (Gumroad/Website)

**Basic ($4.99) - Enhanced Experience**
- All open-source features
- 8K planetary textures (full quality)
- Normal and specular maps for enhanced realism
- Full audio suite
- Email support
- Lifetime updates

**Pro ($9.99) - Complete Package**
- Everything in Basic
- Animated cloud layers (Earth and gas giants)
- Dynamic city lights on Earth
- Advanced camera choreography
- Real-time launch notifications
- Historical debris timeline
- Mission voice clips
- Priority feature requests
- Remove "Made with love by..." attribution (optional)

**Supporter ($19.99) - Fund Development**
- Everything in Pro
- Early access to new features (beta builds)
- Your name in credits
- Custom configuration presets
- Educational institution multi-license (5 computers)
- Direct feature request line
- 4K wallpaper pack (still frames from screensaver)

#### tvOS (Apple TV App Store)

**Option A: One-Time Purchase ($4.99)**
- Complete experience, all features
- 4K HDR optimized
- All camera modes
- Full audio suite
- Family Sharing enabled
- Best for: Users who want to own it outright

**Option B: Subscription ($0.99/month or $9.99/year)**
- Same features as one-time purchase
- Continuous updates and new content
- Monthly "featured planet" with extended footage
- New audio themes added quarterly
- Best for: Recurring revenue, long-term sustainability

**Recommendation:** Offer both options on tvOS, let users choose. Many will prefer one-time $4.99 for simplicity.

---

## Marketing & Launch Strategy

### Pre-Launch (Build Hype - 2 weeks before)

- Tweet development progress with GIFs/videos
- Post on Reddit: r/MacOS, r/Apple, r/Space, r/screensavers, r/AppleTV
- Share on Hacker News: "I built a screensaver contrasting cosmic serenity with orbital chaos"
- Create Product Hunt page (schedule launch date)
- Record living room demo video: Show it running on 65" OLED with people reacting
- Reach out to space/tech journalists

### Launch Week

- **Day 1:** GitHub release v1.0 (macOS only)
- **Day 2:** Submit to Product Hunt (aim for #1 Product of the Day)
- **Day 3:** Post demo video on YouTube showing both Mac and Apple TV living room experience
- **Day 4:** Write blog post: "Why I built this screensaver (and what it taught me about space debris)"
- **Day 5:** Share on Twitter, Mastodon, Bluesky with demo GIF
- **Week 2:** Submit tvOS version to App Store review
- **Throughout:** Engage with comments, answer questions

### Distribution Channels

- MacRumors Forums: Post in screensaver/customization threads
- iMore, 9to5Mac: Pitch as news story about unique macOS/tvOS screensaver
- Space Twitter: Tag space journalists, NASA accounts, astronauts
- Education Market: Reach out to science teachers, planetariums, science museums
- Corporate Market: Pitch to aerospace companies (SpaceX, Blue Origin, NASA offices could run this in lobbies)
- Design Communities: Behance, Dribbble (visual showcase)
- Apple TV Communities: r/AppleTV, Apple TV Forums, "Best Apple TV Apps" lists
- Home Theater Forums: AVSForum, Reddit r/hometheater (perfect ambient content)

### Content Marketing

- **Blog:** "The hidden crisis of space debris, visualized in your living room"
- **YouTube:** "Making a data-driven space screensaver with real NASA audio for Apple TV"
- **Medium:** "What 40,000 satellites look like on a 75-inch OLED"
- **TikTok/Shorts:** 15-second clips of guests reacting to the debris reveal
- **Instagram:** Beautiful stills from the 8K planetary renders

### Apple TV-Specific Marketing

- **Demo video hook:** "This is what 40,000 pieces of space junk look like on your TV"
- **Social proof:** Record friends/family seeing it for first time, genuine reactions
- **Before/After:** Compare to boring default Apple TV screensavers (aerial shots)
- **Pitch angle:** "The screensaver that starts conversations at dinner parties"
- **Target audience:** Tech enthusiasts, space nerds, home theater fans, educators, dinner party hosts

---

## Revenue Projections (Conservative)

### macOS Only (Year 1)
- 500 downloads @ $4.99 (Basic) = $2,495
- 200 downloads @ $9.99 (Pro) = $1,998
- 50 downloads @ $19.99 (Supporter) = $1,000
- **Total:** ~$5,500 (after Gumroad/Stripe fees)

### macOS + Apple TV (Year 1)

**Scenario 1: Modest Success**
- macOS: $5,500 (as above)
- Apple TV: 1,000 downloads @ $4.99 = ~$3,500 (after Apple's 30% cut)
- **Total:** ~$9,000

**Scenario 2: Featured on Apple TV or Viral on Social**
- macOS: $22,000 (viral on Product Hunt/HN)
- Apple TV: 10,000 downloads @ $4.99 = ~$35,000 (after Apple's cut)
- **Total:** ~$57,000

**Scenario 3: App Store "Editor's Choice" + Major Press**
- macOS: $50,000 (featured by Apple, tech press coverage)
- Apple TV: 50,000 downloads @ $4.99 = ~$175,000
- Subscriptions: 2,000 subs @ $9.99/year = ~$14,000
- **Total:** ~$239,000

### Why Apple TV Has Higher Potential

- Larger addressable market (50M+ Apple TV devices vs. ~20M active Mac users who customize)
- App Store discoverability (Featured section, Search)
- Perfect use case (living room ambient entertainment)
- Higher engagement (people run screensavers for hours on TV vs. minutes on Mac)
- Viral social potential ("you have to see this at my place")
- Underserved category (very few quality screensavers on tvOS)

### Additional Revenue Streams

**Educational Licenses ($49-99 per institution)**
- Bulk pricing for schools/universities
- Custom branding option (school logo)
- Perpetual license for all computers
- Curriculum integration guide

**Corporate Licenses ($199-499)**
- Deploy across entire organization
- Custom company branding
- White-label option
- API access for custom integrations

**Affiliate Program**
- 20% commission for influencers
- Recruit space YouTubers, tech bloggers
- Provide promo codes and marketing materials

**Merchandise (Future, if successful)**
- Posters of planetary visualizations
- T-shirts with "40,000 objects orbiting Earth" design
- Coffee table book: "Space Debris Visualized"
- Prints of screensaver stills

### Mac App Store Considerations

**Pros:**
- Built-in payment processing
- Automatic updates
- Credibility & discoverability
- Easier for non-technical users

**Cons:**
- 30% Apple commission (significant)
- Review process delays (1-3 days per update)
- Screensavers are tricky (must wrap as app that installs .saver file)
- Less control over pricing/promotions

**Recommendation:**
- Start with GitHub + Gumroad/website
- Consider Mac App Store for v2.0 if there's demand
- Charge $7.99 on App Store (to compensate for 30% fee)

---

## Legal & Business Setup

### Must Handle
- ✅ NASA textures (public domain, cite source)
- ✅ NASA audio (public domain, cite source)
- ✅ TLE data (public from CelesTrak)
- ✅ Privacy policy (even if you collect nothing)
- ✅ Terms of service (standard EULA)
- ✅ Export compliance check (no encryption = usually exempt)

### Recommended
- Form LLC (protect personal assets) - $100-500 depending on state
- Business bank account (separate finances)
- Basic liability insurance (optional for software, ~$500/year)
- Use standard open-source license (MIT) for free version

---

## Timeline to Launch

- **Week 1-4:** Build MVP (Phase 1) - macOS core with full 12-15 min choreography
- **Week 5-7:** Add real data (Phase 2) - TLE integration, SGP4 propagation
- **Week 8-10:** Polish macOS (Phase 3) - 8K textures, full audio, effects
- **Week 11:** macOS beta test with 20-30 users, gather feedback
- **Week 12:** Launch macOS version (GitHub + Gumroad/website)
- **Week 13-16:** Port to tvOS (Phase 4) - Platform-specific optimizations
- **Week 17:** tvOS beta via TestFlight
- **Week 18:** Submit to Apple TV App Store
- **Week 19-20:** App Store review (typically 1-2 weeks for tvOS)
- **Week 21:** tvOS launch! 🚀

**Total time to both platforms:** ~5 months

### Initial Setup Costs
- Domain name: ~$15/year (naturevsnoise.app)
- Gumroad account: Free (10% per sale)
- Landing page hosting: $19/year (Carrd.co) or free (GitHub Pages)
- Apple Developer Program: $99/year (required for tvOS App Store)
- LLC formation: $100-500 (optional for v1.0, recommended before significant revenue)

**Total:** $234-633

---

## Appendix: Data Sources

### Orbital Elements

**CelesTrak:** https://celestrak.org/
- Active satellites: https://celestrak.org/NORAD/elements/gp.php?GROUP=active&FORMAT=tle
- Debris: https://celestrak.org/NORAD/elements/gp.php?GROUP=debris&FORMAT=tle

### Launch Schedules
- NextSpaceflight API: https://ll.thespacedevs.com/2.2.0/launch/upcoming/
- Space-Track.org: https://www.space-track.org/ (requires free account)

### Statistics
- ESA Space Debris Office: https://www.esa.int/Space_Safety/Space_Debris
- NASA Orbital Debris Program: https://orbitaldebris.jsc.nasa.gov/

### Planetary Textures (8K Resolution)
- NASA's Visible Earth: https://visibleearth.nasa.gov/ (Earth 8K textures)
- NASA Solar System Exploration: https://solarsystem.nasa.gov/resources/
- Solar System Scope Textures: https://www.solarsystemscope.com/textures/ (up to 8K, free for non-commercial)
- NASA Scientific Visualization Studio: https://svs.gsfc.nasa.gov/ (highest quality)
- JHT's Planetary Pixel Emporium: http://planetpixelemporium.com/planets.html (free 8K+)
- NASA's Blue Marble: https://visibleearth.nasa.gov/collection/1484/blue-marble (Earth 21,600×10,800!)
- USGS Astrogeology: https://astrogeology.usgs.gov/search (official planetary maps)
- Björn Jónsson's Planetary Maps: http://bjj.mmedia.is/ (high-quality processed versions)

### Space Audio Recordings (All Public Domain)
- NASA Voyager Sounds: https://voyager.jpl.nasa.gov/audio/
- NASA/JPL Audio Collection: https://www.jpl.nasa.gov/audio/
- University of Iowa Radio & Plasma Wave Group: http://www-pw.physics.uiowa.edu/
- NASA Space Sounds: https://www.nasa.gov/connect/sounds/
- Cassini Saturn Audio: https://saturn.jpl.nasa.gov/
- NASA SoundCloud (Public Domain): https://soundcloud.com/nasa

---

## Conclusion

"Nature's Calm vs. Humanity's Noise" aims to be more than just a screensaver—it's a meditation on our relationship with space, a visualization of hidden realities, and a call to contemplation about sustainability beyond Earth. By contrasting cosmic serenity with orbital chaos, we create an experience that is simultaneously beautiful, educational, and thought-provoking.

The screensaver should leave viewers with a quiet sense of wonder mixed with unease—wonder at the scale and beauty of our solar system, and unease at how quickly we're filling near-Earth space with our artifacts. Without being preachy, it asks: "What kind of cosmic neighbors do we want to be?"

**Next Step:** Review and approve this PRD, then begin Phase 1 development with focus on core visuals and camera choreography.
