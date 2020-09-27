//
//  UIView+Extensions.swift
//  MeshClassification
//
//  Created by Kevin McKee on 9/27/20.
//

import UIKit

extension UIView {
    
    @discardableResult
    func pinToEdges(_ top: CGFloat = 0, _ right: CGFloat = 0, _ bottom: CGFloat = 0, _ left: CGFloat = 0) -> Self {

        guard let parent = superview else { return self }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor, constant: top),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -right),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -bottom),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: left)
        ])
        setNeedsLayout()
        return self
    }

}
