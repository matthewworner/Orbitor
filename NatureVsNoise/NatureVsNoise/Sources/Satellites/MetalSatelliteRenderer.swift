import Metal
import MetalKit
import SceneKit
import simd

// FeatureFlags is now in Sources/FeatureFlags.swift

// MARK: - GPU Data Structures (Must match Metal shader)

struct OrbitalElementsGPU {
    var epoch: Float
    var inclination: Float
    var raan: Float
    var eccentricity: Float
    var argumentOfPerigee: Float
    var meanAnomaly: Float
    var meanMotion: Float
    var bStar: Float
}

struct SatelliteInstanceData {
    var position: SIMD3<Float>
    var velocity: SIMD3<Float>
    var color: SIMD4<Float>
    var size: Float
    var brightness: Float
    
    // Padding to ensure 16-byte alignment
    var _padding: SIMD2<Float> = .zero
}

struct CameraUniforms {
    var viewProjectionMatrix: simd_float4x4
    var cameraPosition: SIMD3<Float>
    var time: Float
}

struct RenderUniforms {
    var modelViewProjection: simd_float4x4
    var earthPosition: SIMD3<Float>
    var scale: Float
    var trailLength: Float
    var showTrails: Int32
    
    // Padding
    var _padding: SIMD2<Float> = .zero
}

// MARK: - Metal Satellite Renderer

/// High-performance satellite renderer using Metal compute shaders
/// Replaces SceneKit's SCNNode-based rendering with GPU-instanced particles
class MetalSatelliteRenderer: NSObject {
    
    // MARK: - Properties
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var propagatePipeline: MTLComputePipelineState?
    private var cullPipeline: MTLComputePipelineState?
    private var renderPipeline: MTLRenderPipelineState?
    private var trailRenderPipeline: MTLRenderPipelineState?
    
    // Buffers
    private var elementsBuffer: MTLBuffer?
    private var instanceBuffer: MTLBuffer?
    private var visibleBuffer: MTLBuffer?
    private var colorBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var renderUniformBuffer: MTLBuffer?
    
    // State
    private var satelliteCount: Int = 0
    private var maxSatellites: Int = 5000  // Reduced from 50000 for stability
    private let maxTrailInstances: Int = 1000  // Maximum trails to render
    private var currentTime: Float = 0
    private var timeAcceleration: Float = 100.0
    
    // Tracking
    private var isInitialized: Bool = false
    private var initializationError: String?
    
