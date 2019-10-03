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
    func setQueueInfo(queueId: String, isHost: Bool)
}

class MapViewController: UIViewController, mapDelegate, UITextFieldDelegate, LoginDelegate, QueueMapDelegate {

    @IBOutlet var cityLabel: UILabel!

    @IBOutlet var regionLabel: UILabel!

    @IBOutlet var addIconImageView: UIImageView!

    @IBOutlet var createQueueForm: createQueueForm!

    @IBOutlet var settingsIconImageView: UIImageView!

    @IBOutlet weak var loginContainer: UIView!
    
    @IBOutlet var playerHelpLabel: UILabel!
    
    @IBOutlet var playerView: PlayerView!
    
    var db : Firestore? = nil

    var uid = String()
    var isHost = false
    var queueId: String? = nil
    
    var playerController = PlayerController()

    weak var delegate: mapControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db = Firestore.firestore()

        setupScreen()
        setupGestureRecognizers()

        createQueueForm.queueNameTextField.delegate = self

        UIApplication.shared.isIdleTimerDisabled = true
        
        playerView.delegate = playerController
        playerController.mapDelegate = playerView
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.delegate = playerController
    }
    
    func update(queueId: String?, isHost: Bool) {
        self.queueId = queueId
        self.isHost = isHost
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
    
    func joinQueue(data: CQLocation) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
        vc.queueName = data.name
        vc.queueId = data.queueId
        vc.uid = self.uid
        vc.isHost = false
        
        vc.mapDelegate = self
        vc.playerController = playerController
        
        
        if(self.queueId != nil && self.queueId != vc.queueId){
            if(!isHost){
                self.db?.collection("contributor").document(self.queueId!).collection("members").document(self.uid).delete()
            }else{
                self.db?.collection("location").document(self.queueId!).delete()
            }
        }
        
        self.db?.collection("contributor").document(data.queueId).collection("members").document(self.uid).setData([:
            ], completion: { (val) in
                })
        
        db?.collection("contributor").document(data.queueId).getDocument(completion: { (snapshot, error) in
            if let err = error {
                print(err)
            }
            if let host = snapshot?.data()?["host"] as? String {
                if self.uid == host {
                    vc.isHost = true
                }
            }
            self.present(vc, animated:true, completion:nil)
        })
    }

    func createQueue(withName name: String) {
        if( (self.queueId) != nil && !isHost ){
            self.db?.collection("contributor").document(self.queueId!).collection("members").document(self.uid).delete()
        }else if( (self.queueId) != nil && isHost){
            self.db?.collection("contributor").document(self.queueId!).delete()
            
            self.db?.collection("song").whereField("queueId", isEqualTo: self.queueId).getDocuments(completion: { (snapshot, err) in
                guard let snap = snapshot else {
                    return
                }
                for doc in snap.documents {
                    doc.reference.delete()
                }
            })
            self.db?.collection("playlist").document(self.queueId!).delete()
            self.db?.collection("playback").document(self.queueId!).delete()
            self.db?.collection("location").document(self.queueId!).delete()
        }
        
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
            
            self.db?.collection("contributor").document(id).collection("members").document(self.uid).setData([:
                ], completion: { (val) in
            })

            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.startAppRemote()

            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

            let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
            vc.queueName = self.createQueueForm.queueNameTextField.text
            vc.queueId = id
            vc.uid = self.uid
            vc.isHost = true
            vc.mapDelegate = self
            
            vc.playerController = self.playerController
            self.playerController.setupPlayer(queueId: id, isHost: true)
            
            self.present(vc, animated:true, completion:nil)
        }
    }
    
}

class Colors {
    var gl:CAGradientLayer? = nil
    var gl1:CAGradientLayer? = nil
    var themeDark: CGColor? = nil
    var themeLight: CGColor? = nil
    var themeBorderColor: CGColor? = nil

    init() {
        let colorTop = UIColor(red: 166.0 / 255.0, green: 166.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 103.0 / 255.0, green: 122.0 / 255.0, blue: 161.0 / 255.0, alpha: 1.0).cgColor

        self.gl = CAGradientLayer()
        self.gl?.colors = [colorTop, colorBottom]
        self.gl?.locations = [0.0, 1.0]

        self.gl1 = CAGradientLayer()
        self.gl1?.colors = [colorBottom, colorTop]
        self.gl1?.locations = [0.3, 1.0]

        let colorDark = UIColor(red: 73.0 / 255.0, green: 71.0 / 255.0, blue: 71.0 / 255.0, alpha: 1.0).cgColor
        let colorLight = UIColor(red: 48.0 / 255.0, green: 65.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0).cgColor

        let colorBorder = UIColor(red: 85.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0).cgColor

        self.themeBorderColor = colorBorder
        self.themeDark = colorDark
        self.themeLight = colorLight
    }
}
