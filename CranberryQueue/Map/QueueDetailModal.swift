//
//  QueueDetailModal.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/17/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

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
    
    weak var db: Firestore? = nil
    
    var distance: Double = 0 {
        didSet {
            //if distance is less than .75 miles use feet else use miles
            if(distance/1609 < 0.75){
                let distanceInFeet = (distance*3.28083985)
                let roundedFeetString = String(format: "%.2f", distanceInFeet)
                distanceLabel.text = roundedFeetString + "ft"
            }else{
                let distanceInMiles = (distance/1609)
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
        
        queueNameLabel.text = ""
        songNameLabel.text = ""
        distanceLabel.text = ""
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
            joinButton.backgroundColor = UIColor(red: 0.349, green: 0.663, blue: 0.486, alpha: 1)
            joinButton.isOpaque = false
        }
    }
    
    func fetchSongInfo() {
        self.db?.collection("playback").document(currentQueue!.queueId).getDocument(completion: { (snapshot, error) in
            if let err = error {
                print(err)
            }
            let currSong = snapshot?.data()?["name"] as? String ?? ""
            let currArtist = snapshot?.data()?["artist"] as? String ?? ""
            let songImage = snapshot?.data()?["imageURL"] as? String ?? ""
            
            if(songImage != ""){
                let url = URL(string: songImage)
                let task = URLSession.shared.dataTask(with: url!) {(dataBack, response, error) in
                    guard let data2 = dataBack else {
                        print("no data")
                        return }
                    DispatchQueue.main.async {
                        self.albumImageView.image = UIImage(data: data2)
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
        })
    }
        
}
