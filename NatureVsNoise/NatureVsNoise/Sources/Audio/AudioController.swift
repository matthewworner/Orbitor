import AVFoundation
import SceneKit

/// Manages the immersive audio experience
/// "Nature's Calm vs. Humanity's Noise"
class AudioController {
    
    // MARK: - Properties
    
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    // Audio Layers
    private let layerAmbient = AudioLayer(name: "ambient_solar_wind", volume: 0.5)
    private let layerHuman = AudioLayer(name: "human_radio_noise", volume: 0.0)

    // Planet Layers (Dictionary for specific voices)
    private var planetLayers: [String: AudioLayer] = [:]
    private var currentPlanetName: String?

    // Mission Voice Clips (Phase 4)
    private var missionLayers: [String: AudioLayer] = [:]
    private var currentMissionClip: String?
    
    // State
    private var isEngineRunning = false

    // Spatial Audio (Phase 4)
    private var spatialMixer: AVAudioEnvironmentNode?
    private var listenerPosition: AVAudio3DPoint = AVAudio3DPoint(x: 0, y: 0, z: 0)
    
    // MARK: - Initialization
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        // Setup spatial audio environment (Phase 4)
        spatialMixer = AVAudioEnvironmentNode()
        engine.attach(spatialMixer!)
        engine.connect(spatialMixer!, to: engine.outputNode, format: nil)

        // Configure spatial environment
        spatialMixer?.renderingAlgorithm = .HRTF
        spatialMixer?.distanceAttenuationParameters.distanceAttenuationModel = .exponential
        spatialMixer?.distanceAttenuationParameters.referenceDistance = 10.0
        spatialMixer?.distanceAttenuationParameters.maximumDistance = 100.0
        spatialMixer?.distanceAttenuationParameters.rolloffFactor = 2.0

        // Attach regular mixer for non-spatial audio
        engine.attach(mixer)
        engine.connect(mixer, to: spatialMixer!, format: nil)
        
        // Setup fixed layers
        setupLayer(layerAmbient)
        setupLayer(layerHuman)
        
        // Setup planet layers (Even if files are missing, we register them)
        let planets = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
        for p in planets {
            let layer = AudioLayer(name: "planet_\(p.lowercased())", volume: 0.0)
            planetLayers[p] = layer
            setupLayer(layer)
        }

        // Setup mission voice clips (Phase 4)
        let missionClips = ["apollo_11_moon_landing", "voyager_golden_record", "hubble_launch", "iss_construction", "perseverance_mars_landing"]
        for clip in missionClips {
            let layer = AudioLayer(name: "mission_\(clip)", volume: 0.0)
            missionLayers[clip] = layer
            setupLayer(layer)
        }
        
