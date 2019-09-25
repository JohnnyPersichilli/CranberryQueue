//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol mapControllerDelegate: class {
    func addTapped()
    func getCoords() -> ([String:Double])
    func setUID(id: String)
}

class MapViewController: UIViewController, mapDelegate, UITextFieldDelegate, LoginDelegate {

    @IBOutlet var cityLabel: UILabel!
    
    @IBOutlet var regionLabel: UILabel!
    
    @IBOutlet var addIconImageView: UIImageView!
    
    @IBOutlet var createQueueForm: createQueueForm!
    
    @IBOutlet var settingsIconImageView: UIImageView!
    
    @IBOutlet weak var loginContainer: UIView!
    
    
    var db : Firestore? = nil
    
    var uid = String()
    
    weak var delegate: mapControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        setupScreen()
        setupGestureRecognizers()
        
        createQueueForm.queueNameTextField.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func updateGeoCode(city: String, region: String) {
        cityLabel.text = city
        regionLabel.text = region
    }
    
    func setupScreen() {
        self.navigationController?.isNavigationBarHidden = true
        
        view.backgroundColor = UIColor.clear
        
        let colors = Colors()
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
        
    }
    
    func setupGestureRecognizers() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped))
        addIconImageView.addGestureRecognizer(addTap)
        addIconImageView.isUserInteractionEnabled = true
        
        let settingsTap = UITapGestureRecognizer(target: self, action: #selector(settingsTapped))
        settingsIconImageView.addGestureRecognizer(settingsTap)
        settingsIconImageView.isUserInteractionEnabled = true
    }
    
    @objc func settingsTapped() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        self.present(vc, animated:true, completion:nil)
    }
    
    @objc func addTapped() {
        delegate?.addTapped()
        createQueueForm.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.createQueueForm.alpha = 1
        }
        createQueueForm.queueNameTextField.becomeFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController
        {
            let vc = segue.destination as? MapController
            vc?.delegate = self
            vc?.uid = uid
            self.delegate = vc
            Auth.auth().signInAnonymously { (result, error) in
                if let data = result {
                    self.uid = data.user.uid
                    self.delegate?.setUID(id: data.user.uid)
                }
                else {
                    print( error! )
                }
            }
        }
        if segue.destination is PlayerViewController {
            //let vc = segue.destination as? PlayerViewController
            
        }
        if segue.destination is LoginController {
            let vc = segue.destination as? LoginController
            vc?.delegate = self
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createQueueForm.queueNameTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.createQueueForm.alpha = 0
        }) { (val) in
            self.createQueueForm.isHidden = true
        }
        
        createQueue(withName: createQueueForm.queueNameTextField.text ?? "")
        
        return true
    }
    
    func dismissLoginContainer() {
        DispatchQueue.main.async {
            self.loginContainer.isHidden = true
        }
    }
    
    func createQueue(withName name: String) {
        let coords = delegate?.getCoords()
        
        var ref : DocumentReference? = nil
        ref = db?.collection("location").addDocument(data: [
            "lat" : coords?["lat"] ?? 0,
            "long" : coords?["long"] ?? 0,
            "city": cityLabel.text ?? "",
            "region": regionLabel.text ?? "",
            "numMembers": 0,
            "currentSong": "",
            "name" : name
        ]) { (val) in
            let id = ref!.documentID
            self.db?.collection("contributor").document(id).setData([
                "host": self.uid
                ])
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.startAppRemote()
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            
            let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
            vc.queueName = self.createQueueForm.queueNameTextField.text
            vc.queueId = id
            vc.uid = self.uid
            vc.isHost = true
            self.present(vc, animated:true, completion:nil)
        }
    }

}

class Colors {
    var gl:CAGradientLayer? = nil
    var gl1:CAGradientLayer? = nil
    
    init() {
        let colorTop = UIColor(red: 166.0 / 255.0, green: 166.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 103.0 / 255.0, green: 122.0 / 255.0, blue: 161.0 / 255.0, alpha: 1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl?.colors = [colorTop, colorBottom]
        self.gl?.locations = [0.0, 1.0]
        
        self.gl1 = CAGradientLayer()
        self.gl1?.colors = [colorBottom, colorTop]
        self.gl1?.locations = [0.0, 1.0]
    }
}
