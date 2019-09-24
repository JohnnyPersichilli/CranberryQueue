//
//  LoginViewController.swift
//  CranberryQueue
//
//  Created by Carl Reiser on 9/23/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.


import UIKit
import Firebase

protocol LoginDelegate: class {
    func dismissLoginContainer()
}

class LoginController: UIViewController, SessionDelegate {
    @IBOutlet weak var spotifyLabel: UILabel!
    
    @IBOutlet weak var guestLabel: UILabel!
        
    weak var delegate: LoginDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let spotifyLabelTap = UITapGestureRecognizer(target: self, action: #selector(spotifyLabelTapped))
        spotifyLabel.addGestureRecognizer(spotifyLabelTap)
        spotifyLabel.isUserInteractionEnabled = true
        
        let guestLabelTap = UITapGestureRecognizer(target: self, action: #selector(guestLabelTapped))
        guestLabel.addGestureRecognizer(guestLabelTap)
        guestLabel.isUserInteractionEnabled = true
    }
    
    @objc func spotifyLabelTapped() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.seshDelegate = self
        delegate.startSession()
    
        print("spot label tap")
    }

    
    @objc func guestLabelTapped() {
        print("guest label tap")
    }
    
    func updateSessionStatus(connected: Bool) {
        if(connected) {
            delegate?.dismissLoginContainer()
        }
        print(connected)
    }
}

