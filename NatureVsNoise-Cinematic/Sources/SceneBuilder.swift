import SceneKit
import AppKit

/// Builds the SceneKit scene for the Kubrick screensaver
/// Encapsulates all celestial body and environment creation
public final class SceneBuilder {
    
    private let scene: SCNScene
    private weak var sceneView: SCNView?
    
    public init(scene: SCNScene, sceneView: SCNView? = nil) {
        self.scene = scene
        self.sceneView = sceneView
    }
    
    // MARK: - Scene Setup
    
    public func createSceneView(frame: CGRect, delegate: SCNSceneRendererDelegate?) -> SCNView {
        let view = SCNView(frame: frame)
        view.autoresizingMask = [.width, .height]
        view.backgroundColor = NSColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1.0)
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.delegate = delegate
        view.scene = scene
        view.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: true)
        view.isPlaying = true
        return view
    }
    
    public func setupCamera() -> (pivot: SCNNode, camera: SCNNode) {
        let cameraPivot = SCNNode()
        cameraPivot.name = "cameraPivot"
        scene.rootNode.addChildNode(cameraPivot)
        
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 500
        cameraPivot.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(0, 3, 14)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        return (cameraPivot, cameraNode)
    }
    
    // MARK: - Celestial Bodies
    
    public func addEarth() -> SCNNode {
        let earthGeo = SCNSphere(radius: 2.0)
        earthGeo.segmentCount = 96
        
        let earthMat = SCNMaterial()
        earthMat.lightingModel = .physicallyBased
        earthMat.metalness.contents = 0.1
        earthMat.roughness.contents = 0.6
        
        // Load Earth texture
        if let earthTexture = TextureManager.shared.load(named: "earth_8k_day") {
            earthMat.diffuse.contents = earthTexture
            
            if let nightTexture = TextureManager.shared.load(named: "earth_8k_night") {
                earthMat.emission.contents = nightTexture
                earthMat.emission.intensity = 0.5
            }
        } else {
            earthMat.diffuse.contents = NSColor(red: 0.08, green: 0.15, blue: 0.35, alpha: 1.0)
            earthMat.emission.contents = NSColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.6)
            earthMat.emission.intensity = 0.5
        }
        
        earthGeo.materials = [earthMat]
        
        let earth = SCNNode(geometry: earthGeo)
        earth.name = "Earth"
        scene.rootNode.addChildNode(earth)
        
        // Clouds layer
        if let cloudsTexture = TextureManager.shared.load(named: "earth_8k_clouds") {
            let cloudsGeo = SCNSphere(radius: 2.05)
            let cloudsMat = SCNMaterial()
            cloudsMat.diffuse.contents = cloudsTexture
            cloudsMat.transparent.contents = cloudsTexture
            cloudsMat.transparencyMode = .default
            cloudsMat.isDoubleSided = true
            cloudsMat.lightingModel = .physicallyBased
            cloudsGeo.materials = [cloudsMat]
            
            let cloudsNode = SCNNode(geometry: cloudsGeo)
            cloudsNode.name = "Clouds"
            let cloudRotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 50)
            cloudsNode.runAction(SCNAction.repeatForever(cloudRotation))
            scene.rootNode.addChildNode(cloudsNode)
        }
        
        // Atmosphere glow
        let atmoGeo = SCNSphere(radius: 2.15)
        let atmoMat = SCNMaterial()
        atmoMat.diffuse.contents = NSColor.clear
        atmoMat.emission.contents = NSColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.15)
        atmoMat.emission.intensity = 1.0
        atmoMat.lightingModel = .constant
        atmoMat.isDoubleSided = true
        atmoMat.blendMode = .add
        atmoGeo.materials = [atmoMat]
        scene.rootNode.addChildNode(SCNNode(geometry: atmoGeo))
        
        return earth
    }
    
    public func addSun() -> (node: SCNNode, position: SCNVector3) {
        let sunGeo = SCNSphere(radius: 8)
        sunGeo.segmentCount = 48
        
        let sunMat = SCNMaterial()
        sunMat.lightingModel = .constant
        
        if let sunTexture = TextureManager.shared.load(named: "sun_8k") {
            sunMat.diffuse.contents = sunTexture
            sunMat.emission.contents = sunTexture
        } else {
            sunMat.diffuse.contents = NSColor(red: 1.0, green: 0.98, blue: 0.85, alpha: 1.0)
            sunMat.emission.contents = NSColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
        }
        sunMat.emission.intensity = 3.0
        sunGeo.materials = [sunMat]
        
        let sun = SCNNode(geometry: sunGeo)
        sun.name = "Sun"
        let position = SCNVector3(-100, 40, -60)
        sun.position = position
        scene.rootNode.addChildNode(sun)
        
        // Corona glow
        let coronaGeo = SCNSphere(radius: 12)
        let coronaMat = SCNMaterial()
        coronaMat.diffuse.contents = NSColor.clear
        coronaMat.emission.contents = NSColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.4)
        coronaMat.emission.intensity = 1.5
        coronaMat.lightingModel = .constant
        coronaMat.isDoubleSided = true
        coronaMat.blendMode = .add
        coronaGeo.materials = [coronaMat]
        
        let corona = SCNNode(geometry: coronaGeo)
        corona.position = position
        scene.rootNode.addChildNode(corona)
        
        return (sun, position)
    }
    
    public func addStarfield() {
        // Try to load starfield texture first
        if let starfieldTexture = TextureManager.shared.load(named: "starfield_8k") {
            let skyGeo = SCNSphere(radius: 350)
            skyGeo.segmentCount = 48
            
            let skyMat = SCNMaterial()
            skyMat.diffuse.contents = starfieldTexture
            skyMat.isDoubleSided = true
            skyMat.lightingModel = .constant
            skyGeo.materials = [skyMat]
            
            let sky = SCNNode(geometry: skyGeo)
            sky.eulerAngles.x = .pi / 2
            scene.rootNode.addChildNode(sky)
            return
        }
        
        // Procedural starfield fallback
        for _ in 0..<350 {
            let starGeo = SCNSphere(radius: CGFloat.random(in: 1.2...2.8))
            starGeo.segmentCount = 6
            
            let starMat = SCNMaterial()
            let bright = CGFloat.random(in: 0.85...1.0)
            let temp = CGFloat.random(in: -0.1...0.1)
            starMat.emission.contents = NSColor(
                red: min(bright + temp, 1.0),
                green: bright,
                blue: max(bright - temp * 0.3, 0.7),
                alpha: 1.0
            )
            starMat.emission.intensity = bright * 1.5
            starMat.lightingModel = .constant
            starGeo.materials = [starMat]
            
            let star = SCNNode(geometry: starGeo)
            let theta = Double.random(in: 0...(2 * .pi))
            let phi = acos(Double.random(in: -1...1))
            let r: Double = 400
            star.position = SCNVector3(
                CGFloat(r * sin(phi) * cos(theta)),
                CGFloat(r * sin(phi) * sin(theta)),
                CGFloat(r * cos(phi))
            )
            scene.rootNode.addChildNode(star)
        }
    }
    
    public func addPlanet(name: String, radius: CGFloat, position: SCNVector3, textureName: String?, fallbackColor: NSColor, hasRings: Bool = false) {
        let geo = SCNSphere(radius: radius)
        geo.segmentCount = 64
        
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        
        if let textureName = textureName, let texture = TextureManager.shared.load(named: textureName) {
            mat.diffuse.contents = texture
        } else {
            mat.diffuse.contents = fallbackColor
        }
        
        geo.materials = [mat]
        
        let planet = SCNNode(geometry: geo)
        planet.name = name
        planet.position = position
        scene.rootNode.addChildNode(planet)
        
        // Saturn rings
        if hasRings {
            let ringGeo = SCNTube(innerRadius: radius * 2.2, outerRadius: radius * 4.0, height: 0.1)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = fallbackColor.withAlphaComponent(0.8)
            ringMat.isDoubleSided = true
            ringMat.lightingModel = .physicallyBased
            ringGeo.materials = [ringMat, ringMat, ringMat]
            
            let ringNode = SCNNode(geometry: ringGeo)
            ringNode.eulerAngles.x = .pi / 3
            planet.addChildNode(ringNode)
        }
    }
    
    public func addPlanets() {
        let planetConfigs: [(name: String, radius: CGFloat, position: SCNVector3, texture: String?, color: NSColor)] = [
            ("Moon", 0.5, SCNVector3(3.5, 0.5, 0), "moon_8k", NSColor(white: 0.7, alpha: 1.0)),
            ("Mars", 0.7, SCNVector3(6, -1, -2), "mars_8k", NSColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)),
            ("Venus", 0.9, SCNVector3(8, 1, 3), "venus_8k_surface", NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)),
            ("Mercury", 0.4, SCNVector3(5, 0.5, 2), "mercury_8k", NSColor(white: 0.5, alpha: 1.0)),
            ("Jupiter", 3.5, SCNVector3(15, -2, -5), "jupiter_8k", NSColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1.0)),
            ("Saturn", 3.0, SCNVector3(22, 1, -8), "saturn_8k", NSColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)),
        ]
        
        for config in planetConfigs {
            addPlanet(name: config.name, radius: config.radius, position: config.position, textureName: config.texture, fallbackColor: config.color, hasRings: config.name == "Saturn")
        }
    }
    
    public func addLighting(sunPosition: SCNVector3) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 250
        ambient.light?.color = NSColor(white: 0.5, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)
        
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.intensity = 700
        sunLight.light?.temperature = 5500
        sunLight.light?.color = NSColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        sunLight.position = sunPosition
        sunLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunLight)
    }
}