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
        
        shadowView.layer.shadowRadius = 15
        shadowView.layer.shadowColor = UIColor.black.cgColor
        self.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