        // Start engine
        do {
            try engine.start()
            isEngineRunning = true
            print("🔊 AudioController: Engine started with \(planetLayers.count + missionLayers.count + 2) layers")
        } catch {
            print("❌ AudioController: Failed to start engine: \(error)")
        }
    }
    
    private func setupLayer(_ layer: AudioLayer) {
        engine.attach(layer.player)
        engine.connect(layer.player, to: mixer, format: nil)
        
        // Load content
        if let url = bundleURL(for: layer.name) {
            do {
                let file = try AVAudioFile(forReading: url)
                layer.buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
                try file.read(into: layer.buffer!)
                
                // Loop
                layer.player.scheduleBuffer(layer.buffer!, at: nil, options: .loops, completionHandler: nil)
                layer.player.volume = layer.targetVolume
                layer.player.play()
                // print("   Layer '\(layer.name)' loaded")
            } catch {
                print("⚠️ AudioController: Failed to load \(layer.name): \(error)")
            }
        } else {
            // print("⚠️ AudioController: Audio file '\(layer.name)' not found - Silent placeholder")
        }
    }
    
    // MARK: - Updates
    
    /// Updates audio mix based on camera position and target
    func update(cameraPosition: SCNVector3, targetNode: SCNNode?) {
        guard isEngineRunning else { return }

        // Update spatial listener position (Phase 4)
        listenerPosition = AVAudio3DPoint(x: cameraPosition.x, y: cameraPosition.y, z: cameraPosition.z)
        spatialMixer?.listenerPosition = listenerPosition

        // Logic:
        // 1. Distance from sun -> Ambient shifts (Deep vs Bright)
        // 2. Proximity to Earth -> Human Noise increases
        // 3. Target Planet -> Specific Planet Voice increases, others fade out

        let distanceToOrigin = sqrt(cameraPosition.x*cameraPosition.x + cameraPosition.y*cameraPosition.y + cameraPosition.z*cameraPosition.z)
        let distanceToEarth = distance(from: cameraPosition, to: SCNVector3(30, 0, 0)) // Earth is at 30

        // Human Layer: Strongest near Earth, falls off quickly
        // < 5 units: 100%, > 20 units: 0%
        let earthProximity = 1.0 - simd_clamp((distanceToEarth - 2.0) / 15.0, 0.0, 1.0)
        layerHuman.player.volume = Float(earthProximity)

        // Identify target planet
        var targetName: String? = nil
        var targetPosition: SCNVector3?
        if let node = targetNode, node.name != "Sun" {
            targetName = node.name
            targetPosition = node.position
        }

        // Crossfade planets with spatial positioning
        for (name, layer) in planetLayers {
            let targetVol: Float = (name == targetName) ? 0.8 : 0.0

            // Smooth lerp for volume transition
            let current = layer.player.volume
            let step: Float = 0.02 // Slow fade

            if abs(current - targetVol) > 0.001 {
                let newVol = current + (targetVol - current) * step
                layer.player.volume = newVol
            }

            // Update spatial position for active planet (Phase 4)
            if name == targetName, let position = targetPosition {
                layer.player.position = AVAudio3DPoint(x: position.x, y: position.y, z: position.z)
            }
        }

        // Ambient: Always on, maybe modulated by speed
        layerAmbient.player.volume = 0.3
    }

    /// Plays a mission voice clip (Phase 4 feature)
    func playMissionClip(_ clipName: String) {
        guard isEngineRunning, let layer = missionLayers[clipName] else { return }

        // Stop current mission clip if playing
        if let currentClip = currentMissionClip, let currentLayer = missionLayers[currentClip] {
            currentLayer.player.stop()
            currentLayer.player.volume = 0.0
        }

        // Play new clip
        layer.player.volume = 0.7
        if layer.buffer != nil {
            layer.player.scheduleBuffer(layer.buffer!, at: nil, options: .interrupts, completionHandler: nil)
            layer.player.play()
            currentMissionClip = clipName

            #if DEBUG
            print("🎵 AudioController: Playing mission clip '\(clipName)'")
            #endif
        }
    }

    /// Stops current mission clip
    func stopMissionClip() {
        guard let currentClip = currentMissionClip, let layer = missionLayers[currentClip] else { return }
        layer.player.stop()
        layer.player.volume = 0.0
        currentMissionClip = nil
    }

    /// Toggles mute state for all audio
    func toggleMute() {
        // Simple implementation: toggle ambient layer volume
        let newVolume: Float = layerAmbient.player.volume > 0 ? 0.0 : 0.3
        layerAmbient.player.volume = newVolume

        // Also mute/unmute other layers proportionally
        let planetMultiplier: Float = newVolume > 0 ? 1.0 : 0.0
        for layer in planetLayers.values {
            layer.player.volume *= planetMultiplier
        }
        layerHuman.player.volume *= planetMultiplier

        #if DEBUG
        print("🔊 AudioController: Audio \(newVolume > 0 ? "unmuted" : "muted")")
        #endif
    }
    
    // MARK: - Helpers
    
    private func bundleURL(for name: String) -> URL? {
        // Try mp3, wav, m4a
        let bundle = Bundle(for: type(of: self))
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
            // Check Resources/Audio subdirectory if needed
            if let path = bundle.path(forResource: name, ofType: ext, inDirectory: "Audio") {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    private func distance(from v1: SCNVector3, to v2: SCNVector3) -> Float {
        let dx = v1.x - v2.x
        let dy = v1.y - v2.y
        let dz = v1.z - v2.z
        return sqrt(Float(dx*dx + dy*dy + dz*dz))
    }
}

// MARK: - Helper Types

private class AudioLayer {
    let name: String
    var targetVolume: Float
    let player = AVAudioPlayerNode()
    var buffer: AVAudioPCMBuffer?
    
    init(name: String, volume: Float) {
        self.name = name
        self.targetVolume = volume
    }
}
