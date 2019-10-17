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
    func setQueue(_ queueId: String?)
    func getCoords() -> ([String:Double])
    func setLocationEnabled(_ val: Bool)
    func getDistanceFrom(_ queue: CQLocation) -> Double
}

class MapViewController: UIViewController, mapDelegate, UITextFieldDelegate, LoginDelegate, QueueMapDelegate {

    @IBOutlet var cityLabel: UILabel!

    @IBOutlet var regionLabel: UILabel!

    @IBOutlet var addIconImageView: UIImageView!
    
    @IBOutlet var searchIconImageView: UIImageView!
    
    @IBOutlet var homeIconImageView: UIImageView!
    
    @IBOutlet var createQueueForm: createQueueForm!
    
    @IBOutlet var joinQueueForm: JoinQueueForm!

    @IBOutlet var settingsIconImageView: UIImageView!

    @IBOutlet weak var loginContainer: UIView!
        
    @IBOutlet var playerView: PlayerView!
    
    @IBOutlet var queueDetailModal: QueueDetailModal!
    
    @IBOutlet weak var topDetailModalConstraint: NSLayoutConstraint!
    
    var db : Firestore? = nil

    var uid = String()
    var isHost = false
    var queueId: String? = nil
    var currMarkerData: CQLocation? = nil
    var code: String? = nil
    
    var playerController = PlayerController.sharedInstance

    weak var delegate: mapControllerDelegate?
    let colors = Colors()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db = Firestore.firestore()
        setupScreen()
        setupGestureRecognizers()
        createQueueForm.queueNameTextField.delegate = self
        joinQueueForm.eventCodeTextField.delegate = self

        UIApplication.shared.isIdleTimerDisabled = true
        
        playerView.delegate = playerController
        playerController.mapDelegate = playerView
        
        queueDetailModal.isHidden = true
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.delegate = playerController
        
