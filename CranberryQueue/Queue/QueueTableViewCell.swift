//
//  QueueTableViewCell.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol QueueCellDelegate: class {
    func voteTapped(isUpvote: Bool, song: Song)
}

class QueueTableViewCell: UITableViewCell {

    @IBOutlet weak var voteLabel: UILabel!
    
    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var songLabel: UILabel!
    
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var upvoteButtonImageView: UIImageView!
    
    @IBOutlet var downvoteButtonImageView: UIImageView!
    
    @IBOutlet var shadowView: UIView!
    
    var uid: String? = nil
    
    var songId: String? = nil
    var song: Song? = nil
    
    var db: Firestore? = nil
    
    var shadowLayer = CALayer()
    var gradientLayer = CAGradientLayer()
    
    var shadOpacity: Float = 1
    
    weak var delegate: QueueCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        db = Firestore.firestore()

        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        let upvoteTap = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped))
        upvoteButtonImageView.addGestureRecognizer(upvoteTap)
        upvoteButtonImageView.isUserInteractionEnabled = true
        
        let downvoteTap = UITapGestureRecognizer(target: self, action: #selector(downvoteTapped))
        downvoteButtonImageView.addGestureRecognizer(downvoteTap)
        downvoteButtonImageView.isUserInteractionEnabled = true
        
        downvoteButtonImageView.transform = CGAffineTransform(rotationAngle: 90*3.1415926/180)
        upvoteButtonImageView.transform = CGAffineTransform(rotationAngle: 270*3.1415926/180)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func addGradient() {
        gradientLayer.frame = CGRect(x: bounds.minX + 10, y: bounds.minY, width: bounds.width - 20, height: bounds.height)
        gradientLayer.colors = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5453749648).cgColor, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.1754601281).cgColor, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5453749648).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func removeGradient() {
        gradientLayer.removeFromSuperlayer()
    }
    
    func addShadow() {
        if (contentView.layer.sublayers?.contains(shadowLayer) ?? false) {
            return
        }
        
        shadowLayer = CALayer()
        let mutablePath = CGMutablePath()
        let maskLayer = CAShapeLayer()

        let usableBounds = CGRect(x: contentView.frame.minX + 10, y: contentView.frame.minY, width: contentView.frame.width - 20, height: contentView.frame.height)
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

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutSubviews()
    }
    
    @objc func upvoteTapped() {
         self.db?.collection("song").document(self.songId!).collection("upvoteUsers").document(self.uid!).setData(
            [:], completion: { (err) in
                self.delegate?.voteTapped(isUpvote: true, song: self.song!)
         })
    }
    
    @objc func downvoteTapped() {
        self.db?.collection("song").document(self.songId!).collection("downvoteUsers").document(self.uid!).setData(
            [:], completion: { (err) in
                self.delegate?.voteTapped(isUpvote: false, song: self.song!)
        })
    }

}
