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
    @IBOutlet weak var modalView: UIView!
    
    @IBOutlet var queueNameTextField: UITextField!
    
    @IBOutlet var scopeSwitch: UISwitch!
    
    @IBOutlet var scopeLabel: UILabel!
    
    @IBOutlet var cancelIconImageView: UIImageView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
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
        
        modalView.layer.cornerRadius = 5
        modalView.layer.borderWidth = 1
        modalView.layer.borderColor = UIColor.black.cgColor
        
        queueNameTextField.borderStyle = .roundedRect
        queueNameTextField.returnKeyType = .join
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        if scopeSwitch.isOn {
            setPublicToggleUI()
            queueNameTextField.becomeFirstResponder()
        }
        else {
            setPrivateToggleUI()
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
    
    func setPublicToggleUI(){
        queueNameTextField.text = ""
        queueNameTextField.textColor = UIColor.black
        queueNameTextField.isEnabled = true
        queueNameTextField.isOpaque = false
        scopeLabel.text = "Public"
    }
    
    func setPrivateToggleUI(){
        queueNameTextField.textColor = UIColor.gray
        queueNameTextField.text = eventCodeFromTimestamp()
        queueNameTextField.isEnabled = false
        queueNameTextField.isOpaque = true
        scopeLabel.text = "Private"
    }
}