        Auth.auth().signInAnonymously { (result, error) in
            if let data = result {
                self.uid = data.user.uid
            }
            else {
                print( error! )
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActiveNotification(notification:)),
        name: UIApplication.didBecomeActiveNotification,
        object: nil)
    }
    
    @objc func handleAppDidBecomeActiveNotification(notification: Notification) {
        if let isEnabled = UserDefaults.standard.object(forKey: "isLocationEnabled") as? Bool {
            if isEnabled {
                return
            }
            else {
                let alert = UIAlertController(title: "Location Services disabled", message: "Enable location to continue.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)

                }))
                self.present(alert, animated: true)
            }
        }
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self)
    }
    
    func setLocationEnabled(status: Bool) {
        if !status {
            if let _ = UserDefaults.standard.object(forKey: "isLocationEnabled") as? Bool {}
            else {
                return
            }
            let alert = UIAlertController(title: "Location services disabled", message: "Please enable location to continue.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }))
            self.present(alert, animated: true)
        }
    }
    
    func update(queueId: String?, isHost: Bool, privateCode: String?) {
        self.code = privateCode
        if privateCode != nil {
            self.addIconImageView.isHidden = true
            self.searchIconImageView.isHidden = true
            self.homeIconImageView.isHidden = false
        }
        else {
            self.addIconImageView.isHidden = false
            self.searchIconImageView.isHidden = false
            self.homeIconImageView.isHidden = true
        }
        
        self.queueId = queueId
        self.isHost = isHost
        self.delegate?.setQueue(queueId)
        self.delegate?.setLocationEnabled(true)
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
        
        let joinQueueTap = UITapGestureRecognizer(target: self, action: #selector(joinQueue as () -> ()))
        queueDetailModal.joinButton.addGestureRecognizer(joinQueueTap)
        queueDetailModal.joinButton.isUserInteractionEnabled = true
        
        let closeModalTap = UITapGestureRecognizer(target: self, action: #selector(closeDetailModalTapped))
        queueDetailModal.closeIconImageView.addGestureRecognizer(closeModalTap)
        queueDetailModal.closeIconImageView.isUserInteractionEnabled = true
        
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        searchIconImageView.addGestureRecognizer(searchTap)
        searchIconImageView.isUserInteractionEnabled = true
        
        let joinCancelTap = UITapGestureRecognizer(target: self, action: #selector(joinFormCancelTapped))
        joinQueueForm.cancelIconImageView.addGestureRecognizer(joinCancelTap)
        joinQueueForm.cancelIconImageView.isUserInteractionEnabled = true
        
        let homeTap = UITapGestureRecognizer(target: self, action: #selector(homeTapped))
        homeIconImageView.addGestureRecognizer(homeTap)
        homeIconImageView.isUserInteractionEnabled = true
    }
    
    @objc func homeTapped() {
        joinQueue(code: code!)
    }
    
    @objc func joinFormCancelTapped() {
        joinQueueForm.eventCodeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.joinQueueForm.alpha = 0
        }) { (val) in
            self.joinQueueForm.isHidden = true
        }
    }
    
    @objc func closeDetailModalTapped() {
       UIView.animate(withDuration: 0.3, animations: {
            self.topDetailModalConstraint.constant = 0
            self.queueDetailModal.alpha = 0
            self.view.layoutIfNeeded()
        }) { (_) in
            self.queueDetailModal.isHidden = true
        }
    }

    @objc func settingsTapped() {
        self.closeDetailModalTapped()
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        self.present(vc, animated:true, completion:nil)
    }
    
    @objc func searchTapped() {
        self.closeDetailModalTapped()
        joinQueueForm.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.joinQueueForm.alpha = 1
            self.joinQueueForm.eventCodeTextField.becomeFirstResponder()
        }
    }

    @objc func addTapped() {
        self.closeDetailModalTapped()
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == nil || textField.text == "" {
            return false
        }
        if textField == createQueueForm.queueNameTextField {
            createQueueForm.queueNameTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.3, animations: {
                self.createQueueForm.alpha = 0
            }) { (val) in
                self.createQueueForm.isHidden = true
            }
            if createQueueForm.scopeSwitch.isOn {
                createQueue(withName: createQueueForm.queueNameTextField.text ?? "")
            }
            else {
                createQueue(withCode: eventCodeFromTimestamp())
            }
        }
        else if textField == joinQueueForm.eventCodeTextField {
            joinQueueForm.eventCodeTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.3, animations: {
                self.joinQueueForm.alpha = 0
            }) { (val) in
                self.joinQueueForm.isHidden = true
            }
            joinQueue(code: textField.text!)
        }
        return true
    }

    func dismissLoginContainer() {
        DispatchQueue.main.async {
            self.loginContainer.isHidden = true
        }
    }
    
    func openDetailModal(data: CQLocation) {
        // Setup modal in child, animate from parent
        if(!queueDetailModal.isHidden && self.currMarkerData?.queueId == data.queueId){
            UIView.animate(withDuration: 0.3, animations: {
                self.topDetailModalConstraint.constant = 0
                self.queueDetailModal.alpha = 0
                self.view.layoutIfNeeded()
            }) { (_) in
                self.queueDetailModal.isHidden = true
            }
        }
        else { // clicked a different window while its open, dont close just rerender the data
            self.currMarkerData = data
            let distance = delegate?.getDistanceFrom(data)
            queueDetailModal.distance = distance ?? 0
            queueDetailModal.db = db
            queueDetailModal.currentQueue = data
            queueDetailModal.fetchSongInfo()
            
            self.queueDetailModal.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.topDetailModalConstraint.constant = -170
                self.queueDetailModal.alpha = 1
                self.view.layoutIfNeeded()
            }) { (_) in }
        }
        
    }
    
    
    func joinQueue(code: String) {
        db?.collection("location").whereField("code", isEqualTo: code).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            if snap.documents.count == 0 { return }
            let id = snap.documents[0].documentID
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
            vc.queueName = code
            vc.queueId = id
            vc.uid = self.uid
            vc.isPrivate = true
            
            vc.mapDelegate = self
            
            if self.queueId != vc.queueId {
                self.leaveCurrentQueue()
            }
            
            self.db?.collection("contributor").document(id).collection("members").document(self.uid).setData([:
                 ], completion: { (val) in
                     })
            
            self.db?.collection("contributor").document(id).getDocument(completion: { (snapshot, error) in
                if let err = error {
                    print(err)
                }
                //see if the users was previously in the queue, if they were numMembers does not change
                if let host = snapshot?.data()?["host"] as? String {
                    if self.uid == host {
                        vc.isHost = true
                        vc.isRejoining = true
                    }
                }
                self.delegate?.setLocationEnabled(false)
                self.present(vc, animated:true, completion:nil)
            })
        })
        
    }
    
    @objc func joinQueue() {
        self.closeDetailModalTapped()
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
        
        let data = currMarkerData as! CQLocation
        
        vc.queueName = data.name
        vc.queueId = data.queueId
        vc.uid = self.uid
        vc.isHost = false
        
        vc.mapDelegate = self
        
        DispatchQueue.main.async {
            self.delegate?.setQueue(data.queueId)
        }
        
        if self.queueId != vc.queueId {
            leaveCurrentQueue()
        }
        
        db?.collection("contributor").document(data.queueId).collection("members").document(self.uid).setData([:
             ], completion: { (val) in
                 })
        
        db?.collection("contributor").document(data.queueId).getDocument(completion: { (snapshot, error) in
            if let err = error {
                print(err)
            }
            //see if the users was previously in the queue, if they were numMembers does not change
            if let host = snapshot?.data()?["host"] as? String {
                if self.uid == host {
                    vc.isHost = true
                    vc.isRejoining = true
                }
            }
            self.delegate?.setLocationEnabled(false)
            self.present(vc, animated:true, completion:nil)
        })
    }
    
    func createQueue(withCode code: String) {
        self.closeDetailModalTapped()
        var ref : DocumentReference? = nil
        ref = db?.collection("contributor").addDocument(data: [
            "host": self.uid
        ]) { (val) in
            let id = ref!.documentID
            self.delegate?.setQueue(id)
            
            self.db?.collection("location").document(id).setData([
                "numMembers": 0,
                "currentSong": "",
                "code" : code
                ])
            
            self.leaveCurrentQueue()
            
            self.db?.collection("contributor").document(id).collection("members").document(self.uid).setData([:
                ], completion: { (val) in
            })

            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.startAppRemote()

            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

            let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
            vc.queueName = code
            vc.queueId = id
            vc.uid = self.uid
            vc.isHost = true
            vc.isPrivate = true
            vc.mapDelegate = self
            
            self.playerController.setupPlayer(queueId: id, isHost: true)
            self.delegate?.setLocationEnabled(false)
            self.present(vc, animated:true, completion:nil)
        }
            
    }

    func createQueue(withName name: String) {
        self.closeDetailModalTapped()
        let coords = delegate?.getCoords()

        var ref : DocumentReference? = nil
        ref = db?.collection("contributor").addDocument(data: [
            "host": self.uid
        ]) { (val) in
            let id = ref!.documentID
            self.delegate?.setQueue(id)
            
            self.db?.collection("location").document(id).setData([
                "lat" : coords?["lat"] ?? 0,
                "long" : coords?["long"] ?? 0,
                "city": self.cityLabel.text ?? "",
                "region": self.regionLabel.text ?? "",
                "numMembers": 0,
                "currentSong": "",
                "name" : name
                ])
            
            self.leaveCurrentQueue()
            
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
            
            self.playerController.setupPlayer(queueId: id, isHost: true)
            self.delegate?.setLocationEnabled(false)
            self.present(vc, animated:true, completion:nil)
        }
    }
    
    func leaveCurrentQueue() {
        if(self.queueId != nil){
            if(!isHost){
                let url = URL(string: "https://us-central1-cranberryqueue.cloudfunctions.net/removeFromMembers")!
                var request = URLRequest(url: url)
                let dictionary = ["queueId":self.queueId,"uid":self.uid]
                request.httpBody = try! JSONEncoder().encode(dictionary)
                request.httpMethod = "PUT"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let err = error {
                        print(err)
                        return
                    }
                }
                task.resume()
            }else{
                self.db?.collection("location").document(self.queueId!).delete()
            }
        }
    }
    
    func eventCodeFromTimestamp() -> String {
        let possibleChars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/")
        var rixit = 0
        var residual = Int(Double(Date().timeIntervalSince1970)*1000) / 64
        var result = ""
        while(residual != 0) {
            rixit = residual % 64
            result = String(possibleChars[rixit]) + result;
            residual = (residual / 64);
        }
        result.removeFirst(1)
        return result;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController
        {
            let vc = segue.destination as? MapController
            vc?.delegate = self
            self.delegate = vc
        }
        else if segue.destination is LoginController {
            let vc = segue.destination as? LoginController
            vc?.delegate = self
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
