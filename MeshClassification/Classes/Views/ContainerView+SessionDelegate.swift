//
//  ContainerView+SessionDelegate.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import ARKit

extension ContainerView: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available;
        // holding too many buffers for analysis would starve the camera.
        guard currentPixelBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        // Retain the image buffer for Vision processing.
        self.currentPixelBuffer = frame.capturedImage
        recognizeObjectsInCurrentImage()
        
        DispatchQueue.main.async {
            self.debugView.update(frame)
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        
    }
}
