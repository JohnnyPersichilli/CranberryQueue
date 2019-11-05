//
//  FeaturedTableViewCell.swift
//  CranberryQueue
//
//  Created by Johnny Persichilli on 11/3/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class FeaturedTableViewCell: UITableViewCell {

    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var addIconImageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var albumImageView: UIRoundedImageView!
    var song = Song()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        self.layer.borderColor = UIColor.clear.cgColor
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
