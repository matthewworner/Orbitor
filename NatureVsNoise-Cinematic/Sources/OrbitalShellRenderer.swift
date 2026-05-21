import SceneKit

/// Renders orbital altitude shells around Earth
class OrbitalShellRenderer {
    
    private weak var scene: SCNScene?
    private var shells: [SCNNode] = []
    private var rings: [SCNNode] = []
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func createShellForZone(_ zone: OrbitalZone, radius: CGFloat, opacity: CGFloat) {
        // Shell sphere - translucent
        let shellGeo = SCNSphere(radius: radius)
        shellGeo.segmentCount = 48
        
        let mat = SCNMaterial()
        mat.diffuse.contents = zoneColor(zone).withAlphaComponent(opacity * 0.3)
        mat.emission.contents = zoneColor(zone)
        mat.emission.intensity = 0.2
        mat.lightingModel = .constant
        mat.isDoubleSided = true
        mat.cullMode = .back
        mat.blendMode = .alpha
        shellGeo.materials = [mat]
        
        let shell = SCNNode(geometry: shellGeo)
        shell.name = "Shell-\(zone.rawValue)"
        shell.opacity = opacity
        scene?.rootNode.addChildNode(shell)
        shells.append(shell)
        
        // Equatorial ring
        createRing(at: radius, color: zoneColor(zone), opacity: 0.7)
        
        // Inclined rings
        for angle in [30.0, 60.0] as [CGFloat] {
            createRing(at: radius, color: zoneColor(zone), opacity: 0.4, inclination: angle)
        }
    }
    
    private func zoneColor(_ zone: OrbitalZone) -> NSColor {
        switch zone {
        case .leo: return NSColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
        case .meo: return NSColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        case .geo: return NSColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
        case .heo: return NSColor(red: 0.3, green: 0.4, blue: 1.0, alpha: 1.0)
        }
    }
    
    private func createRing(at radius: CGFloat, color: NSColor, opacity: CGFloat, inclination: CGFloat = 0) {
        let segments = 64
        var vertices: [SCNVector3] = []
        
        for i in 0...segments {
            let angle = CGFloat(i) / CGFloat(segments) * .pi * 2
            vertices.append(SCNVector3(radius * cos(angle), 0, radius * sin(angle)))
        }
        
        var indices: [Int32] = []
        for i in 0..<segments {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let mat = SCNMaterial()
        mat.diffuse.contents = color.withAlphaComponent(opacity)
        mat.emission.contents = color
        mat.emission.intensity = CGFloat(opacity)
        mat.lightingModel = .constant
        geometry.materials = [mat]
        
        let ring = SCNNode(geometry: geometry)
        ring.eulerAngles.z = inclination * .pi / 180.0
        scene?.rootNode.addChildNode(ring)
        rings.append(ring)
    }
    
    func update(time: Float) {
        // Animate shell rotation
        let rot = CGFloat(time * 0.03)
        for shell in shells {
            shell.eulerAngles.y = rot
        }
        
        // Pulse ring opacity
        let pulse = (sin(time * 1.5) + 1) / 2 * 0.3 + 0.5
        for ring in rings {
            if let mat = ring.geometry?.firstMaterial {
                mat.emission.intensity = CGFloat(pulse)
            }
        }
    }
    
    func setMode(_ mode: KubrickMode) {
        switch mode {
        case .shells:
            for shell in shells { shell.isHidden = false; shell.opacity = 0.15 }
            for ring in rings { ring.isHidden = false }
        case .density:
            for shell in shells { shell.isHidden = false; shell.opacity = 0.25 }
            for ring in rings { ring.isHidden = false }
        default:
            for shell in shells { shell.isHidden = false; shell.opacity = 0.05 }
            for ring in rings { ring.isHidden = false }
        }
    }
}