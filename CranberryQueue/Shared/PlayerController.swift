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
    
    func swiped() {
        print(eventCodeFromTimestamp())
        if queueId != nil && isHost {
            skipSong()
        }
    }
        
    var queueId: String? = nil
    var isHost = false
    
    var remote: SPTAppRemote? = nil
    var token: String? = nil
    
    var db: Firestore? = nil
    
    var timer = Timer()
    var isTimerRunning = false
    
    var currentUri = String()
    var duration = 200
    var position = 0
    
    var isEnqueuing = false
    
    var mapDelegate: PlayerDelegate?
    var queueDelegate: PlayerDelegate?
    
    var guestListener: ListenerRegistration? = nil
    
    static let sharedInstance = PlayerController()

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
        else if queueId != nil {
            setupGuestListeners()
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
        if Int(position/1000) >= Int(duration/1000) {
            isTimerRunning = false
        }
    }
    
    func skipSong() {
        self.remote?.playerAPI?.skip(toNext: { (_, error) in
            if let err = error {
                print(err)
                return
            }
        })
    }
    
    func enqueueSongWith(_ uri: String) {
        isEnqueuing = true
        self.remote?.playerAPI?.enqueueTrackUri(uri, callback: { (response, error) in
            if let err = error {
                print(err)
                return
            }
        })
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if isEnqueuing {
            isEnqueuing = false
            return
        }
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
        
        let uri = playerState.track.uri
        if currentUri != uri {
            currentUri = uri
            removeSongWith(uri, completion: {
                self.enqueueNextSong()
            })
        }
    }
    
    func enqueueNextSong() {
        songTableWith(queueId!)?.order(by: "votes", descending: true).limit(to: 1).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            if snap.documents.count == 0 { return }
            let doc = snap.documents[0]
            var data = doc.data()
            let ref = doc.reference
            data["next"] = true
            ref.setData(data, merge: true)
            
            self.enqueueSongWith(data["uri"] as! String)
        })
    }
    
    func removeSongWith(_ uri: String, completion: @escaping ()-> Void) {
        songTableWith(queueId!)?.whereField("uri", isEqualTo: uri ).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            var docs = snap.documents
            if docs.count == 0 {
                completion()
                return
            }
            if let doc = docs.first(where: {$0.data()["next"] as! Bool == true}) {
                doc.reference.delete()
            }
            else {
                docs.sort(by: {$0.data()["votes"] as! Int > $1.data()["votes"] as! Int})
                docs[0].reference.delete()
            }
            completion()
        })
    }
    
    func songTableWith(_ queueId: String) -> CollectionReference? {
        return db?.collection("playlist").document(queueId).collection("songs")
    }
    
    func setupHostListeners() {
        print(remote!.isConnected)
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
            self.position = info.position + (Int(Date().timeIntervalSince1970) - info.timestamp)*1000
            
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
    
    func eventCodeFromTimestamp() -> String {
        let possibleChars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/")
        var rixit = 0
        var residual = Int(Double(Date().timeIntervalSince1970)*1000)
        var result = ""
        while(residual != 0) {
            rixit = residual % 64
            result = String(possibleChars[rixit]) + result;
            residual = (residual / 64);
        }
        result.removeFirst(2)
        return result;
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
        playback["timestamp"] = Int(Date().timeIntervalSince1970)
        playback["uri"] = playerState.track.uri
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
        playback.timestamp = json["timestamp"] as! Int
        playback.uri = json["uri"] as! String
        return playback
    }

}
