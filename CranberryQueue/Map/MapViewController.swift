//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol ControllerMapDelegate: class {
    func addTapped()
    func setQueue(_ queueId: String?)
    func recenterMap()
    func getCoords() -> [String:Double]
    func getGeoCode(withLocation loc: [String:Double], completion: @escaping (String, String)->Void)
    func setLocationEnabled(_ val: Bool)
    func getDistanceFrom(_ queue: CQLocation) -> Double
}

class MapViewController: UIViewController, UITextFieldDelegate, MapControllerDelegate, LoginMapDelegate, QueueMapDelegate, SettingsMapDelegate, RemoteDelegate {
    
    
    // Labels
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var regionLabel: UILabel!

    // Views
    @IBOutlet weak var mapOptionsView: UIView!
    
    //Buttons
    @IBOutlet var settingsIconImageView: UIImageView!
    @IBOutlet weak var createIconImageView: UIImageView!
    @IBOutlet weak var privateSearchIconImageView: UIImageView!
    @IBOutlet weak var backToQueueIconImageView: UIImageView!
    
    // Forms
    @IBOutlet var createQueueForm: createQueueForm!
    @IBOutlet var joinQueueForm: JoinQueueForm!

    // Login Container
    @IBOutlet weak var loginContainer: UIView!

    // Playback view and controller
    @IBOutlet var playerView: PlayerView!
    var playerController = PlayerController.sharedInstance
    
    // Queue detail
    @IBOutlet var queueDetailModal: QueueDetailModal!
    @IBOutlet weak var topDetailModalConstraint: NSLayoutConstraint!
    @IBOutlet var bottomDetailModalConstraint: NSLayoutConstraint!
    
    // Personal delegates
    weak var controllerMapDelegate: ControllerMapDelegate?
    
    // Firebase
    var db : Firestore? = nil
    weak var playbackRef: ListenerRegistration? = nil
    
    // Global state vars
    var uid = String()
    var queueId: String? = nil
    var isHost = false
    var isPremium = false
    var code: String? = nil
    var name: String? = nil
    /// should open create modal when app remote connected
    var isWaitingForRemote = false
    
    var region: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScreen()
        setupGestureRecognizers()
        
        setupFirebase()
        setupDelegates()

