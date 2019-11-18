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
    func updatePlayPauseUI(isPaused: Bool, isHost: Bool)
    func clear()
}

class PlayerController: NSObject, SPTAppRemotePlayerStateDelegate, RemoteDelegate, PlayerControllerDelegate {

    func updateConnectionStatus(connected: Bool) {
        if connected && isHost {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            token = delegate.token
            remote = delegate.appRemote
            setupHostListeners()
        }
    }
    
    func swiped() {
        if queueId != nil && isHost {
            skipSong()
        }
    }
    
    func stripIdFromCurrentUri() -> String? {
        let index = self.currentUri.index(self.currentUri.startIndex, offsetBy: 13)
        let range = self.currentUri.index(after: index)..<self.currentUri.endIndex
        return String(self.currentUri[range])
    }
    
    func playPause(isPaused: Bool){
        if(queueId != nil && isHost){
            if(isPaused){
                self.remote?.playerAPI?.resume({ (response, error) in
                    if let err = error {
                        print(err)
                        return
                    }
                })
            }else{
                self.remote?.playerAPI?.pause({ (response, error) in
                    if let err = error {
                        print(err)
                        return
                    }
                })
            }
        }else{
            
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
    var hostListener: ListenerRegistration? = nil
    
    static let sharedInstance = PlayerController()
    
    func likeTapped() {
        let id = stripIdFromCurrentUri()!
        let url = URL(string: "https://api.spotify.com/v1/me/tracks?ids=\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(self.token!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                print(err)
            }
        }
        task.resume()
    }
    
    func unlikeTapped() {
        let id = stripIdFromCurrentUri()!
        let url = URL(string: "https://api.spotify.com/v1/me/tracks?ids=\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(self.token!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                print(err)
            }
        }
        task.resume()
    }

    func setupPlayer(queueId: String?, isHost: Bool) {
        let oldQueueId = self.queueId
        
        self.queueId = queueId
        self.isHost = isHost
        db = Firestore.firestore()
        
        if oldQueueId == nil && queueId != nil { /// no current queue, joining new queue
            if isHost {
                updateConnectionStatus(connected: true)
            }
            else {
                setupGuestListeners()
            }
        }
        else if oldQueueId != nil && queueId == nil { /// leaving a queue to nothing
            remote?.playerAPI?.unsubscribe(toPlayerState: { (val, error) in
            })
            timer.invalidate()
            position = 0
            mapDelegate?.clear()
            queueDelegate?.clear()
            hostListener?.remove()
            guestListener?.remove()
        }
        else if oldQueueId != queueId { /// leaving current queue, joining new one
            if isHost {
                updateConnectionStatus(connected: true)
            }
            else {
                setupGuestListeners()
            }
        }
        else { /// rejoining same queue
            if isHost {
                remote?.playerAPI?.getPlayerState({ (state, error) in
                    guard let info = state as? SPTAppRemotePlayerState else { return }
                    self.playerStateDidChange(info)
                })
            }
            else {
                setupGuestListeners()
            }
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
        if(queueId != nil && isHost){
            self.remote?.playerAPI?.skip(toNext: { (_, error) in
                if let err = error {
                    print(err)
                    return
                }
            })
        }
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
        if queueId == nil {
            remote?.playerAPI?.unsubscribe(toPlayerState: { (value, error) in
                
            })
            return
        }
        
        mapDelegate?.updateSongUI(withState: playerState)
        queueDelegate?.updateSongUI(withState: playerState)
        
        
        let json = playbackStateToJson(playerState)
        db?.collection("playback").document(queueId!).setData(json)
        
        duration = json["duration"] as! Int
        position = json["position"] as! Int
        let isPaused = json["isPaused"] as! Bool
        
        self.mapDelegate?.updatePlayPauseUI(isPaused: isPaused, isHost: isHost)
        self.queueDelegate?.updatePlayPauseUI(isPaused: isPaused, isHost: isHost)
        
        if (isPaused) {
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
            // will prepopulate the like icon to be already liked or not
            self.populateLikeIcon()
            removeSongWith(uri, completion: {
                self.enqueueNextSong()
            })
        }
    }
    
    func populateLikeIcon() {
        if let id = stripIdFromCurrentUri() {
            let url = URL(string: "https://api.spotify.com/v1/me/tracks/contains?ids=\(id)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(self.token!)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
               if let httpResponse = response as? HTTPURLResponse {
                   print("STATUS")
                   print(httpResponse.statusCode)
               }
                guard let data = data else {
                     return
                }

                do {
                    let jsonRes = try JSONSerialization.jsonObject(with: data, options: []) as! NSArray
                    let value = jsonRes.firstObject as! Int
                    if value == 1 {
                        print("contains like")
                    } else {
                        print("does not contain like")
                    }
                }
                catch {
                    print("error")
                }

               if let err = error {
                   print(err)
               }
            }
            task.resume()
        }
    }
    
    func enqueueNextSong() {
        songTableWith(queueId!)?.order(by: "votes", descending: true).limit(to: 1).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            
            if snap.isEmpty {
                return
            }
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
                doc.reference.delete { (val) in
                    completion()
                }
            }
            else {
                docs.sort(by: {$0.data()["votes"] as! Int > $1.data()["votes"] as! Int})
                docs[0].reference.delete { (val) in
                    completion()
                }
            }
            
        })
    }
    
    func songTableWith(_ queueId: String) -> CollectionReference? {
        return db?.collection("playlist").document(queueId).collection("songs")
    }
    
    func setupHostListeners() {
        var lastCount = 0
        hostListener?.remove()
        hostListener = db?.collection("playlist").document(self.queueId!).collection("songs").limit(to: 1).addSnapshotListener({ (snapshot, error) in
            guard let docs = snapshot?.documents else { return }
            if docs.count == 1 && lastCount == 0 {
                self.enqueueNextSong()
            }
            lastCount = docs.count
        })
        remote?.playerAPI?.delegate = self
        remote?.playerAPI?.unsubscribe(toPlayerState: { (val, error) in
            self.remote?.playerAPI?.subscribe(toPlayerState: { (result, error) in
                if let res = result {
                    print(res)
                }
                if let error = error {
                    debugPrint(error.localizedDescription)
                }
            })
        })
        
    }
    
    func setupGuestListeners() {
        guestListener?.remove()
        guestListener = db?.collection("playback").document(queueId!).addSnapshotListener({ (snapshot, error) in
            if let err = error {
                print(err)
                return
            }
            guard let contents = snapshot?.data() else {
                self.mapDelegate?.clear()
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
    
    func getURLFrom(_ playerState: SPTAppRemotePlayerState ) -> String {
        var imageURL = ""
        
        if(playerState.track.imageIdentifier.split(separator: ":").count >= 2){
            imageURL = "https://i.scdn.co/image/\(playerState.track.imageIdentifier.split(separator: ":")[2])"
        }
        else{
            print("no track image in JSON file for:", playerState.track.name)
            imageURL = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-frc3/t1.0-1/1970403_10152215092574354_1798272330_n.jpg"
        }
        
        return imageURL
    }
    
    func playbackStateToJson(_ playerState: SPTAppRemotePlayerState) -> [String:Any] {
        var playback = [String:Any]()
        playback["name"] = playerState.track.name
        playback["artist"] = playerState.track.artist.name
        playback["imageURL"] = getURLFrom(playerState)
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
