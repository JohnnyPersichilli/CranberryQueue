//
//  LoginViewController.swift
//  CranberryQueue
//
//  Created by Carl Reiser on 9/23/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.


import UIKit
import Firebase
import MediaPlayer

protocol LoginDelegate: class {
    func dismissLoginContainer()
}

class LoginController: UIViewController, SessionDelegate {
    @IBOutlet weak var spotifyContinueModal: UIView!
    @IBOutlet weak var guestContinueModal: UIView!
    @IBOutlet weak var loginButton: UIView!
    @IBOutlet weak var continueButton: UIView!
    @IBOutlet weak var volumeSlider: MPVolumeView!
    
    weak var delegate: LoginDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let spotifyLabelTap = UITapGestureRecognizer(target: self, action: #selector(spotifyLabelTapped))
        loginButton.addGestureRecognizer(spotifyLabelTap)
        loginButton.isUserInteractionEnabled = true
        
        let guestLabelTap = UITapGestureRecognizer(target: self, action: #selector(guestLabelTapped))
        continueButton.addGestureRecognizer(guestLabelTap)
        continueButton.isUserInteractionEnabled = true

            setupUI()
    }
    
    func setupUI() {
        let colors = Colors()
        spotifyContinueModal.layer.cornerRadius = 13
        spotifyContinueModal.layer.borderWidth = 1
        spotifyContinueModal.layer.borderColor = colors.themeBorderColor
        
        guestContinueModal.layer.cornerRadius = 13
        guestContinueModal.layer.borderWidth = 1
        guestContinueModal.layer.borderColor = colors.themeBorderColor
        
        loginButton.layer.cornerRadius = 14
        continueButton.layer.cornerRadius = 14
        
        //hide volume slider
        volumeSlider.showsRouteButton = false
        volumeSlider.showsVolumeSlider = false
        volumeSlider.isHidden = true
    }
    
    @objc func spotifyLabelTapped() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        volumeSlider.volumeSlider.value = 0
        delegate.seshDelegate = self
        delegate.startSession()
    
    }

    @objc func guestLabelTapped() {
        
    }
    
    func updateSessionStatus(connected: Bool) {
        if(connected) {
            delegate?.dismissLoginContainer()
        }
        print(connected)
    }
}

extension MPVolumeView {
    var volumeSlider:UISlider {
        self.showsRouteButton = false
        self.showsVolumeSlider = false
        self.isHidden = true
        var slider = UISlider()
        for subview in self.subviews {
            if subview is UISlider {
                slider = subview as! UISlider
                slider.isContinuous = false
                (subview as! UISlider).value = AVAudioSession.sharedInstance().outputVolume
                return slider
            }
        }
        return slider
    }
}
