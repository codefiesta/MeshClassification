//
//  ARContainerView.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import SwiftUI
import RealityKit
import ARKit
import Vision

class ContainerView: UIView {
    
    // Our ARView
    var arView: ARView!
    
    // Debugging View
    var debugView: DebugView!

    // Cache of Mesh Classification Text Models
    var classifications: [String: ModelEntity] = [:]
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    var currentPixelBuffer: CVPixelBuffer?

    // Queue for dispatching vision classification requests
    let visionQueue = DispatchQueue(label: "com.procore.VisionQueue")
    
    // The minimum confidence threshold
    let minimumConfidence: VNConfidence = 0.3
    
    // Vision recognition request and model
    lazy var recognitionRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let configuration = MLModelConfiguration()
            let model = try VNCoreMLModel(for: YOLOv3Tiny(configuration: configuration).model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processReconizedObjects(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        
        // Layout the ARView
        arView = ARView(frame: .zero)
        addSubview(arView)
        arView.pinToEdges()
        
        // Layout the debug view
        debugView = DebugView(frame: .zero)
        debugView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(debugView)

        NSLayoutConstraint.activate([
            debugView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            debugView.centerXAnchor.constraint(equalTo: centerXAnchor),
            debugView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            debugView.heightAnchor.constraint(equalToConstant: 40)
        ])

        
        // Add tap gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        // Prepare & run the session
        prepareSession()
    }
    
    private func prepareSession() {
        arView.session.delegate = self
        
        arView.environment.sceneUnderstanding.options = []
        
        // Turn on occlusion from the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Turn on physics for the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.physics)

        // Display a debug visualization of the mesh.
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.debugOptions.insert(.showStatistics)
        
        // For performance, disable render options that are not required for this app.
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification

        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)

    }
}
