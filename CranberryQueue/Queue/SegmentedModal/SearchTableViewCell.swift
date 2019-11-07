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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
