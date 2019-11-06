//
//  SearchTableViewCell.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {

    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var songLabel: UILabel!
    
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var addIconImageView: UIImageView!
    
    var song = Song()
    
    var shadowLayer = CALayer()
    var gradientLayer = CAGradientLayer()
    var shadOpacity: Float = 1
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        self.addShadow()
    }
    
    func addShadow() {
        if (contentView.layer.sublayers?.contains(shadowLayer) ?? false) {
            return
        }
        
        shadowLayer = CALayer()
        let mutablePath = CGMutablePath()
        let maskLayer = CAShapeLayer()

        let usableBounds = CGRect(x: contentView.frame.minX + 5, y: contentView.frame.minY + 1 , width: self.bounds.width + addIconImageView.bounds.width , height: contentView.frame.height - 2)
        let xOffset = CGFloat(2.3)
        let yOffset = CGFloat(4)
        let shadowOffset = CGSize(width: xOffset, height: yOffset)
        let shadowOpacity = shadOpacity
        let shadowRadius = CGFloat(3)
        let shadowPath = UIBezierPath(rect: usableBounds).cgPath
        let shadowColor = UIColor.black
        let shadowFrame = usableBounds.insetBy(dx: -2 * shadowRadius, dy: -2 * shadowRadius).offsetBy(dx: xOffset, dy: yOffset)
        let shadowRect = CGRect(origin: .zero, size: shadowFrame.size)
        let shadowTransform = CGAffineTransform(translationX: -usableBounds.origin.x - xOffset + 2 * shadowRadius, y: -usableBounds.origin.y - yOffset + 2 * shadowRadius)

        shadowLayer.shadowOffset = shadowOffset
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
        shadowLayer.shadowPath = shadowPath
        shadowLayer.shadowColor = shadowColor.cgColor

        mutablePath.addRect(shadowRect)
        mutablePath.addPath(shadowLayer.shadowPath!, transform: shadowTransform)
        mutablePath.closeSubpath()

        maskLayer.frame = shadowFrame
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.path = mutablePath

        shadowLayer.mask = maskLayer
        contentView.layer.insertSublayer(shadowLayer, above: layer)
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
