//
//  createQueueForm.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class createQueueForm: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet var queueNameTextField: UITextField!
    
    @IBOutlet var scopeSwitch: UISwitch!
    
    @IBOutlet var scopeLabel: UILabel!
    
    @IBOutlet var cancelIconImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("createQueueForm", owner: self, options: nil)
        contentView.fixInView(self)
        
        queueNameTextField.borderStyle = .none
        queueNameTextField.returnKeyType = .join
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        if scopeSwitch.isOn {
            scopeLabel.text = "Public"
        }
        else {
            scopeLabel.text = "Private"
        }
    }
    
}
