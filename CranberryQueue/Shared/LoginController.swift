//
//  LoginViewController.swift
//  CranberryQueue
//
//  Created by Carl Reiser on 9/23/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.


import UIKit
import Firebase

protocol LoginMapDelegate: class {
    func dismissLoginContainer(isPremium: Bool)
}

class LoginController: UIViewController, SessionDelegate, activityIndicatorPresenter {
    @IBOutlet weak var spotifyContinueModal: UIView!
    @IBOutlet weak var guestContinueModal: UIView!
    @IBOutlet weak var loginButton: UIView!
    @IBOutlet weak var continueButton: UIView!
    
    var activityIndicator = UIActivityIndicatorView()
    
    weak var loginMapDelegate: LoginMapDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let spotifyLabelTap = UITapGestureRecognizer(target: self, action: #selector(spotifyLabelTapped))
        loginButton.addGestureRecognizer(spotifyLabelTap)
        loginButton.isUserInteractionEnabled = true
        
        let guestLabelTap = UITapGestureRecognizer(target: self, action: #selector(guestLabelTapped))
        continueButton.addGestureRecognizer(guestLabelTap)
        continueButton.isUserInteractionEnabled = true
        
        setupModalUI()
    }
    
    func setupModalUI() {
        spotifyContinueModal.layer.cornerRadius = 13
        spotifyContinueModal.layer.borderWidth = 1
        spotifyContinueModal.layer.borderColor = Colors.border.cgColor
        
        guestContinueModal.layer.cornerRadius = 13
        guestContinueModal.layer.borderWidth = 1
        guestContinueModal.layer.borderColor = Colors.border.cgColor
        
        loginButton.layer.cornerRadius = 14
        continueButton.layer.cornerRadius = 14
    }
    
    @objc func spotifyLabelTapped() {
        UIView.animate(withDuration: 1, animations: {
            self.spotifyContinueModal.alpha = 0;
            self.guestContinueModal.alpha = 0
        }) { (Bool) in
            self.showActivityIndicator()
        }
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.seshDelegate = self
        delegate.startSession()
    }

    
    @objc func guestLabelTapped() {
        loginMapDelegate?.dismissLoginContainer(isPremium: false)
    }
    
    func updateSessionStatus(connected: Bool) {
        if(connected) {
            loginMapDelegate?.dismissLoginContainer(isPremium: true)
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.spotifyContinueModal.alpha = 1
                self.guestContinueModal.alpha = 1
                self.hideActivityIndicator()
            }
        }
        else {
            UIView.animate(withDuration: 1, animations: {
                self.spotifyContinueModal.alpha = 1;
                self.guestContinueModal.alpha = 1
            }) { (Bool) in
                self.hideActivityIndicator()
            }
        }
    }
}

