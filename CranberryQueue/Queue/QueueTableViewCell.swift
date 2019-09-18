//
//  QueueTableViewCell.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

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
    
    var db: Firestore? = nil
    
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
        
        shadowView.layer.shadowRadius = 15
        shadowView.layer.shadowColor = UIColor.black.cgColor
        self.clipsToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func upvoteTapped() {
         self.db?.collection("song").document(self.songId!).collection("upvoteUsers").document(self.uid!).setData(
            [:], completion: { (err) in
         })
    }
    
    @objc func downvoteTapped() {
        self.db?.collection("song").document(self.songId!).collection("downvoteUsers").document(self.uid!).setData(
            [:], completion: { (err) in
        })
    }

}
