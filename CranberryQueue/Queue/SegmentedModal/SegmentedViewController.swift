//
//  SegmentedViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 10/27/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol SegmentedJointDelegate: class {
    func addSongTapped(song: Song)
}

protocol SegmentedChildDelegate: class {
    func clear()
}

class SegmentedViewController: UIViewController, QueueSegmentedDelegate, SegmentedJointDelegate {
    
    @IBOutlet var stackHorizontalConstraint: NSLayoutConstraint!
        
    @IBOutlet var searchContainerView: UIView!
    
    weak var jointDelegate: SegmentedJointDelegate?
    weak var childDelegate: SegmentedChildDelegate?
    
    var queueId: String?
    var uid: String?
    var db: Firestore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        guard let control = sender as? UISegmentedControl else {
            return
        }
        var newConstant: CGFloat
        switch control.selectedSegmentIndex {
        case 0:
            newConstant = 0
        case 1:
            newConstant = -self.view.frame.size.width
        default:
            newConstant = -2*self.view.frame.size.width
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.stackHorizontalConstraint.constant = newConstant
            self.view.layoutIfNeeded()
        }) { (val) in
            
        }
    }
    
    func searchTapped(shouldHideContents: Bool) {
        if shouldHideContents {
            childDelegate?.clear()
        }
    }
    
    func addSongTapped(song: Song) {
        var newSong = self.songToJSON(song: song)
        var ref: DocumentReference? = nil
        ref = db?.collection("song").addDocument(data: [
            "queueId": self.queueId!
            ], completion: { (val) in
                newSong["docID"] = ref!.documentID
                self.jointDelegate?.addSongTapped(song: self.JSONToSong(json: newSong))
                
                self.db?.collection("playlist").document(self.queueId!).collection("songs").getDocuments(completion: { (snapshot, error) in
                    guard let snap = snapshot else {
                        print(error!)
                        return
                    }
                    if snap.documents.count == 0 {
                        newSong["next"] = true
                    }
                    self.db?.collection("playlist").document(self.queueId!).collection("songs").document(ref!.documentID).setData(newSong, completion: { err in
                        self.db?.collection("song").document(ref!.documentID).collection("upvoteUsers").document(self.uid!).setData([:], completion: { (err) in  })
                    })
                })
        })
    }
    
    func songToJSON(song: Song) -> [String:Any] {
        return [
            "artist": song.artist,
            "name": song.name,
            "imageURL": song.imageURL,
            "docID": song.docID,
            "votes": 0,
            "uri": song.uri,
            "next": song.next
        ]
    }
    
    func JSONToSong(json: [String:Any]) -> Song {
        var song = Song()
        song.artist = json["artist"] as! String
        song.name = json["name"] as! String
        song.imageURL = json["imageURL"] as! String
        song.docID = json["docID"] as! String
        song.votes = json["votes"] as! Int
        song.uri = json["uri"] as! String
        song.next = json["next"] as! Bool
        return song
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is SearchController {
            /// swap delegates with SearchController
            let vc = segue.destination as? SearchController
            vc?.delegate = self
            childDelegate = vc
        }
        else if segue.destination is PlaylistViewController {
            let vc = segue.destination as? PlaylistViewController
            vc?.delegate = self
        }
        else if false {
            
        }
    }
}
