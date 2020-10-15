//
//  ContainerView+Vision.swift
//  MeshClassification
//
//  Created by Kevin McKee on 10/6/20.
//

import ARKit
import RealityKit
import Vision

extension ContainerView {
    
    // Performs an attempt to recognize objects in the current pixel buffer
    func recognizeObjectsInCurrentImage() {
        
        if let currentPixelBuffer = currentPixelBuffer {
            // Most computer vision tasks are not rotation agnostic so it is important
            // to pass in the orientation of the image with respect to device.
            let orientation = CGImagePropertyOrientation.current
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentPixelBuffer, orientation: orientation)
            visionQueue.async {
                do {
                    // Release the pixel buffer when done, allowing the next buffer to be processed.
                    defer { self.currentPixelBuffer = nil }
                    try requestHandler.perform([self.recognitionRequest])
                } catch {
                    print("Error: Vision request failed with error \"\(error)\"")
                }
            }

        }
        
    }

    // Handle completion of the Vision request and choose results to display.
    func processReconizedObjects(for request: VNRequest, error: Error?) {
        
        guard let pixelBuffer = currentPixelBuffer, let results = request.results,
              let observations = results as? [VNRecognizedObjectObservation],
              !observations.isEmpty else {
            return
        }

        // Filter out any objects that don't meet our minimum confidence level
        let recognizedObjects = observations.filter({ $0.confidence > minimumConfidence })
        debugPrint("🎯 [\(recognizedObjects.count)] objects recognized")
        
        // Drop anchor on objects we have recognized
        for recognizedObject in recognizedObjects {
            DispatchQueue.main.async { [weak self] in
                self?.addAnchor(for: recognizedObject, in: pixelBuffer)
            }
        }
    }

    // Drops ball and text anchors on top of any mesh anchors we've could identify
    private func addAnchor(for recognizedObject: VNRecognizedObjectObservation, in pixelBuffer: CVPixelBuffer) {
        
        // The highest probability label
        guard let label = recognizedObject.labels.first?.identifier else { return }
        
        let boundingBox = recognizedObject.boundingBox

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let objectBounds = VNNormalizedRectForImageRect(boundingBox, width, height)
        
        let center = CGPoint(x: objectBounds.midX, y: objectBounds.midY)
        
        guard let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .any).first else { return }
        
        guard let frame = arView.session.currentFrame else { return }

        // Sort all of the ARMeshAnchors by proximity to center of the recognized
        // object bounding box and filer any that are more than 4 meters away
        var meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        let position = result.worldTransform.position
        let cutoffDistance: Float = 4.0
        meshAnchors.removeAll { distance($0.transform.position, position) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, position) < distance($1.transform.position, position) }
        
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
                    let distanceToFace = distance(centerWorldPosition, position)
                    if distanceToFace <= 0.05 {
                        
                        // Drop the ball and text anchors on top of that ARMeshAnchor
                        DispatchQueue.main.async {
                            let rayDirection = normalize(result.worldTransform.position - self.arView.cameraTransform.translation)
                            let textPositionInWorldCoordinates = result.worldTransform.position - (rayDirection * 0.1)
            
                            // Create a 3D text to visualize the Vision classification result.
                            let textEntity = self.text(for: label)
            
                            // Scale the text depending on the distance, such that it always appears with the same size on screen.
                            let raycastDistance = distance(result.worldTransform.position, self.arView.cameraTransform.translation)
                            textEntity.scale = .one * raycastDistance
            
                            // Place the text, facing the camera.
                            var cameraTransform = self.arView.cameraTransform
                            cameraTransform.translation = textPositionInWorldCoordinates
                            
                            let ballAnchor = AnchorEntity(world: result.worldTransform)
                            ballAnchor.addChild(self.sphere(color: .red))
                            self.arView.scene.addAnchor(ballAnchor)
                            
                            let textAnchor = AnchorEntity(world: cameraTransform.matrix)
                            textAnchor.addChild(textEntity)
                            self.arView.scene.addAnchor(textAnchor)
                            
                            debugPrint("⚓︎ Dropping anchor on [\(anchor.identifier)]")

                        }
                        return
                    }
                }
            }
        }
    }
}
