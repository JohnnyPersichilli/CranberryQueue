//
//  PlayerViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol PlayerDelegate: class {
    func updateSongUI(withInfo: PlaybackInfo)
    func updateSongUI(withState: SPTAppRemotePlayerState)
    func updateTimerUI(position: Int, duration: Int)
    func clear()
}

class PlayerController: NSObject, SPTAppRemotePlayerStateDelegate, mainDelegate, PlayerControllerDelegate {
    
    func updateConnectionStatus(connected: Bool) {
        if connected && isHost {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            token = delegate.token
            remote = delegate.appRemote
            setupHostListeners()
        }
    }
    
    var queueId: String? = nil
    
    var isHost = false
    
    var remote: SPTAppRemote? = nil
    
    var db: Firestore? = nil
    
    var timer = Timer()
    var isTimerRunning = false
    
    var duration = 200
    var position = 0
    
    var token: String? = nil
    
    var mapDelegate: PlayerDelegate?
    var queueDelegate: PlayerDelegate?
    
    var guestListener: ListenerRegistration? = nil
    
//    override func viewDidLoad() {
        
//
//        db = Firestore.firestore()
//
//        if !isHost && queueId != nil { // observing
//            setupGuestListeners()
//        }
//        else { // not in queue
//            showHelpText()
//        }
//    }
    
    func setupPlayer(queueId: String?, isHost: Bool) {
        if queueId != self.queueId || queueId == nil {
            guestListener?.remove()
            remote?.playerAPI?.unsubscribe(toPlayerState: { (val, error) in
                
            })
            
        }
        if queueId == nil {
            timer.invalidate()
            position = 0
            mapDelegate?.clear()
            queueDelegate?.clear()
        }
        self.queueId = queueId
        self.isHost = isHost
        db = Firestore.firestore()
        if isHost {
            //updateConnectionStatus(connected: true)
        }
        if queueId != nil {
            setupGuestListeners()
        }
    }
    
    func swiped() {
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
        mapDelegate?.updateTimerUI(position: position, duration: duration)
        queueDelegate?.updateTimerUI(position: position, duration: duration)
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
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        
        mapDelegate?.updateSongUI(withState: playerState)
        queueDelegate?.updateSongUI(withState: playerState)
        
        let json = playbackStateToJson(playerState)
        db?.collection("playback").document(queueId!).setData(json)
        
        duration = json["duration"] as! Int
        position = json["position"] as! Int
        if (json["isPaused"] as! Bool) {
            timer.invalidate()
            mapDelegate?.updateTimerUI(position: position, duration: duration)
            queueDelegate?.updateTimerUI(position: position, duration: duration)
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
        guestListener = db?.collection("playback").document(queueId!).addSnapshotListener({ (snapshot, error) in
            if let err = error {
                print(err)
                return
            }
            guard let contents = snapshot?.data() else {
                return
            }
            let info = self.playbackJsonToInfo(json: contents)
            
            self.mapDelegate?.updateSongUI(withInfo: info)
            self.queueDelegate?.updateSongUI(withInfo: info)
            self.duration = info.duration
            self.position = info.position
            
            if (info.isPaused) {
                self.timer.invalidate()
                self.mapDelegate?.updateTimerUI(position: self.position, duration: self.duration)
                self.queueDelegate?.updateTimerUI(position: self.position, duration: self.duration)
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