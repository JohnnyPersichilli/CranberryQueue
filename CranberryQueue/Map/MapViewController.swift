//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

protocol mapControllerDelegate: class {
    func addTapped()
    func setQueue(_ queueId: String?)
    func getCoords() -> ([String:Double])
    func setLocationEnabled(_ val: Bool)
}

class MapViewController: UIViewController, mapDelegate, UITextFieldDelegate, LoginDelegate, QueueMapDelegate {

    @IBOutlet var cityLabel: UILabel!

    @IBOutlet var regionLabel: UILabel!

    @IBOutlet var addIconImageView: UIImageView!

    @IBOutlet var createQueueForm: createQueueForm!

    @IBOutlet var settingsIconImageView: UIImageView!

    @IBOutlet weak var loginContainer: UIView!
        
    @IBOutlet var playerView: PlayerView!
    

    @IBOutlet weak var queueDetailModal: UIView!
    @IBOutlet weak var queueNameLabel: UILabel!
    @IBOutlet weak var joinQueueButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var numMembersLabel: UILabel!
    @IBOutlet weak var closeQueueDetailImage: UIImageView!
    @IBOutlet weak var songImage: UIRoundedImageView!
    @IBOutlet weak var distanceFromQueueLabel: UILabel!
    
    var db : Firestore? = nil

    var uid = String()
    var isHost = false
    var queueId: String? = nil
    var currMarkerData: CQLocation? = nil
    
    var playerController = PlayerController.sharedInstance

    weak var delegate: mapControllerDelegate?
    let colors = Colors()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db = Firestore.firestore()
        setupScreen()
        setupGestureRecognizers()
        createQueueForm.queueNameTextField.delegate = self

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
    
    func update(queueId: String?, isHost: Bool) {
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
        
        let joinQueueTap = UITapGestureRecognizer(target: self, action: #selector(joinQueue))
        joinQueueButton.addGestureRecognizer(joinQueueTap)
        joinQueueButton.isUserInteractionEnabled = true
        
        let closeModalTap = UITapGestureRecognizer(target: self, action: #selector(closeModalTapped))
        closeQueueDetailImage.addGestureRecognizer(closeModalTap)
        closeQueueDetailImage.isUserInteractionEnabled = true
        
    }
    
    @objc func closeModalTapped() {
        queueDetailModal.isHidden = true
        self.currMarkerData = nil
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
    
    func openDetailModal(data: CQLocation) {        
        //if the window is open and click the same marker close the window
        if(!queueDetailModal.isHidden && self.currMarkerData?.queueId==data.queueId){
            queueDetailModal.isHidden = true
            print("window closed")
        //click a different window while its open, dont close just rerender the data
        }else{
            queueDetailModal.isHidden = false
            let myCoords = delegate?.getCoords()
            let myLocation = CLLocation(latitude: myCoords?["lat"] ?? 0, longitude: myCoords?["long"] ?? 0)
            let queueLocation = CLLocation(latitude: data.lat, longitude: data.long)
            let distance = myLocation.distance(from: queueLocation)
            
            //if distance is less than .75 miles use feet else use miles
            if(distance/1609 < 0.75){
                let distanceInFeet = (distance*3.28083985)
                let roundedFeetString = String(format: "%.2f", distanceInFeet)
                distanceFromQueueLabel.text = roundedFeetString + " ft"
            }else{
                let distanceInMiles = (distance/1609)
                let roundedMileString = String(format: "%.1f", distanceInMiles)
                distanceFromQueueLabel.text =  roundedMileString + " mi"
            }
            
            
            
            //can set this as the radius if we are letting users do that or an arbitrary number like 500m
            let maxDistance = 500.0
            if(distance > maxDistance){
                joinQueueButton.isEnabled = false
                joinQueueButton.layer.cornerRadius = 10
                joinQueueButton.backgroundColor = UIColor.red.withAlphaComponent(0.3)
                joinQueueButton.isOpaque = true
            }else{
                joinQueueButton.isEnabled = true
                joinQueueButton.layer.cornerRadius = 10
                joinQueueButton.backgroundColor = UIColor(red: 0.349, green: 0.663, blue: 0.486, alpha: 1)
                joinQueueButton.isOpaque = false
            }
            self.currMarkerData = data
            self.db?.collection("playback").document(data.queueId).getDocument(completion: { (snapshot, error) in
                if let err = error {
                    print(err)
                }
                
                let currSong = snapshot?.data()?["name"] as? String ?? ""
                let currArtist = snapshot?.data()?["artist"] as? String ?? ""
                let songImage = snapshot?.data()?["imageURL"] as? String ?? ""
                
                if(songImage != ""){
                    let url = URL(string: songImage)
                    let task = URLSession.shared.dataTask(with: url!) {(dataBack, response, error) in
                        guard let data2 = dataBack else {
                            print("no data")
                            return }
                        DispatchQueue.main.async {
                            self.songImage.image = UIImage(data: data2)
                            self.queueNameLabel.text = data.name
                            self.songNameLabel.text = currSong + " - " + currArtist
                            self.numMembersLabel.text = String(data.numMembers)
                        }
                    }
                    
                    task.resume()
                }else{
                    DispatchQueue.main.async {
                        self.numMembersLabel.text = String(data.numMembers)
                        self.queueNameLabel.text = data.name
                        self.songImage.image = UIImage(named: "defaultPerson")!
                        self.songNameLabel.text = "No song currently playing"
                    }
                }
            })
        }
    }
    
    @objc func joinQueue() {
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
        
        if(self.queueId != nil && self.queueId != vc.queueId){
            if(!isHost){
                let url = URL(string: "https://us-central1-cranberryqueue.cloudfunctions.net/removeFromMembers")!
                var request = URLRequest(url: url)
                let dictionary = ["queueId":self.queueId,"uid":self.uid]
                request.httpBody = try! JSONEncoder().encode(dictionary)
                request.httpMethod = "PUT"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    //if let res = response { }
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

    func createQueue(withName name: String) {
        
        
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
            
            if( (self.queueId) != nil && !self.isHost ){
                self.db?.collection("contributor").document(self.queueId!).collection("members").document(self.uid).delete()
            }else if( (self.queueId) != nil && self.isHost){
                self.db?.collection("location").document(self.queueId!).delete()
            }
            
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController
        {
            let vc = segue.destination as? MapController
            vc?.delegate = self
            self.delegate = vc
        }
        if segue.destination is LoginController {
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