        setupObservers()
    }

    func setupScreen() {
        self.mapOptionsView.layer.cornerRadius = 10
        self.navigationController?.isNavigationBarHidden = true
        let backgroundLayer = Colors.mapGradient
        backgroundLayer.frame = view.frame
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }

    func setupGestureRecognizers() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped))
        createIconImageView.addGestureRecognizer(addTap)
        createIconImageView.isUserInteractionEnabled = true

        let settingsTap = UITapGestureRecognizer(target: self, action: #selector(settingsTapped))
        settingsIconImageView.addGestureRecognizer(settingsTap)
        settingsIconImageView.isUserInteractionEnabled = true
        
        let joinQueueTap = UITapGestureRecognizer(target: self, action: #selector(joinQueue as () -> ()))
        queueDetailModal.joinButton.addGestureRecognizer(joinQueueTap)
        queueDetailModal.joinButton.isUserInteractionEnabled = true
        
        let closeModalTap = UITapGestureRecognizer(target: self, action: #selector(closeDetailModal))
        queueDetailModal.closeIconImageView.addGestureRecognizer(closeModalTap)
        queueDetailModal.closeIconImageView.isUserInteractionEnabled = true
        
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        privateSearchIconImageView.addGestureRecognizer(searchTap)
        privateSearchIconImageView.isUserInteractionEnabled = true

        let joinCancelTap = UITapGestureRecognizer(target: self, action: #selector(closeJoinForm))
        joinQueueForm.cancelIconImageView.addGestureRecognizer(joinCancelTap)
        joinQueueForm.cancelIconImageView.isUserInteractionEnabled = true
        
        let createCancelTap = UITapGestureRecognizer(target: self, action: #selector(closeCreateForm))
        createQueueForm.cancelIconImageView.addGestureRecognizer(createCancelTap)
        createQueueForm.cancelIconImageView.isUserInteractionEnabled = true

        let recenterMapTap = UITapGestureRecognizer(target: self, action: #selector(recenterMapTapped))
        backToQueueIconImageView.addGestureRecognizer(recenterMapTap)
        backToQueueIconImageView.isUserInteractionEnabled = true
        
        let playerHomeTap = UITapGestureRecognizer(target: self, action: #selector(homeTapped))
        playerView.addGestureRecognizer(playerHomeTap)
        playerView.isUserInteractionEnabled = true
    }
    
    func setupFirebase() {
        db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        db?.settings = settings
        Auth.auth().signInAnonymously { (result, error) in
            guard let data = result else {
                print(error!)
                return
            }
            self.uid = data.user.uid
        }
    }
    
    func setupDelegates() {
        createQueueForm.queueNameTextField.delegate = self
        joinQueueForm.eventCodeTextField.delegate = self
        
        playerView.delegate = playerController
        playerController.mapDelegate = playerView
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.appPlayerDelegate = playerController
        delegate.appMapDelegate = self
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActiveNotification(notification:)),
        name: UIApplication.didBecomeActiveNotification,
        object: nil)
    }
    
    // Called when user chooses an option in the login screen # LoginDelegate
    func dismissLoginContainer(isPremium: Bool) {
        self.isPremium = isPremium
        if isPremium {
            self.checkForReturningContributor(withId: self.uid)
        }
        DispatchQueue.main.async {
            self.loginContainer.isHidden = true
            self.createIconImageView.isHidden = !self.isPremium
        }
    }
    
    // Helper checks contributor database for user hosted queues and conditionally sets their local data
    func checkForReturningContributor(withId id: String) {
        db?.collection("contributor").whereField("id", isEqualTo: id).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            guard let oldQueueId = snap.documents.first?.data()["queueId"] as? String else {
                return
            }
            self.queueId = oldQueueId
            
            guard let isHost = snap.documents.first?.data()["isHost"] as? Bool else { return }
            if isHost {
                self.playerController.isHost = true
                self.isHost = true
                (UIApplication.shared.delegate as? AppDelegate)?.startAppRemote()
            }
            
            self.db?.collection("location").document(oldQueueId).getDocument(completion: { (snapshot, error) in
                guard let snap = snapshot else {
                    print(error!)
                    return
                }
                guard let oldQueueName = snap["name"] as? String else {
                    return
                }
                
                if let oldQueueCode = snap["code"] as? String {
                    self.presentQueueScreen(queueId: oldQueueId, name: oldQueueName, code: oldQueueCode, isHost: isHost)
                }
                else {
                    self.presentQueueScreen(queueId: oldQueueId, name: oldQueueName, code: nil, isHost: isHost)
                }
                self.name = oldQueueName
            })
            
            self.controllerMapDelegate?.setQueue(oldQueueId)
            self.playerController.queueId = oldQueueId
            self.playerController.db = self.db
        })
    }
    
    @objc func recenterMapTapped() {
        self.controllerMapDelegate?.recenterMap()
    }
    
    // Called when "+" icon tapped
    @objc func addTapped() {
        createQueueForm.queueNameTextField.text = ""
        self.closeDetailModal()
        self.closeJoinForm()
        /// tries to connect the app remote before opening the create queue modal
        isWaitingForRemote = true
        let del = UIApplication.shared.delegate as! AppDelegate
        del.startAppRemote()
    }
    
    // Called when appRemote has finished attempting to connect # RemoteDelegate
    func updateConnectionStatus(connected: Bool) {
        /// also called when app becomes active, so don't open modal
        if !isWaitingForRemote {
            return
        }
        isWaitingForRemote = false
        if connected {
            controllerMapDelegate?.addTapped()
            createQueueForm.isHidden = false
            UIView.animate(withDuration: 0.3) {
                self.createQueueForm.alpha = 1
            }
            createQueueForm.queueNameTextField.becomeFirstResponder()
            /// textfieldshouldreturn continues lifecycle
        }
        else {
            showAppRemoteAlert()
        }
    }
    
    // Helper to close create queue modal
    @objc func closeCreateForm() {
        isWaitingForRemote = false
        controllerMapDelegate?.setQueue(nil)
        createQueueForm.queueNameTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.createQueueForm.alpha = 0
        }) { (val) in
            self.createQueueForm.isHidden = true
            self.createQueueForm.scopeSwitch.isOn = true
        }
    }
    
    // Called when search icon is tapped
    @objc func searchTapped() {
        self.closeDetailModal()
        self.closeCreateForm()
        joinQueueForm.eventCodeTextField.text = ""
        joinQueueForm.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.joinQueueForm.alpha = 1
            self.joinQueueForm.eventCodeTextField.becomeFirstResponder()
            /// textfieldshouldreturn continues lifecycle
        }
    }
    
    // Helper to close join private queue modal
    @objc func closeJoinForm() {
        joinQueueForm.eventCodeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.joinQueueForm.alpha = 0
        }) { (val) in
            self.joinQueueForm.isHidden = true
        }
    }
    
    // Called when create or join textfield's keyboard enter is tapped
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /// empty textfield cannot be submitted
        if textField.text == nil || textField.text == "" {
            return false
        }
        /// determine which textfield called the delegate
        if textField == createQueueForm.queueNameTextField {
            /// create queue as either private or public queue from UISwitch
            if createQueueForm.scopeSwitch.isOn {
                createPublicQueue(withName: createQueueForm.queueNameTextField.text ?? "")
            }
            else {
                createPrivateQueue(withCode: eventCodeFromTimestamp())
            }
            /// close the create queue modal
            self.closeCreateForm()
        }
        else if textField == joinQueueForm.eventCodeTextField {
            /// join queue textfield is always private
            joinQueue(code: textField.text!)
            /// close the join queue modal
            closeJoinForm()
        }
        return true
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
    
    // Join queue from queue detail modal
    @objc func joinQueue() {
        let data = queueDetailModal.currentQueue!
        self.getIsUserHostOf(queueId: data.queueId) { (isHost) in
            self.presentQueueScreen(queueId: data.queueId, name: data.name, code: nil, isHost: isHost)
        }
    }
    
    // Join queue from search icon
    func joinQueue(code: String) {
        db?.collection("location").whereField("code", isEqualTo: code).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            if snap.documents.count == 0 { return }
            let id = snap.documents[0].documentID
            self.getIsUserHostOf(queueId: id) { (isHost) in
                self.presentQueueScreen(queueId: id, name: "", code: code, isHost: isHost)
            }
        })
    }
    
    // Create queue from add icon
    func createPublicQueue(withName name: String) {
        guard let coords = self.controllerMapDelegate?.getCoords() else { return }
        self.controllerMapDelegate?.getGeoCode(withLocation: coords, completion: { (city, region) in
            var ref : DocumentReference? = nil
            ref = self.db?.collection("location").addDocument(data: [
                "lat" : coords["lat"]!,
                "long" : coords["long"]!,
                "city": city,
                "region": region,
                "numMembers": 0,
                "currentSong": "",
                "name" : name
                ], completion: { (val) in
                    self.presentQueueScreen(queueId: ref!.documentID, name: name, code: nil, isHost: true)
            })
        })
    }
    
    // Convert state names to full name PA ~> Pennsylvania
    func convertToFullRegionName(region: String) -> String? {
        return Constants.stateDictionary[region]
    }

    // Create queue from create queue modal
    func createPrivateQueue(withCode code: String) {
        self.closeDetailModal()
        var ref : DocumentReference? = nil
        ref = self.db?.collection("location").addDocument(data: [
            "numMembers": 0,
            "currentSong": "",
            "code" : code,
            "name": createQueueForm.queueNameTextField.text ?? ""
            ], completion: { (val) in
                self.presentQueueScreen(queueId: ref!.documentID, name: code, code: code, isHost: true)
        })
    }
    
    // Helper presents the Queue View Controller with options
    func presentQueueScreen(queueId: String, name: String, code: String?, isHost: Bool){
        var isPrivate = false
        if code != nil {
            isPrivate = true
        }else{
            self.code = nil
        }
        
        self.controllerMapDelegate?.setQueue(queueId)
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
        vc.city = self.cityLabel.text
        vc.region = self.region
        vc.queueName = isPrivate ? code : name
        vc.queueId = queueId
        vc.uid = self.uid
        vc.isPrivate = isPrivate

        if self.queueId != queueId {
            self.leaveCurrentQueue()
        }

        self.db?.collection("contributor").document(self.uid).setData([
            "id": self.uid,
            "queueId": queueId,
            "isHost": isHost
        ])
        vc.isHost = isHost
        vc.mapDelegate = self
        vc.db = db
        self.present(vc, animated:true, completion:{
            self.controllerMapDelegate?.setLocationEnabled(false)
            self.closeDetailModal()
        })
    }
    
    // Helper removes user from their current queue or deletes the queue if they are the host
    func leaveCurrentQueue() {
        guard let queueId = queueId else {
            return
        }
        if isHost {
            self.db?.collection("location").document(queueId).delete()
            return
        }
        let url = URL(string: "https://us-central1-cranberryqueue.cloudfunctions.net/removeFromMembers")!
        var request = URLRequest(url: url)
        let dictionary = ["queueId":queueId,"uid":self.uid]
        request.httpBody = try! JSONEncoder().encode(dictionary)
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                print(err)
            }
        }
        task.resume()
    }
    
    // Checks if user is host of any queues by querying contributor table
    func getIsUserHostOf(queueId: String, completion: @escaping (Bool) -> Void) {
        db?.collection("contributor").document(self.uid).getDocument(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            guard let oldQueueId = snap.data()?["queueId"] as? String,
                let isHost = snap.data()?["isHost"] as? Bool else {
                completion(false)
                return
            }
            completion(oldQueueId == queueId && isHost)
        })
    }
    
    // Called by queue view controller when returning to map # QueueMapDelegate
    func update(queueId: String?, isHost: Bool, privateCode: String?, name: String?) {
        self.code = privateCode
        self.queueId = queueId
        self.isHost = isHost
        self.name = name
        self.controllerMapDelegate?.setQueue(queueId)
        self.controllerMapDelegate?.setLocationEnabled(true)
    }
    
    // Home tapped while in private queue brings user to queue screen
    @objc func homeTapped() {
        self.closeJoinForm()
        self.closeDetailModal()
        self.closeCreateForm()
        if(code != nil){
            joinQueue(code: code!)
        }else if(queueId != nil && name != nil){
            self.getIsUserHostOf(queueId: queueId!) { (isHost) in
                self.presentQueueScreen(queueId: self.queueId!, name: self.name!, code: nil, isHost: isHost)
            }
        }

    }
    
    // Called when settings icon is tapped
    @objc func settingsTapped() {
        self.closeDetailModal()
        self.closeJoinForm()
        self.closeCreateForm()
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        vc.mapDelegate = self
        self.present(vc, animated:true, completion:nil)
    }
    
    // Called when logout is tapped from settings # SettingsMapDelegate
    func logoutTapped() {
        loginContainer.isHidden = false
        isPremium = false
        if isHost {
            (UIApplication.shared.delegate as? AppDelegate)?.pauseAndDisconnectAppRemote()
            self.playerController.setupPlayer(queueId: nil, isHost: false)
        }
        isHost = false
        
        (UIApplication.shared.delegate as? AppDelegate)?.token = ""
    }
    
    // Called when geocode has been set by location manager # MapDelegate
    func updateGeoCode(city: String, region: String) {
        cityLabel.text = city
        self.region = region
        regionLabel.text = self.convertToFullRegionName(region: region) ?? region
    }
    
    // Called when map marker was tapped with location doc data # MapDelegate
    func toggleDetailModal(withData data: CQLocation) {
        /// Close if clicking same queue while modal is open
        if(!queueDetailModal.isHidden && queueDetailModal.currentQueue?.queueId == data.queueId){
            closeDetailModal()
            return
        }
        /// Reload and show if clicking new queue
        let distance = controllerMapDelegate?.getDistanceFrom(data)
        queueDetailModal.distance = distance ?? 0
        queueDetailModal.currentQueue = data
        /// Setup listener closure to update current song
        playbackRef = db?.collection("playback").document(data.queueId).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            /// Closes when doc is deleted
            if let doc = snap.data() {
                self.queueDetailModal.updateWithPlaybackDoc(doc: doc)
                self.showDetailModal()
            }
            else {
                self.closeDetailModal()
            }
        })
    }
    
    // Helper animates queue detail modal open
    func showDetailModal() {
        self.queueDetailModal.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.topDetailModalConstraint.isActive = false
            self.bottomDetailModalConstraint.isActive = true
            self.view.layoutIfNeeded()
            self.queueDetailModal.alpha = 1
        })
    }
    
    // Helper animates queue detail modal closed
    @objc func closeDetailModal() {
       UIView.animate(withDuration: 0.3, animations: {
            self.topDetailModalConstraint.isActive = true
            self.bottomDetailModalConstraint.isActive = false
            self.view.layoutIfNeeded()
            self.queueDetailModal.alpha = 0
        }) { (_) in
            self.queueDetailModal.isHidden = true
            self.playbackRef?.remove()
            self.playbackRef = nil
        }
    }
    
    // Called by location manager with an updated location authorization # MapDelegate
    func setLocationEnabled(status: Bool) {
        /// if disallowed escape first time users else show error
        if !status {
            guard let _ = UserDefaults.standard.object(forKey: "isLocationEnabled") as? Bool else {
                return
            }
            showLocationAlert()
        }
    }
    
    // Called when the app returns to the foreground after being suspended
    @objc func handleAppDidBecomeActiveNotification(notification: Notification) {
        /// check userDefaults for the user's past permissions and show error if not allowed
        if let isEnabled = UserDefaults.standard.object(forKey: "isLocationEnabled") as? Bool {
            if !isEnabled {
                showLocationAlert()
            }
        }
    }
    
    // Helper shows location not enabled alert
    func showLocationAlert() {
        let alert = UIAlertController(title: "Location Services disabled", message: "Enable location to continue.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        self.present(alert, animated: true)
    }
    
    // Helper shows app remote not connected alert
    func showAppRemoteAlert() {
        let alert = UIAlertController(title: "Spotify could not connect", message: "Please close the Spotify App and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel, handler: { action in }))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { action in
            /// start app remote again on retry
            self.isWaitingForRemote = true
            let del = UIApplication.shared.delegate as? AppDelegate
            del?.startAppRemote()
        }))
        self.present(alert, animated: true)
    }
    
    // If the status bar should be white on black or vice versa
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Called to prepare embedded child View Controllers before mounting them to view hierarchy
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController {
            /// swap delegates with MapController
            let vc = segue.destination as? MapController
            vc?.db = Firestore.firestore()
            vc?.mapControllerDelegate = self
            self.controllerMapDelegate = vc
        }
        else if segue.destination is LoginController {
            /// assign self as delegate of LoginController
            let vc = segue.destination as? LoginController
            vc?.loginMapDelegate = self
        }
    }
    
    // Called when view is terminated
    deinit {
        /// remove background-to-foreground location permissions observer
        NotificationCenter.default.removeObserver(self)
    }

}

