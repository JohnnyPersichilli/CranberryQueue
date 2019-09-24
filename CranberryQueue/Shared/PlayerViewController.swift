//
//  PlayerViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

class PlayerViewController: UIViewController, SPTAppRemotePlayerStateDelegate, mainDelegate {
    
    func updateConnectionStatus(connected: Bool) {
        if connected && isHost {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            token = delegate.token
            remote = delegate.appRemote
            setupHostListeners()
        }
    }
    
    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var timeLabel: UILabel!
    
    var queueId: String? = nil
    
    var isHost = false
    
    var remote: SPTAppRemote? = nil
    
    var db: Firestore? = nil
    
    var timer = Timer()
    var isTimerRunning = false
    
    var duration = 200
    var position = 0
    
    var token: String? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.delegate = self
        
        db = Firestore.firestore()
        
        if !isHost && queueId != nil { // observing
            setupGuestListeners()
        }
        else { // not in queue
            showHelpText()
        }
        
        setupGestureRecognizers()
        
    }
    
    func setupGestureRecognizers() {
        let forwardSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        forwardSwipe.direction = .left
        self.view.addGestureRecognizer(forwardSwipe)
    }
    
    @objc func swiped() {
        if queueId != nil && isHost {
            db?.collection("playlist").document(queueId!).collection("songs").order(by: "votes", descending: true).limit(to: 1).getDocuments(completion: { (snapshot, error) in
                guard let snap = snapshot else {
                    print(error!)
                    return
                }
                if snap.count == 0 {
                    self.remote?.playerAPI?.skip(toNext: { (_, error) in
                        if let err = error {
                            print(err)
                            return
                        }
                    })
                    return
                }
                let nextSongJSON = snap.documents[0].data()
                
                self.remote?.playerAPI?.enqueueTrackUri((nextSongJSON["uri"] as! String), callback: { (response, error) in
                    guard let res = response else {
                        print(error!)
                        return
                    }
                    self.db?.collection("playlist").document(self.queueId!).collection("songs").document(snap.documents[0].documentID).delete()
                    self.remote?.playerAPI?.skip(toNext: { (_, error) in
                        if let err = error {
                            print(err)
                            return
                        }
                    })
                })
            })
            
            
        }
    }
    
    func runTimer() {
        timer.invalidate()
        isTimerRunning = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer () {
        if !isTimerRunning {
            return
        }
        position += 1000
        updateTimerUI()
        if Int(position/1000) == Int(duration/1000) {
            isTimerRunning = false
        }
        if Int(duration/1000) - Int(position/1000) == 4 {
            db?.collection("playlist").document(queueId!).collection("songs").order(by: "votes", descending: true).limit(to: 1).getDocuments(completion: { (snapshot, error) in
                guard let snap = snapshot else {
                    print(error!)
                    return
                }
                if snap.count == 0 {
                    return
                }
                let nextSongJSON = snap.documents[0].data()
                
                self.remote?.playerAPI?.enqueueTrackUri((nextSongJSON["uri"] as! String), callback: { (response, error) in
                    guard let res = response else {
                        print(error!)
                        return
                    }
                    self.db?.collection("playlist").document(self.queueId!).collection("songs").document(snap.documents[0].documentID).delete()
                        self.db?.collection("song").document(nextSongJSON["docID"] as! String).delete()
                })
            })
        }
    }
    
    func updateTimerUI() {
        let posSeconds = (position/1000) % 60
        let posMinutes = (position/1000)/60 % 60
        let durSeconds = (duration/1000) % 60
        let durMinutes = (duration/1000)/60 % 60
        var stringPosSeconds = String((position/1000) % 60)
        var stringDurSeconds = String((duration/1000) % 60)
        if posSeconds < 10 {
            stringPosSeconds = "0" + String((position/1000) % 60)
        }
        if durSeconds < 10 {
            stringDurSeconds = "0" + String((duration/1000) % 60)
        }
        DispatchQueue.main.async {
            self.timeLabel.text = "\(posMinutes):\(stringPosSeconds) | \(durMinutes):\(stringDurSeconds)"
        }
    }
    
    func updateSongUI(withState state: SPTAppRemotePlayerState) {
        var url = URL(string: "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-frc3/t1.0-1/1970403_10152215092574354_1798272330_n.jpg")
        if(state.track.imageIdentifier.split(separator: ":").count >= 2){
            let trackId = state.track.imageIdentifier.split(separator: ":")[2]
            url = URL(string: "https://i.scdn.co/image/\(trackId)")
        }else{
            //may need to update default image even though its never being used?
            print("no track image for:", state.track.name)
        }
        
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return }
            DispatchQueue.main.async() {
                self.titleLabel.text = state.track.artist.name + " - " + state.track.name
                self.albumImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    func updateSongUI(withInfo info: PlaybackInfo) {
        let url = URL(string: info.imageURL)
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return }
            DispatchQueue.main.async() {
                self.titleLabel.text = info.artist + " - " + info.name
                self.albumImageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        
        updateSongUI(withState: playerState)
        
        let json = playbackStateToJson(playerState)
        db?.collection("playback").document(queueId!).setData(json)
        
        duration = json["duration"] as! Int
        position = json["position"] as! Int
        if (json["isPaused"] as! Bool) {
            timer.invalidate()
            updateTimerUI()
        }
        else {
            runTimer()
        }
        
    }
    
    func setupHostListeners() {
        print(remote?.playerAPI)
        remote?.playerAPI?.delegate = self
        remote?.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let res = result {
                print(res)
            }
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
    }
    
    func setupGuestListeners() {
        db?.collection("playback").document(queueId!).addSnapshotListener({ (snapshot, error) in
            if let err = error {
                print(err)
                return
            }
            guard let contents = snapshot?.data() else {
                return
            }
            let info = self.playbackJsonToInfo(json: contents)
            
            self.updateSongUI(withInfo: info)
            self.duration = info.duration
            self.position = info.position
            
            if (info.isPaused) {
                self.timer.invalidate()
                self.updateTimerUI()
            }
            else {
                self.runTimer()
            }
        })
    }
    
    func showHelpText() {
        
    }
    
    func playbackStateToJson(_ playerState: SPTAppRemotePlayerState) -> [String:Any] {
        var playback = [String:Any]()
        playback["name"] = playerState.track.name
        playback["artist"] = playerState.track.artist.name
        
        if(playerState.track.imageIdentifier.split(separator: ":").count >= 2){
            playback["imageURL"] = "https://i.scdn.co/image/\(playerState.track.imageIdentifier.split(separator: ":")[2])"
        }else{
            //may need to update default image even though its never being used?
            print("no track image in JSON file for:", playerState.track.name)
            playback["imageURL"] = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-frc3/t1.0-1/1970403_10152215092574354_1798272330_n.jpg"
        }
        
        playback["isPaused"] = playerState.isPaused
        playback["position"] = playerState.playbackPosition
        playback["duration"] = Int(playerState.track.duration)
        return playback
    }
    
    func playbackJsonToInfo(json: [String:Any]) -> PlaybackInfo {
        var playback = PlaybackInfo()
        playback.name = json["name"] as! String
        playback.artist = json["artist"] as! String
        playback.imageURL = json["imageURL"] as! String
        playback.isPaused = json["isPaused"] as! Bool
        playback.position = json["position"] as! Int
        playback.duration = json["duration"] as! Int
        return playback
    }

}
