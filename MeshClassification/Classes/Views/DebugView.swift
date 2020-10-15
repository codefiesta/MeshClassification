//
//  DebugView.swift
//  MeshClassification
//
//  Created by Kevin McKee on 10/12/20.
//

import ARKit
import UIKit

class DebugView: UIView {
    
    private var stackView: UIStackView!
    private var positionLabel: UILabel!
    private var directionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        
        positionLabel = buildLabel()
        positionLabel.text = "Position: "
        directionLabel = buildLabel()
        directionLabel.text = "Direction: "
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        addSubview(stackView)
        stackView.pinToEdges()
        
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        layer.cornerRadius = 4
        
        stackView.addArrangedSubview(positionLabel)
        stackView.addArrangedSubview(directionLabel)
    }
    
    private func buildLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func update(_ frame: ARFrame) {
        let transform = frame.camera.transform
        let orientation = frame.camera.eulerAngles
        let position = transform.columns.3.xyz
        positionLabel.text = "Position: [\(position.x), \(position.y), \(position.z)]"
        directionLabel.text = "Direction: [\(orientation.x), \(orientation.y), \(orientation.z)]"
    }
}
