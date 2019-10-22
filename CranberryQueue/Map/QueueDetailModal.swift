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
        
    var distance: Double = 0 {
        didSet {
            let metersInMile = 1609.34
            let feetInMeter = 3.28083985
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
        let joinGreen = UIColor(red: 0.349, green: 0.663, blue: 0.486, alpha: 1)
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
                let songString = currSong + " - " + currArtist
                self.updatePlaybackUI(queueName: self.currentQueue!.name, numMembers: self.currentQueue!.numMembers, songString: songString, albumImage: UIImage(data: imageData)!)
            }
            task.resume()
        }else{
            updatePlaybackUI(queueName: self.currentQueue!.name, numMembers: self.currentQueue!.numMembers, songString: "No song currently playing", albumImage: UIImage(named: "defaultPerson")!)
        }
    }
    
    func updatePlaybackUI(queueName: String, numMembers:Int, songString: String, albumImage: UIImage){
        DispatchQueue.main.async {
            self.albumImageView.image = albumImage
            self.queueNameLabel.text = queueName
            self.songNameLabel.text = songString
            self.numMembersLabel.text = String(numMembers)
        }
    }
}
