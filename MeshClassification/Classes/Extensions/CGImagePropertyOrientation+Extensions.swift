//
//  CGImagePropertyOrientation+Extensions.swift
//  MeshClassification
//
//  Created by Kevin McKee on 10/6/20.
//

import ARKit

extension CGImagePropertyOrientation {
    
    static var current: CGImagePropertyOrientation {
        return CGImagePropertyOrientation(rawValue: UInt32(UIDevice.current.orientation.rawValue)) ?? .up
    }
    
}
