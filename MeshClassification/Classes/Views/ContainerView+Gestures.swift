//
//  ContainerView+Gestures.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import ARKit
import RealityKit
import UIKit

extension ContainerView {
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {

        // Perform a ray cast against the mesh, drop an anchor and try to identify the object
        let location = sender.location(in: arView)
        guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else { return }
        
        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.addChild(sphere(color: .red))
        arView.scene.addAnchor(anchor)
        
        // Try to get a classification near the tap location
        classify(to: result.worldTransform.position) { (centerOfFace, classification) in

            DispatchQueue.main.async {
                // 4. Compute a position for the text which is near the result location, but offset 10 cm
                // towards the camera (along the ray) to minimize unintentional occlusions of the text by the mesh.
                let rayDirection = normalize(result.worldTransform.position - self.arView.cameraTransform.translation)
                let textPositionInWorldCoordinates = result.worldTransform.position - (rayDirection * 0.1)
                
                // Create a 3D text to visualize the classification result.
                let textEntity = self.text(for: classification.description)

                // Scale the text depending on the distance, such that it always appears with the same size on screen.
                let raycastDistance = distance(result.worldTransform.position, self.arView.cameraTransform.translation)
                textEntity.scale = .one * raycastDistance

                // Place the text, facing the camera.
                var cameraTransform = self.arView.cameraTransform
                cameraTransform.translation = textPositionInWorldCoordinates
                let textAnchor = AnchorEntity(world: cameraTransform.matrix)
                textAnchor.addChild(textEntity)
                self.arView.scene.addAnchor(textAnchor)

            }
        }
    }

    // Attempts to classify the ARMeshAnchor at the specified location
    func classify(to location: SIMD3<Float>, completionBlock: @escaping (SIMD3<Float>?, ARMeshClassification) -> Void) {
        guard let frame = arView.session.currentFrame else {
            completionBlock(nil, .none)
            return
        }
    
        var meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        
        // Sort the mesh anchors by distance to the given location
        // and filter out any anchors that are too far away (4 meters).
        let cutoffDistance: Float = 4.0
        meshAnchors.removeAll { distance($0.transform.position, location) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, location) < distance($1.transform.position, location) }

        // Perform the search asynchronously in order not to stall rendering.
        DispatchQueue.global().async {
            for anchor in meshAnchors {
                for index in 0..<anchor.geometry.faces.count {
                    // Get the center of the face so that we can compare it to the given location.
                    let center = anchor.geometry.centerOfFace(at: index)
                    
                    // Convert the face's center to world coordinates.
                    var transform = matrix_identity_float4x4
                    transform.columns.3 = SIMD4<Float>(center.0, center.1, center.2, 1)
                    let centerWorldPosition = (anchor.transform * transform).position
                     
                    // We're interested in a classification that is sufficiently close to the given location – within 5 cm.
                    let distanceToFace = distance(centerWorldPosition, location)
                    if distanceToFace <= 0.05 {
                        // Get the semantic classification of the face and finish the search.
                        let classification: ARMeshClassification = anchor.geometry.semanticClassificationForFace(at: index)
                        completionBlock(centerWorldPosition, classification)
                        return
                    }
                }
            }
            
            // Let the completion block know that no result was found.
            completionBlock(nil, .none)
        }
    }

    func text(for classification: String) -> ModelEntity {
        
        // Return cached model if available
        if let model = classifications[classification] {
            model.transform = .identity
            return model.clone(recursive: true)
        }
        
        // Generate 3D text for the classification
        let lineHeight: CGFloat = 0.05
        let font = MeshResource.Font.systemFont(ofSize: lineHeight)
        let textMesh = MeshResource.generateText(classification, extrusionDepth: Float(lineHeight * 0.1), font: font)
        let textMaterial = SimpleMaterial(color: .white, isMetallic: true)
        let model = ModelEntity(mesh: textMesh, materials: [textMaterial])
        // Move text geometry to the left so that its local origin is in the center
        model.position.x -= model.visualBounds(relativeTo: nil).extents.x / 2
        // Add model to cache
        classifications[classification] = model
        return model
    }

    func sphere(radius: Float = 0.05, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
    }
}
