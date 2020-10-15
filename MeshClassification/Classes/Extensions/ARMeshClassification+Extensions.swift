//
//  ARMeshClassification+Extensions.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import ARKit

extension ARMeshClassification {

    var description: String {
        switch self {
        case .ceiling: return "Ceiling"
        case .door: return "Door"
        case .floor: return "Floor"
        case .seat: return "Seat"
        case .table: return "Table"
        case .wall: return "Wall"
        case .window: return "Window"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }
}

