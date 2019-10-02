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
}

class PlayerView: UIView, PlayerDelegate {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet var albumImageView: UIRoundedImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var helpLabel: UILabel!
    
    
    var delegate: PlayerControllerDelegate?
    
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
        
        setupGestureRecognizers()
    }
    
    func setupGestureRecognizers() {
        let forwardSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        forwardSwipe.direction = .left
        contentView.addGestureRecognizer(forwardSwipe)
    }
    
    @objc func swiped() {
        delegate?.swiped()
    }
    
    func updateSongUI(withState state: SPTAppRemotePlayerState) {
        helpLabel.isHidden = true
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
        helpLabel.isHidden = true
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
    
    func updateTimerUI(position: Int, duration: Int) {
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
    
    func clear() {
        albumImageView.image = nil
        titleLabel.text = nil
        timeLabel.text = nil
        helpLabel.isHidden = false
    }

}
