//
//  SettingsTableViewCell.swift
//  CranberryQueue
//
//  Created by Johnny Persichilli on 10/21/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var optionsNameLabel: UILabel!
    @IBOutlet weak var moreDetailOptionImage: UIImageView!
    
    var currentlySelectedText: [String: String]? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupGestureRecognizers()
    }
    
    func setupGestureRecognizers() {
        //        let forwardSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        //        forwardSwipe.direction = .left
        let clickMoreInfo = UITapGestureRecognizer(target: self, action: #selector(moreInfo))
        moreDetailOptionImage.addGestureRecognizer(clickMoreInfo)
        moreDetailOptionImage.isUserInteractionEnabled = true
    }
    
    @objc func moreInfo(){
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
