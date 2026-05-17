import Cocoa
import SceneKit
import SceneKit.ModelIO
import ModelIO

let files = ["hubble", "juno", "tdrs", "tess"]
let fileManager = FileManager.default

for file in files {
    let glbURL = URL(fileURLWithPath: "\(file).glb")
    let scnURL = URL(fileURLWithPath: "\(file).scn")
    
    if fileManager.fileExists(atPath: glbURL.path) {
        print("Loading \(file).glb with MDLAsset...")
        let asset = MDLAsset(url: glbURL)
        let scene = SCNScene(mdlAsset: asset)
        print("Successfully loaded \(file).glb. Saving to \(file).scn...")
        let success = scene.write(to: scnURL, options: nil, delegate: nil, progressHandler: nil)
        if success {
            print("✅ Converted \(file).glb to \(file).scn")
        } else {
            print("❌ Failed to save \(file).scn")
        }
    } else {
        print("⚠️ File not found: \(file).glb")
    }
}
