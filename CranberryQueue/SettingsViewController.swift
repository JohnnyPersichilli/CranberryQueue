//
//  SettingsViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/15/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet var uidLabel: UILabel!
    
    var uid: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uidLabel.text = uid ?? "fail"
        
        
    }
    
}
