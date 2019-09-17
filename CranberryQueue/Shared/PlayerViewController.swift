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
        
        
    }
    
    func updateSongUI(withState state: SPTAppRemotePlayerState) {
        let trackId = state.track.imageIdentifier.split(separator: ":")[2]
        let url = URL(string: "https://i.scdn.co/image/\(trackId)")
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
            
        })
    }
    
    func showHelpText() {
        
    }
    
    func playbackStateToJson(_ playerState: SPTAppRemotePlayerState) -> [String:Any] {
        var playback = [String:Any]()
        playback["name"] = playerState.track.name
        playback["artist"] = playerState.track.artist.name
        playback["imageURL"] = "https://i.scdn.co/image/\(playerState.track.imageIdentifier.split(separator: ":")[2])"
        playback["isPaused"] = playerState.isPaused
        playback["completion"] = playerState.playbackPosition
        playback["duration"] = Int(playerState.track.duration)
        return playback
    }
    
    func playbackJsonToInfo(json: [String:Any]) -> PlaybackInfo {
        var playback = PlaybackInfo()
        playback.name = json["name"] as! String
        playback.artist = json["artist"] as! String
        playback.imageURL = json["imageURL"] as! String
        playback.isPaused = json["isPaused"] as! Bool
        playback.completion = json["completion"] as! Int
        playback.duration = json["duration"] as! Int
        return playback
    }

}
