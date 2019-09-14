//
//  QueueTableViewCell.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class QueueTableViewCell: UITableViewCell {

    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var songLabel: UILabel!
    
    @IBOutlet var artistLabel: UILabel!
    
    @IBOutlet var upvoteButtonImageView: UIImageView!
    
    @IBOutlet var downvoteButtonImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        let upvoteTap = UITapGestureRecognizer(target: self, action: #selector(upvoteTapped))
        upvoteButtonImageView.addGestureRecognizer(upvoteTap)
        upvoteButtonImageView.isUserInteractionEnabled = true
        
        let downvoteTap = UITapGestureRecognizer(target: self, action: #selector(downvoteTapped))
        downvoteButtonImageView.addGestureRecognizer(downvoteTap)
        downvoteButtonImageView.isUserInteractionEnabled = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func upvoteTapped() {
        
    }
    
    @objc func downvoteTapped() {
        
    }

}
