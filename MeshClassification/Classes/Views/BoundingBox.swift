//
//  BoundingBox.swift
//  MeshClassification
//
//  Created by Kevin McKee on 10/7/20.
//

import ARKit
import RealityKit

class BoundingBox: Entity, HasModel, HasPhysics {
    
    required init(label: String? = nil) {
        super.init()
        let color = UIColor.red.withAlphaComponent(0.3)
        self.model = ModelComponent(
            mesh: .generateBox(size: [0.5, 0.2, 0.5]),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
          )
          self.generateCollisionShapes(recursive: true)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
}
