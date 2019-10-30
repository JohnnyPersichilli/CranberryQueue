//
//  QueueViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol QueueMapDelegate: class {
    func update(queueId: String?, isHost: Bool, privateCode: String?, name: String?)
}

protocol QueueSegmentedDelegate: class {
    func searchTapped(shouldHideContents: Bool)
}

class QueueViewController: UIViewController, SegmentedJointDelegate, SongTableDelegate {

    var queueName: String? = nil
    var queueId: String? = nil
    var uid: String? = nil
    var isHost = false
    var shouldHideContents = false
    var isPrivate = false
    
    @IBOutlet weak var leaveQueueButton: UIButton!
    @IBOutlet var songTableView: SongTableView!
    @IBOutlet var searchIconImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var numMembersLabel: UILabel!
    @IBOutlet var numSongsLabel: UILabel!
    @IBOutlet var nextUpLabel: UILabel!
    @IBOutlet var globeIcon: UIImageView!
    @IBOutlet var playerView: PlayerView!
    
    @IBOutlet var segmentedContainerView: UIView!
    
    weak var mapDelegate: QueueMapDelegate? = nil
    weak var queueSegmentedDelegate: QueueSegmentedDelegate? = nil
    
    var queueRef: ListenerRegistration? = nil
    
    var db : Firestore? = nil
    
    var playerController = PlayerController.sharedInstance
    
    override func viewDidLoad() {
        db = Firestore.firestore()
        
        playerView.delegate = playerController
        playerController.queueDelegate = playerView
        playerController.setupPlayer(queueId: queueId!, isHost: isHost)
        
        setupGestureRecognizers()
        setupScreen()
        
        songTableView.delegate = songTableView
        songTableView.dataSource = songTableView
        
        songTableView.songDelegate = self
    }
            
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if(isHost){
            leaveQueueButton.setTitle("Delete Queue", for: .normal)
        }
        
        if (UIApplication.shared.delegate as! AppDelegate).token == "" {
            searchIconImageView.isUserInteractionEnabled = false
        }
        
