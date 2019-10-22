//
//  SettingsTableViewCell.swift
//  CranberryQueue
//
//  Created by Johnny Persichilli on 10/21/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var moreDetailImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
