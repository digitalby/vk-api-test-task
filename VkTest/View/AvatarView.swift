//
//  AvatarView.swift
//  VkTest
//
//  Created by Digital on 29.10.2020.
//

import UIKit

@IBDesignable class AvatarView: UIImageView {
    @IBInspectable var inspectableCornerRadius: CGFloat = 0.0 {
        didSet {
            updateRadius()
        }
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        updateRadius()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateRadius()
        layer.borderWidth = 4.0
        layer.borderColor = UIColor.lightGray.cgColor
    }

    private func updateRadius() {
        layer.cornerRadius = inspectableCornerRadius
        clipsToBounds = true
    }
}
