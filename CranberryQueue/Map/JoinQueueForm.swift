//
//  JoinQueueForm.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/16/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class JoinQueueForm: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet var eventCodeTextField: UITextField!
    
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
        Bundle.main.loadNibNamed("JoinQueueForm", owner: self, options: nil)
        contentView.fixInView(self)
        
        eventCodeTextField.returnKeyType = .join
    }

}
