//
//  QueueDetailModal.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/17/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class QueueDetailModal: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet var queueNameLabel: UILabel!
    
    @IBOutlet var distanceLabel: UILabel!
    
    @IBOutlet var songNameLabel: UILabel!
    
    @IBOutlet var numMembersLabel: UILabel!
    
    @IBOutlet var albumImageView: UIRoundedImageView!
    
    @IBOutlet var joinButton: UIButton!
    
    @IBOutlet var addIconImageView: UIImageView!
    
    @IBOutlet var closeIconImageView: UIImageView!
    
    var currentQueue: CQLocation? = nil
    
    let metersInMile = 1609.34
    let feetInMeter = 3.28083985
    let joinGreen = UIColor(red: 0.349, green: 0.663, blue: 0.486, alpha: 1)
        
    var distance: Double = 0 {
        didSet {
            //if distance is less than .25 miles use feet else use miles
            if(distance/metersInMile < 0.25){
                let distanceInFeet = (distance*feetInMeter)
                let roundedFeetString = String(format: "%.2f", distanceInFeet)
                distanceLabel.text = roundedFeetString + "ft"
            }else{
                let distanceInMiles = (distance/metersInMile)
                let roundedMileString = String(format: "%.1f", distanceInMiles)
                distanceLabel.text =  roundedMileString + "mi"
            }
            setJoinEnabled()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("QueueDetailModal", owner: self, options: nil)
        contentView.fixInView(self)
    }
    
    func setJoinEnabled() {
        //can set this as the radius if we are letting users do that or an arbitrary number like 500m
        let maxDistance = 500.0
        if(distance > maxDistance){
            joinButton.isEnabled = false
            joinButton.backgroundColor = UIColor.red.withAlphaComponent(0.3)
            joinButton.isOpaque = true
        }else{
            joinButton.isEnabled = true
            joinButton.backgroundColor = joinGreen
            joinButton.isOpaque = false
        }
    }
    
    func updateWithPlaybackDoc(doc: [String:Any]) {
        let currSong = doc["name"] as? String ?? ""
        let currArtist = doc["artist"] as? String ?? ""
        let songImage = doc["imageURL"] as? String ?? ""
        
        if(songImage != ""){
            let url = URL(string: songImage)
            let task = URLSession.shared.dataTask(with: url!) {(dataBack, response, error) in
                guard let imageData = dataBack else {
                    print("no data")
                    return
                }
                DispatchQueue.main.async {
                    self.albumImageView.image = UIImage(data: imageData)
                    self.queueNameLabel.text = self.currentQueue!.name
                    self.songNameLabel.text = currSong + " - " + currArtist
                    self.numMembersLabel.text = String(self.currentQueue!.numMembers)
                }
            }
            task.resume()
        }else{
            DispatchQueue.main.async {
                self.numMembersLabel.text = String(self.currentQueue!.numMembers)
                self.queueNameLabel.text = self.currentQueue!.name
                self.albumImageView.image = UIImage(named: "defaultPerson")!
                self.songNameLabel.text = "No song currently playing"
            }
        }
    }
//    currently not implemented
//    func fetchSongInfo() {
//
//    }
}
