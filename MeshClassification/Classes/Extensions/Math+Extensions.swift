//
//  Math+Extensions.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import simd

let π = Float.pi

extension Float {
    
    // Degrees to radians
    var radians: Float {
        return (self / 180) * π
    }

    // Radians to degrees
    var degrees: Float {
      return (self / π) * 180
    }
}

extension SIMD4 where Scalar : BinaryFloatingPoint {
    
    var xyz: SIMD3<Scalar> {
        return [x, y, z]
    }
}

extension simd_float4x4 {

    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
