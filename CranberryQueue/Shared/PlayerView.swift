//
//  PlayerView.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/2/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

protocol PlayerControllerDelegate: class {
    func swiped()
    func playPause(isPaused: Bool)
    func toggleLikeRequest()
}

class PlayerView: UIView, PlayerDelegate {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var albumImageView: UIRoundedImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet weak var likeIconImageView: UIImageView!
    
    @IBOutlet var helpLabel: UILabel!
    @IBOutlet weak var inactiveHostLabel: UILabel!
    @IBOutlet weak var playPauseImage: UIImageView!
    @IBOutlet weak var skipSongImage: UIImageView!
    @IBOutlet weak var bottomGuestTimeLabelConstraint: NSLayoutConstraint!
    
    var delegate: PlayerControllerDelegate?
    var isPaused = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("PlayerView", owner: self, options: nil)
        contentView.fixInView(self)
        
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        titleLabel.text = nil
        timeLabel.text = nil
        playPauseImage.image = nil
        skipSongImage.image = nil
        
        inactiveHostLabel.isHidden = true
        self.likeIconImageView.isHidden = true

        setupGestureRecognizers()
    }
    
    func setupGestureRecognizers() {
        let skipSongTap = UITapGestureRecognizer(target: self, action: #selector(skipSongTapped))
        skipSongImage.addGestureRecognizer(skipSongTap)
        skipSongImage.isUserInteractionEnabled = true
        
        let playPauseTap = UITapGestureRecognizer(target: self, action: #selector(playPauseTapped))
        playPauseImage.addGestureRecognizer(playPauseTap)
        playPauseImage.isUserInteractionEnabled = true
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.likeIconTapped))
        self.likeIconImageView.addGestureRecognizer(likeTapGesture)
        self.likeIconImageView.isUserInteractionEnabled = true
    }
    
    @objc func playPauseTapped(){
        delegate?.playPause(isPaused: isPaused)
    }
    
    @objc func skipSongTapped() {
        delegate?.swiped()
    }
    
     @objc func likeIconTapped() {
        delegate?.toggleLikeRequest()
     }
    
    //Same function as player controller
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
    
    func updatePlayPauseUI(isPaused: Bool, isHost: Bool) {
        if(isHost){
            bottomGuestTimeLabelConstraint.constant = 7.5
            self.isPaused = isPaused
            skipSongImage.image = UIImage(named: "ios-skip-forward-white")
            if(isPaused){
                if #available(iOS 13.0, *) {
                    playPauseImage.image = UIImage(systemName: "play.fill")
                }else{
                    playPauseImage.image = UIImage(named: "whitePlayIcon")
                }
            }else{
                if #available(iOS 13.0, *) {
                    playPauseImage.image = UIImage(systemName: "pause.fill")
                }else{
                    playPauseImage.image = UIImage(named: "ios-pause-white")
                }
            }
            playPauseImage.isUserInteractionEnabled = true
            skipSongImage.isUserInteractionEnabled = true
        }else{
            bottomGuestTimeLabelConstraint.constant = 25
            playPauseImage.image = nil
            skipSongImage.image = nil
            playPauseImage.isUserInteractionEnabled = false
            skipSongImage.isUserInteractionEnabled = false
        }
    }
    
    func updateLikeUI(liked: Bool) {
        DispatchQueue.main.async {
            // if the incoming song is already in your library
            if liked {
                if #available(iOS 13.0, *) {
                    self.likeIconImageView.image = UIImage(systemName: "heart.fill")!
                    self.likeIconImageView.tintColor = UIColor.red
                    self.likeIconImageView.isHidden = false
                } else {
                  // Fallback on earlier versions
                }
                
            } else {
                if #available(iOS 13.0, *) {
                    self.likeIconImageView.image = UIImage(systemName: "heart")!
                    self.likeIconImageView.tintColor = UIColor.white
                    self.likeIconImageView.isHidden = false
                } else {
                  // Fallback on earlier versions
                }
                
            }
        }
    }
    
    func updateSongUI(withState state: SPTAppRemotePlayerState) {
        let position = state.playbackPosition
        if position <= state.track.duration {
            inactiveHostLabel.isHidden = true
            
            let url = URL( string: getURLFrom(state) )
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data, error == nil else {
                    print(error!)
                    return }
                DispatchQueue.main.async() {
                    self.titleLabel.text = state.track.name + " - " + state.track.artist.name
                    self.albumImageView.image = UIImage(data: data)
                }
            }
            task.resume()
        }
        
        helpLabel.isHidden = true
        updateTimerUI(position: position, duration: Int(state.track.duration))
    }
    
    func updateSongUI(withInfo info: PlaybackInfo, position: Int) {
        if position <= info.duration {
            inactiveHostLabel.isHidden = true
            
            let url = URL(string: info.imageURL)
            let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data, error == nil else {
                    print(error!)
                    return }
                DispatchQueue.main.async() {
                    self.titleLabel.text = info.name + " - " + info.artist
                    self.albumImageView.image = UIImage(data: data)
                }
            }
            task.resume()
        }
        
        helpLabel.isHidden = true
        updateTimerUI(position: position, duration: info.duration)
    }
    
    func updateTimerUI(position: Int, duration: Int) {
        let posSeconds = (position/1000) % 60
        let posMinutes = (position/1000)/60 % 60
        let durSeconds = (duration/1000) % 60
        let durMinutes = (duration/1000)/60 % 60
        if(position > duration){
            DispatchQueue.main.async {
                self.showInactiveLabel()
                if( position - duration > (60*60*1000)){
                    self.inactiveHostLabel.text = "Host has been inactive for over an hour"
                }
                else if(posMinutes == durMinutes){
                    self.inactiveHostLabel.text = "Host has been inactive for less than 1 minute"
                }else{
                    self.inactiveHostLabel.text = "Host has been inactive for " + String(posMinutes-durMinutes) + " min"
                }
            }
            return
        }
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
    
    func showHelpLabel() {
        clearPlayerUI()
        helpLabel.isHidden = false
        inactiveHostLabel.isHidden = true
    }
    
    func showInactiveLabel() {
        clearPlayerUI()
        helpLabel.isHidden = true
        inactiveHostLabel.isHidden = false
    }
    
    func clearPlayerUI() {
        playPauseImage.image = nil
        skipSongImage.image = nil
        albumImageView.image = nil
        titleLabel.text = nil
        timeLabel.text = nil
        likeIconImageView.isHidden = true
    }
    
}