    // Configuration
    var earthPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)  // Fixed: Earth at origin
    var renderScale: Float = 1.5  // Increased for visibility
    var showTrails: Bool = true
    var trailLength: Float = 1.5
    var lodDistance: Float = 100.0
    weak var cameraNode: SCNNode?
    
    // MARK: - Initialization

    /// Create a Metal satellite renderer
    /// - Parameter maxSatelliteCount: Maximum satellites to render (default from FeatureFlags)
    static func create(maxSatelliteCount: Int? = nil) -> MetalSatelliteRenderer? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ MetalSatelliteRenderer: Metal is not supported on this device")
            return nil
        }

        guard let commandQueue = device.makeCommandQueue() else {
            print("❌ MetalSatelliteRenderer: Failed to create command queue")
            return nil
        }

        let count = maxSatelliteCount ?? FeatureFlags.maxSatelliteCount
        let renderer = MetalSatelliteRenderer(device: device, commandQueue: commandQueue, maxSatellites: count)

        // setupPipelines may fail for optional pipelines - that's OK, we fall back to SceneKit-only
        renderer.setupPipelines()
        renderer.setupBuffers()
        
        // Check if we have a functional render pipeline
        if renderer.renderPipeline == nil {
            print("⚠️ MetalSatelliteRenderer: No functional render pipeline - using SceneKit-only mode")
        } else {
            print("✅ MetalSatelliteRenderer: Initialized with \(device.name), max \(count) satellites")
        }
        
        return renderer
    }

    private init(device: MTLDevice, commandQueue: MTLCommandQueue, maxSatellites: Int) {
        self.device = device
        self.commandQueue = commandQueue
        self.maxSatellites = maxSatellites
        super.init()
    }
    
    // MARK: - Pipeline Setup
    
    private func setupPipelines() {
        // Load the shader library
        guard let library = device.makeDefaultLibrary() else {
            initializationError = "Failed to load Metal shader library"
            return
        }
        
        // Try to create compute pipeline for propagation (optional - may fail)
        if let propagateFunction = library.makeFunction(name: "propagateSatellites") {
            do {
                propagatePipeline = try device.makeComputePipelineState(function: propagateFunction)
                print("✅ MetalSatelliteRenderer: Propagation pipeline created")
            } catch {
                print("⚠️ MetalSatelliteRenderer: Could not create propagation pipeline: \(error)")
            }
        } else {
            print("⚠️ MetalSatelliteRenderer: propagateSatellites function not found in shaders")
        }
        
        // Try to create compute pipeline for culling (optional)
        if let cullFunction = library.makeFunction(name: "cullAndLOD") {
            do {
                cullPipeline = try device.makeComputePipelineState(function: cullFunction)
            } catch {
                print("⚠️ MetalSatelliteRenderer: Could not create cull pipeline: \(error)")
            }
        }
        
        // Render pipeline for satellites - this is required
        guard let vertexFunction = library.makeFunction(name: "satelliteVertex"),
              let fragmentFunction = library.makeFunction(name: "satelliteFragment") else {
            initializationError = "Required shader functions not found in Metal library"
            return
        }
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        // Additive glow instead of flat alpha-blended discs — a "firefly swarm" should glow,
        // not paint solid coins. Overlapping satellites brighten instead of just occluding.
        renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        // ponytail: tried additive (.one/.one) for a "glow" look — wrong call, additive vanishes
        // against this scene's bright sun/bloom (color + near-white ≈ near-white). Back to normal
        // alpha-over so satellites stay visible regardless of background brightness.
        renderDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        renderDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        renderDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: renderDescriptor)
            print("✅ MetalSatelliteRenderer: Render pipeline created")
        } catch {
            print("⚠️ MetalSatelliteRenderer: Failed to create render pipeline: \(error)")
            // Don't throw - we'll use SceneKit-only mode as fallback
            // This allows the screensaver to work even if Metal shaders fail
            initializationError = "Render pipeline creation failed: \(error.localizedDescription)"
            return
        }
        
        // Trail render pipeline (optional)
        if let trailVertex = library.makeFunction(name: "trailVertex"),
           let trailFragment = library.makeFunction(name: "trailFragment") {
            let trailDescriptor = MTLRenderPipelineDescriptor()
            trailDescriptor.vertexFunction = trailVertex
            trailDescriptor.fragmentFunction = trailFragment
            trailDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            trailDescriptor.colorAttachments[0].isBlendingEnabled = true
            trailDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            trailDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one // Additive blending for trails
            trailDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            do {
                trailRenderPipeline = try device.makeRenderPipelineState(descriptor: trailDescriptor)
            } catch {
                print("⚠️ MetalSatelliteRenderer: Could not create trail pipeline: \(error)")
            }
        }
        
        isInitialized = true
    }
    
    private func setupBuffers() {
        // Pre-allocate buffers for maximum satellite count
        let elementsSize = MemoryLayout<OrbitalElementsGPU>.stride * maxSatellites
        let instanceSize = MemoryLayout<SatelliteInstanceData>.stride * maxSatellites
        let colorSize = MemoryLayout<SIMD4<Float>>.stride * maxSatellites
        
        elementsBuffer = device.makeBuffer(length: elementsSize, options: .storageModeShared)
        instanceBuffer = device.makeBuffer(length: instanceSize, options: .storageModeShared)
        visibleBuffer = device.makeBuffer(length: instanceSize, options: .storageModeShared)
        colorBuffer = device.makeBuffer(length: colorSize, options: .storageModeShared)
        uniformBuffer = device.makeBuffer(length: MemoryLayout<CameraUniforms>.size, options: .storageModeShared)
        renderUniformBuffer = device.makeBuffer(length: MemoryLayout<RenderUniforms>.size, options: .storageModeShared)
        
        elementsBuffer?.label = "Orbital Elements"
        instanceBuffer?.label = "Satellite Instances"
        visibleBuffer?.label = "Visible Satellites"
        colorBuffer?.label = "Satellite Colors"
    }
    
    // MARK: - Data Upload
    
    /// Upload satellite orbital elements to GPU
    func uploadSatellites(_ satellites: [SatelliteManager.Satellite], colors: [SIMD4<Float>], sizesAndBrightness: [(size: Float, brightness: Float)]) {
        guard let elementsBuffer = elementsBuffer,
              let colorBuffer = colorBuffer,
              let instanceBuffer = instanceBuffer else { 
            print("❌ MetalSatelliteRenderer: Buffers not initialized")
            return 
        }

        satelliteCount = min(satellites.count, maxSatellites)

        // Convert to GPU format
        let elementsPtr = elementsBuffer.contents().bindMemory(to: OrbitalElementsGPU.self, capacity: satelliteCount)
        let colorsPtr = colorBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: satelliteCount)
        let instancePtr = instanceBuffer.contents().bindMemory(to: SatelliteInstanceData.self, capacity: satelliteCount)

        for i in 0..<satelliteCount {
            let sat = satellites[i]
            elementsPtr[i] = OrbitalElementsGPU(
                epoch: Float(sat.epoch),
                inclination: Float(sat.inclination),
                raan: Float(sat.raan),
                eccentricity: Float(sat.eccentricity),
                argumentOfPerigee: Float(sat.argumentOfPerigee),
                meanAnomaly: Float(sat.meanAnomaly),
                meanMotion: Float(sat.meanMotion),
                bStar: Float(sat.bStar)
            )
            colorsPtr[i] = colors[i]

            // Per-classification size/brightness (hero objects large+bright, debris small+dim) —
            // was a flat swarmSize/swarmBrightness constant for every satellite.
            let (size, brightness) = sizesAndBrightness[i]
            instancePtr[i] = SatelliteInstanceData(
                position: SIMD3<Float>(0, 0, 0), // Will be set by propagation shader or CPU fallback
                velocity: SIMD3<Float>(0, 0, 0),
                color: colors[i],
                size: size,
                brightness: brightness,
                _padding: .zero
            )
        }

        #if DEBUG
        print("📡 MetalSatelliteRenderer: Uploaded \(satelliteCount) satellites to GPU (firefly swarm)")
        #endif
    }
    
    // MARK: - Propagation
    
    /// Execute GPU propagation for all satellites
    func propagate(deltaTime: Float) {
        // If compute pipeline not available, skip GPU propagation
        // SceneKit fallback will handle positioning
        guard propagatePipeline != nil,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let propagatePipeline = propagatePipeline,
              let elementsBuffer = elementsBuffer,
              let instanceBuffer = instanceBuffer,
              let colorBuffer = colorBuffer else { 
            // GPU propagation not available - this is fine, SceneKit handles it
            return 
        }
        
        currentTime += deltaTime
        
        computeEncoder.setComputePipelineState(propagatePipeline)
        computeEncoder.setBuffer(elementsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(instanceBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(colorBuffer, offset: 0, index: 2)
        
        var time = currentTime
        var accel = timeAcceleration
        computeEncoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 3)
        computeEncoder.setBytes(&accel, length: MemoryLayout<Float>.size, index: 4)
        
        // Dispatch compute threads
        let threadGroupSize = propagatePipeline.maxTotalThreadsPerThreadgroup
        let threadGroups = MTLSize(width: (satelliteCount + threadGroupSize - 1) / threadGroupSize, height: 1, depth: 1)
        let threadsPerGroup = MTLSize(width: threadGroupSize, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
    // MARK: - SceneKit Integration
    
    /// Get instance data for SceneKit rendering (fallback/hybrid mode)
    func getInstancePositions() -> [SIMD3<Float>] {
        guard let instanceBuffer = instanceBuffer else { return [] }
        
        let ptr = instanceBuffer.contents().bindMemory(to: SatelliteInstanceData.self, capacity: satelliteCount)
        var positions: [SIMD3<Float>] = []
        positions.reserveCapacity(satelliteCount)
        
        for i in 0..<satelliteCount {
            positions.append(ptr[i].position)
        }
        
        return positions
    }
    
    /// Get complete instance data for rendering
    func getInstances() -> [SatelliteInstanceData] {
        guard let instanceBuffer = instanceBuffer else { return [] }
        
        let ptr = instanceBuffer.contents().bindMemory(to: SatelliteInstanceData.self, capacity: satelliteCount)
        return Array(UnsafeBufferPointer(start: ptr, count: satelliteCount))
    }
    
    // MARK: - Direct Metal Rendering
    
    /// Render satellites directly using Metal (bypasses SceneKit)
    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, camera: SCNNode) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let renderPipeline = renderPipeline,
              let instanceBuffer = instanceBuffer else { return }
        
        // Calculate camera matrices
        let viewMatrix = camera.simdTransform.inverse
        let projectionMatrix: simd_float4x4
        if let proj = camera.camera?.projectionTransform {
            projectionMatrix = simd_float4x4(proj)
        } else {
            projectionMatrix = matrix_identity_float4x4
        }
        let vpMatrix = simd_mul(projectionMatrix, viewMatrix)
        
        var cameraUniforms = CameraUniforms(
            viewProjectionMatrix: vpMatrix,
            cameraPosition: camera.simdPosition,
            time: currentTime
        )
        
        var renderUniforms = RenderUniforms(
            modelViewProjection: vpMatrix,
            earthPosition: earthPosition,
            scale: renderScale,
            trailLength: trailLength,
            showTrails: showTrails ? 1 : 0
        )
        
        // Update uniform buffers
        memcpy(uniformBuffer?.contents(), &cameraUniforms, MemoryLayout<CameraUniforms>.size)
        memcpy(renderUniformBuffer?.contents(), &renderUniforms, MemoryLayout<RenderUniforms>.size)
        
        // Render satellites as points
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(renderUniformBuffer, offset: 0, index: 2)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: satelliteCount)
        
        // Render trails if enabled
        if showTrails, let trailPipeline = trailRenderPipeline {
            renderEncoder.setRenderPipelineState(trailPipeline)
            renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 10, instanceCount: min(satelliteCount, 5000))
        }
        
        renderEncoder.endEncoding()
    }
    
    // MARK: - SceneKit Integration (Hybrid Rendering)
    
    /// Render satellites using SceneKit's existing Metal render context
    /// Call this from SCNSceneRendererDelegate.renderer(_:willRenderScene:atTime:)
    func render(into renderer: SCNSceneRenderer, camera: SCNNode) {
        guard let renderEncoder = renderer.currentRenderCommandEncoder,
              let renderPipeline = renderPipeline,
              let instanceBuffer = instanceBuffer,
              let renderUniformBuffer = renderUniformBuffer,
              satelliteCount > 0 else { return }
        
        // Calculate view-projection matrix from camera
        let viewMatrix = camera.simdTransform.inverse
        let projectionMatrix: simd_float4x4
        if let cameraObj = camera.camera {
            projectionMatrix = simd_float4x4(cameraObj.projectionTransform)
        } else {
            projectionMatrix = matrix_identity_float4x4
        }
        let vpMatrix = simd_mul(projectionMatrix, viewMatrix)
        
        // Update uniforms buffer
        var renderUniforms = RenderUniforms(
            modelViewProjection: vpMatrix,
            earthPosition: earthPosition,
            scale: renderScale,
            trailLength: trailLength,
            showTrails: showTrails ? 1 : 0
        )
        memcpy(renderUniformBuffer.contents(), &renderUniforms, MemoryLayout<RenderUniforms>.stride)
        
        // Encode render commands directly into SceneKit's render pass.
        // NOTE: satelliteVertex/trailVertex read the view-projection matrix from buffer(1).
        // RenderUniforms.modelViewProjection is the struct's first field, so binding
        // renderUniformBuffer at index 1 hands the shader the matrix it expects. Binding it at
        // index 2 (as before) left buffer(1) holding SceneKit's leftover buffer → garbage
        // transform → satellites projected off-screen and never appeared.
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(renderUniformBuffer, offset: 0, index: 1)

        // Draw all satellites as point sprites in a single draw call
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: satelliteCount)

        // Render trails if enabled
        if showTrails, let trailPipeline = trailRenderPipeline {
            renderEncoder.setRenderPipelineState(trailPipeline)
            renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(renderUniformBuffer, offset: 0, index: 1)
            // Draw trail lines (2 vertices per satellite, instanced)
            renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 2, instanceCount: min(satelliteCount, maxTrailInstances))
        }
    }
    
    /// Update satellite positions on CPU (for hybrid mode when GPU propagation unavailable)
    func updatePositionsCPU(positions: [SIMD3<Float>], velocities: [SIMD3<Float>]) {
        guard let instanceBuffer = instanceBuffer else { return }
        
        let ptr = instanceBuffer.contents().bindMemory(to: SatelliteInstanceData.self, capacity: satelliteCount)
        let count = min(positions.count, satelliteCount)
        
        for i in 0..<count {
            ptr[i].position = positions[i]
            if i < velocities.count {
                ptr[i].velocity = velocities[i]
            }
        }
    }
    
    // MARK: - Configuration
    
    func setTimeAcceleration(_ acceleration: Float) {
        timeAcceleration = acceleration
    }
    
    func resetTime() {
        currentTime = 0
    }
}

// MARK: - Errors

enum MetalRendererError: Error {
    case shaderLoadFailed
    case pipelineCreationFailed
    case bufferCreationFailed
}

// MARK: - SCNMatrix4 to simd_float4x4 Extension

extension simd_float4x4 {
    init(_ matrix: SCNMatrix4) {
        self.init(columns: (
            SIMD4<Float>(Float(matrix.m11), Float(matrix.m12), Float(matrix.m13), Float(matrix.m14)),
            SIMD4<Float>(Float(matrix.m21), Float(matrix.m22), Float(matrix.m23), Float(matrix.m24)),
            SIMD4<Float>(Float(matrix.m31), Float(matrix.m32), Float(matrix.m33), Float(matrix.m34)),
            SIMD4<Float>(Float(matrix.m41), Float(matrix.m42), Float(matrix.m43), Float(matrix.m44))
        ))
    }
}

// MARK: - MTKViewDelegate Extension

extension MetalSatelliteRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle drawable size changes if needed (e.g., update viewport)
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let camera = cameraNode else { return }

        // Render satellites using the existing render method
        render(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, camera: camera)

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