        watchLocationDoc()
        setupSongTableView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        queueRef?.remove()
        songTableView.songRef?.remove()
    }
    
    func navigateToRoot() {
        self.presentingViewController?.dismiss(animated: true, completion: {
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func updateNumSongs(_ numSongs: Int) {
        DispatchQueue.main.async {
            self.numSongsLabel.text = String(numSongs)
        }
    }
    
    // setup related to the song table view
    func setupSongTableView() {
        songTableView.queueId = queueId
        songTableView.uid = self.uid
        songTableView.isHost = isHost
        songTableView.loadPreviousVotes()
        songTableView.watchPlaylist()
    }
    
    func watchLocationDoc() {
        db = Firestore.firestore()
        queueRef = db?.collection("location").document(queueId!)
            .addSnapshotListener({ (snapshot, error) in
                guard let snap = snapshot else {
                    print(error!)
                    return
                }
                guard let doc = snap.data() else {
                    self.cleanup()
                    return
                }
                let numMembers = doc["numMembers"] as! Int
                DispatchQueue.main.async {
                    self.numMembersLabel.text = String(numMembers)
                }
            })
    }
    
    func setupGestureRecognizers() {
        let globeTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.globeTapped))
        globeIcon.addGestureRecognizer(globeTapGesture)
        globeIcon.isUserInteractionEnabled = true
        
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(self.searchTapped))
        searchIconImageView.addGestureRecognizer(searchTap)
        searchIconImageView.isUserInteractionEnabled = true
        
        let leaveQueueTap = UITapGestureRecognizer(target: self, action: #selector(self.leaveQueueTapped))
        leaveQueueButton.addGestureRecognizer(leaveQueueTap)
        leaveQueueButton.isUserInteractionEnabled = true
    }
    
    func cleanup() {
        let alert = UIAlertController(title: "Queue no longer exists", message: "The host deleted the queue or there was a problem retrieving queue information.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Return to map", style: UIAlertAction.Style.default, handler: self.returnToMapFromAlert))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func returnToMapFromAlert(alert: UIAlertAction!) {
        playerController.setupPlayer(queueId: nil, isHost: false)
        self.navigateToRoot()
        self.queueName = nil
        self.queueId = nil
        self.queueRef?.remove()
        self.mapDelegate?.update(queueId: nil, isHost: false, privateCode: nil, name: nil)
    }
    
    @objc func leaveQueueTapped() {
        //if your the host, then delete the queue when leaving
        if(isHost){
            //firebase fn handles all garbage cleanup for this
            self.db?.collection("location").document(self.queueId!).delete()
        } else {
            //delete from members now an endpoint
            removeFromMembersRequest(queueId: self.queueId!, uid: self.uid!)
        }
        
        self.queueId = nil
        mapDelegate?.update(queueId: nil, isHost: false, privateCode: nil, name: nil)
        playerController.setupPlayer(queueId: nil, isHost: false)
        
        self.navigateToRoot()
    }
    
    @objc func globeTapped() {
        mapDelegate?.update(queueId: queueId, isHost: isHost, privateCode: isPrivate ? self.nameLabel.text : nil, name: !isPrivate ? self.nameLabel.text : nil)
        self.navigateToRoot()
    }
    
    func setupScreen() {
        leaveQueueButton.alpha = 0.8
        segmentedContainerView.isHidden = true
        segmentedContainerView.alpha = 0
        nameLabel.text = queueName
        let backgroundLayer = Colors.queueGradient
        backgroundLayer.frame = view.frame
        view.layer.insertSublayer(backgroundLayer, at: 0)
    }
    
    func dismissSegmentedContainerViewAnimation() {
        self.nextUpLabel.isHidden = false
        self.songTableView.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {
            self.nextUpLabel.alpha = 1
            self.songTableView.alpha = 1
            self.segmentedContainerView.alpha = 0
        }) { (_) in
            self.segmentedContainerView.isHidden = true
        }
    }
    
    func presentSegmentedContainerViewAnimation() {
        self.segmentedContainerView.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {
            self.nextUpLabel.alpha = 0
            self.songTableView.alpha = 0
            self.segmentedContainerView.alpha = 1
        }) { (val) in
            self.nextUpLabel.isHidden = true
            self.songTableView.isHidden = true
        }
    }
    
    @objc func searchTapped() {
        queueSegmentedDelegate?.searchTapped(shouldHideContents: segmentedContainerView.isHidden)
        if(segmentedContainerView.isHidden) {
            searchIconImageView.image = UIImage(named: "xIcon")!
            presentSegmentedContainerViewAnimation()
        } else {
            if #available(iOS 13.0, *) {
                searchIconImageView.image = UIImage(systemName: "plus")!
            }
            dismissSegmentedContainerViewAnimation()
        }
    }
    
    func addSongTapped(song: Song) {
        songTableView.voteTapped(isUpvote: true, song: song)
                
        self.nextUpLabel.isHidden = false
        self.songTableView.isHidden = false
        if #available(iOS 13.0, *) {
            searchIconImageView.image = UIImage(systemName: "plus")!
        }
        dismissSegmentedContainerViewAnimation()
    }
    
    //removes the user from the queue
    func removeFromMembersRequest(queueId: String, uid: String) {
        let url = URL(string: "https://us-central1-cranberryqueue.cloudfunctions.net/removeFromMembers")!
         var request = URLRequest(url: url)
        let dictionary = ["queueId": queueId,"uid": uid]
        request.httpBody = try! JSONEncoder().encode(dictionary)
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let res = response {
                print(res)
            }
            if let err = error {
                print(err)
                return
            }
        }
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SegmentedViewController {
            let vc = segue.destination as? SegmentedViewController
            vc?.jointDelegate = self
            queueSegmentedDelegate = vc
            vc?.queueId = queueId
            vc?.uid = uid
        }
    }
    

}
