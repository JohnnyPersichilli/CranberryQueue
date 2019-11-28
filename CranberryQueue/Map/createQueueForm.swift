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
    @IBOutlet weak var createPrivateButton: UIButton!
    
    var privateCode: String? = nil
    
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
        createPrivateButton.isHidden = true
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        if scopeSwitch.isOn {
            createPrivateButton.isHidden = true
            
            privateCode = nil
            queueNameTextField.text = ""
            queueNameTextField.textColor = UIColor.black
            queueNameTextField.isEnabled = true
            queueNameTextField.becomeFirstResponder()
            queueNameTextField.isOpaque = false
            scopeLabel.text = "Public"
        }
        else {
            createPrivateButton.isHidden = false
            
            privateCode = eventCodeFromTimestamp()
            queueNameTextField.textColor = UIColor.gray
            queueNameTextField.text = privateCode
            queueNameTextField.isEnabled = false
            queueNameTextField.isOpaque = true
            scopeLabel.text = "Private"
        }
    }
    
    // Takes the current timestamp in decimal and returns a short string of base n
    func eventCodeFromTimestamp() -> String {
        /// choose possible characters
        let possibleChars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/")
        let radix = possibleChars.count
        var rixit = 0
        var residual = Int(Double(Date().timeIntervalSince1970)*1000) / radix
        var result = ""
        /// modulo timestamp by radix and repeat until done
        while(residual != 0) {
            rixit = residual % radix
            result = String(possibleChars[rixit]) + result;
            residual = (residual / radix);
        }
        result.removeFirst(1)
        return result;
    }
}
