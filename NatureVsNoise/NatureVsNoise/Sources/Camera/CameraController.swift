import SceneKit

/// Manages cinematic camera sequences for the solar system tour
class CameraController {

    // MARK: - Properties

    private weak var scene: SCNScene?
    private var cameraNode: SCNNode
    private var cameraPivot: SCNNode
    private var currentSequence: CameraSequence?

    // Camera settings
    private let defaultFieldOfView: CGFloat = 60
    private let cinematicFieldOfView: CGFloat = 45

    // MARK: - Initialization

    init(scene: SCNScene, cameraNode: SCNNode, cameraPivot: SCNNode) {
        self.scene = scene
        self.cameraNode = cameraNode
        self.cameraPivot = cameraPivot

        setupCamera()
    }

    private func setupCamera() {
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 10000
        cameraNode.camera?.fieldOfView = defaultFieldOfView
    }

    // MARK: - Camera Sequences

    /// Starts the main cinematic camera sequence (12-15 minutes)
    func startCinematicSequence() {
        let sequence = createCinematicSequence()
        currentSequence = sequence
        executeSequence(sequence)
    }

    private func createCinematicSequence() -> CameraSequence {
        let segments: [CameraSegment] = [
            // 1. Neptune approach (45s contemplation)
            CameraSegment.neptuneApproach(),

            // 2. Uranus transition and close-up (30s)
            CameraSegment.uranusTransition(),
            CameraSegment.uranusCloseUp(),

            // 3. Saturn ring reveal sequence (45s)
            CameraSegment.saturnRingReveal(),

            // 4. Jupiter encounter with Galilean moons (60s)
            CameraSegment.jupiterEncounter(),

            // 5. Inner planet transit (Mars, Venus approach) (180s)
            CameraSegment.innerPlanetTransit(),

            // 6. Earth reveal moment (420s)
            CameraSegment.earthReveal()
        ]

        return CameraSequence(segments: segments)
    }

    private func executeSequence(_ sequence: CameraSequence) {
        var actions: [SCNAction] = []

        for segment in sequence.segments {
            for movement in segment.movements {
                switch movement {
                case .pivotMove(let position, let duration):
                    let action = movePivotTo(position: position, duration: duration)
                    actions.append(action)

                case .pivotRotate(let rotation, let duration):
                    let action = rotatePivot(rotation: rotation, duration: duration)
                    actions.append(action)

                case .cameraPosition(let offset):
                    let action = setCameraRelativePosition(offset: offset)
                    actions.append(action)

                case .wait(let duration):
                    let action = SCNAction.wait(duration: duration)
                    actions.append(action)

                case .lookAt(let target, let duration):
                    let action = lookAtContinuously(target: target, duration: duration)
                    actions.append(action)
                }
            }
        }

        // Create sequence and run it once (not repeating)
        let fullSequence = SCNAction.sequence(actions)
        cameraPivot.runAction(fullSequence)

        #if DEBUG
        print("🎬 CameraController: Started cinematic sequence (\(sequence.totalDuration)s total)")
        #endif
    }

    // MARK: - Camera Movements

    func movePivotTo(position: SCNVector3, duration: Double, timingMode: SCNActionTimingMode = .easeInEaseOut) -> SCNAction {
        let action = SCNAction.move(to: position, duration: duration)
        action.timingMode = timingMode
        return action
    }

    func rotatePivot(rotation: SCNVector3, duration: Double, timingMode: SCNActionTimingMode = .easeInEaseOut) -> SCNAction {
        let action = SCNAction.rotateBy(x: rotation.x, y: rotation.y, z: rotation.z, duration: duration)
        action.timingMode = timingMode
        return action
    }

    func setCameraRelativePosition(offset: SCNVector3, lookAtTarget: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> SCNAction {
        return SCNAction.run { [weak self] _ in
            guard let self = self else { return }
            self.cameraNode.position = offset
            self.cameraNode.look(at: lookAtTarget)
        }
    }

    func lookAtContinuously(target: SCNVector3, duration: Double) -> SCNAction {
        return SCNAction.customAction(duration: duration) { [weak self] _, _ in
            self?.cameraNode.look(at: target)
        }
    }

    func setFieldOfView(_ fov: CGFloat, duration: Double = 1.0) -> SCNAction {
        return SCNAction.customAction(duration: duration) { [weak self] _, progress in
            guard let self = self else { return }
            let newFOV = self.defaultFieldOfView + (fov - self.defaultFieldOfView) * CGFloat(progress)
            self.cameraNode.camera?.fieldOfView = newFOV
        }
    }
}

// MARK: - Camera Sequence Types

enum CameraMovementType {
    case pivotMove(to: SCNVector3, duration: Double)
    case pivotRotate(rotation: SCNVector3, duration: Double)
    case cameraPosition(offset: SCNVector3)
    case wait(duration: Double)
    case lookAt(target: SCNVector3, duration: Double)
}

struct CameraSequence {
    let segments: [CameraSegment]
    var totalDuration: Double {
        segments.reduce(0) { $0 + $1.duration }
    }
}

struct CameraSegment {
    let movements: [CameraMovementType]
    let duration: Double

