//
//  QueueViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol queueDelegate: class {
    func searchTapped(shouldHideContents: Bool)
}

class QueueViewController: UIViewController, searchDelegate, SongTableDelegate {

    var queueName: String? = nil
    var queueId: String? = nil
    var uid: String? = nil
    var isHost = false
    var shouldHideContents = false
    
    @IBOutlet weak var leaveQueueImage: UIImageView!
    
    @IBOutlet var songTableView: SongTableView!
    
    @IBOutlet var searchIconImageView: UIImageView!
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var numMembersLabel: UILabel!
    
    @IBOutlet var numSongsLabel: UILabel!
    
    @IBOutlet var nextUpLabel: UILabel!
    
    @IBOutlet var searchView: UIView!
    
    @IBOutlet var globeIcon: UIImageView!
    
    weak var delegate: queueDelegate? = nil
    
    var db : Firestore? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        setupScreen()
        songTableView.delegate = songTableView
        songTableView.dataSource = songTableView
        
        nameLabel.text = queueName
        
        searchView.isHidden = true
        searchView.alpha = 0
        
        songTableView.queueId = queueId
        songTableView.uid = self.uid
        songTableView.isHost = isHost
        songTableView.loadPreviousVotes()
        songTableView.watchPlaylist()
        songTableView.songDelegate = self
        
        
        setupGestureRecognizers()
        
        watchLocationDoc()

        
        if (UIApplication.shared.delegate as! AppDelegate).token == "" {
            searchIconImageView.isUserInteractionEnabled = false
        }
    }
    
    func updateNumSongs(_ numSongs: Int) {
        DispatchQueue.main.async {
            self.numSongsLabel.text = String(numSongs)
        }
    }
    
    func watchLocationDoc() {
        db = Firestore.firestore()
        
        db?.collection("location").document(queueId!)
            .addSnapshotListener({ (snapshot, error) in
                
                guard let snap = snapshot else {
                    print(error!)
                    return
                }
                
                let doc = snap.data()!
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
        leaveQueueImage.addGestureRecognizer(leaveQueueTap)
        leaveQueueImage.isUserInteractionEnabled = true
    }
    
    @objc func leaveQueueTapped() {
        self.db?.collection("contributor").document(self.queueId!).collection("members").document(self.uid!).delete()
        
        self.queueId = nil
        
        self.presentingViewController?.dismiss(animated: true, completion: {
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    @objc func globeTapped() {
        self.presentingViewController?.dismiss(animated: true, completion: {
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func setupScreen() {
        let colors = Colors()
        let backgroundLayer = colors.gl1
        backgroundLayer?.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
    }
    
    @objc func searchTapped() {
        if(searchView.isHidden) {
            delegate?.searchTapped(shouldHideContents: false)
            searchView.isHidden = false
            let closeSearchImage: UIImage = UIImage(named: "xIcon")!
            searchIconImageView.image = closeSearchImage
            UIView.animate(withDuration: 0.4, animations: {
                self.nextUpLabel.alpha = 0
                self.songTableView.alpha = 0
                self.searchView.alpha = 1
            }) { (val) in
                self.nextUpLabel.isHidden = true
                self.songTableView.isHidden = true
            }
        } else {
            delegate?.searchTapped(shouldHideContents: true)
            self.nextUpLabel.isHidden = false
            self.songTableView.isHidden = false
            let searchImage: UIImage = UIImage(named: "searchIcon")!
            searchIconImageView.image = searchImage
            UIView.animate(withDuration: 0.4, animations: {
                self.nextUpLabel.alpha = 1
                self.songTableView.alpha = 1
                self.searchView.alpha = 0
            }) { (_) in
                self.searchView.isHidden = true
            }
        }
    }
    
    func addSongTapped(song: Song) {
        songTableView.voteTapped(isUpvote: true, song: song)
        
        self.nextUpLabel.isHidden = false
        self.songTableView.isHidden = false
        let searchImage: UIImage = UIImage(named: "searchIcon")!
        searchIconImageView.image = searchImage
        UIView.animate(withDuration: 0.4, animations: {
            self.nextUpLabel.alpha = 1
            self.songTableView.alpha = 1
            self.searchView.alpha = 0
        }) { (_) in
            self.searchView.isHidden = true
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PlayerViewController
        {
            let vc = segue.destination as? PlayerViewController
            vc?.queueId = queueId
            vc?.isHost = isHost
            vc?.updateConnectionStatus(connected: true)
        }
        else if segue.destination is SearchController {
            let vc = segue.destination as? SearchController
  
            vc?.delegate = self
            vc?.queueId = queueId
            vc?.uid = uid
            self.delegate = vc
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