    // Neptune approach (45s contemplation)
    static func neptuneApproach() -> CameraSegment {
        let movements: [CameraMovementType] = [
            .cameraPosition(offset: SCNVector3(x: 0, y: 5, z: 80)),  // Wide establishing shot
            .pivotMove(to: SCNVector3(x: 200, y: 0, z: 0), duration: 25.0),  // Slow approach Neptune
            .cameraPosition(offset: SCNVector3(x: 0, y: 3, z: 25)),  // Closer view
            .lookAt(target: SCNVector3(x: 0, y: 0, z: 0), duration: 20.0),  // Look at Neptune
            .wait(duration: 20.0)  // Extended contemplation
        ]
        return CameraSegment(movements: movements, duration: 45)
    }

    // Uranus transition and close-up (30s total)
    static func uranusTransition() -> CameraSegment {
        let movements: [CameraMovementType] = [
            .pivotMove(to: SCNVector3(x: 160, y: 0, z: 0), duration: 15)
        ]
        return CameraSegment(movements: movements, duration: 15)
    }

    static func uranusCloseUp() -> CameraSegment {
        let movements: [CameraMovementType] = [
            .cameraPosition(offset: SCNVector3(x: 0, y: 2, z: 15)),  // Close-up position
            .pivotRotate(rotation: SCNVector3(x: 0, y: .pi * 2, z: 0), duration: 15)  // Full orbit
        ]
        return CameraSegment(movements: movements, duration: 15)
    }

    // Saturn ring reveal sequence (60s total - Enhanced)
    static func saturnRingReveal() -> CameraSegment {
        let movements: [CameraMovementType] = [
            // 1. Approach from high angle
            .pivotMove(to: SCNVector3(x: 120, y: 0, z: 0), duration: 20.0),
            .cameraPosition(offset: SCNVector3(x: 0, y: 15, z: 35)), // High above ring plane
            .pivotRotate(rotation: SCNVector3(x: 0.2, y: .pi * 0.5, z: 0), duration: 20.0),
            
            // 2. THE DIVE: Drop through the ring plane
            .cameraPosition(offset: SCNVector3(x: 0, y: -5, z: 25)), // Below plane
            .pivotRotate(rotation: SCNVector3(x: -0.1, y: .pi * 1.0, z: 0), duration: 10.0), // Fast rotation during dive
            
            // 3. Stabilization below rings
            .cameraPosition(offset: SCNVector3(x: 0, y: -2, z: 30)),
            .lookAt(target: SCNVector3(x: 0, y: 0, z: 0), duration: 30.0),
            .wait(duration: 10.0)
        ]
        return CameraSegment(movements: movements, duration: 60)
    }

    // Jupiter encounter with Galilean moons (60s)
    static func jupiterEncounter() -> CameraSegment {
        let movements: [CameraMovementType] = [
            .cameraPosition(offset: SCNVector3(x: 0, y: 3, z: 35)),  // Wider view for moons
            .pivotRotate(rotation: SCNVector3(x: 0, y: .pi * 2.5, z: 0), duration: 60),
            // Slight vertical oscillation to feel "floating"
            .cameraPosition(offset: SCNVector3(x: 0, y: -2, z: 30))
        ]
        return CameraSegment(movements: movements, duration: 60)
    }

    // Inner planet transit (Mars, Venus approach) (180s)
    static func innerPlanetTransit() -> CameraSegment {
        let movements: [CameraMovementType] = [
            .pivotMove(to: SCNVector3(x: 40, y: 0, z: 0), duration: 45),  // Move to Mars
            .cameraPosition(offset: SCNVector3(x: 0, y: 1, z: 12)),  // Mars view
            .wait(duration: 45),  // Mars contemplation
            .pivotMove(to: SCNVector3(x: 20, y: 0, z: 0), duration: 45),  // Move to Venus
            .cameraPosition(offset: SCNVector3(x: 0, y: 1, z: 10)),  // Venus view
            .wait(duration: 45)  // Venus contemplation
        ]
        return CameraSegment(movements: movements, duration: 180)
    }

    // Earth reveal moment (420s - Enhanced "Nature vs Noise")
    static func earthReveal() -> CameraSegment {
        let movements: [CameraMovementType] = [
            // 1. Establish: "The Blue Marble" (Peaceful)
            .pivotMove(to: SCNVector3(x: 30, y: 0, z: 0), duration: 60),
            .cameraPosition(offset: SCNVector3(x: 0, y: 0, z: 25)), // Classic view
            .wait(duration: 30),
            
            // 2. The REVEAL: Aggressive zoom into the swarm (Chaos)
            .cameraPosition(offset: SCNVector3(x: 0, y: 0, z: 3.5)), // Extremely close (LEO)
            .pivotRotate(rotation: SCNVector3(x: 0, y: .pi * 0.5, z: 0.1), duration: 10.0), // Fast spin
            .wait(duration: 60), // Hold in the swarm
            
            // 3. Night Side Tour (City Lights + Satellites)
            .pivotRotate(rotation: SCNVector3(x: 0, y: .pi, z: 0), duration: 60), // Move to night side
            .cameraPosition(offset: SCNVector3(x: 0, y: 2, z: 4.0)), // Slightly higher orbit
            .wait(duration: 60),
            
            // 4. The Pull Back: "Context"
            .cameraPosition(offset: SCNVector3(x: 0, y: 5, z: 60)), // Far retreat
            .pivotRotate(rotation: SCNVector3(x: 0, y: .pi * 2, z: 0), duration: 60),
            .wait(duration: 60)
        ]
        return CameraSegment(movements: movements, duration: 420)
    }
}