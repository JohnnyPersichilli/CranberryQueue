//
//  SearchController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

class FeaturedController: UIViewController, SegmentedChildDelegate, TableSegmentedDelegate {
    
    @IBOutlet weak var featuredTableView: SearchTableView!
    
    weak var delegate: SegmentedJointDelegate?
    
    var db: Firestore?
    
    var city: String? = nil
    var region: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        featuredTableView.delegate = featuredTableView
        featuredTableView.dataSource = featuredTableView
        featuredTableView.controllerDelegate = self
        getFeaturedSongs() { (songs) in
            DispatchQueue.main.async {
                self.featuredTableView.songs = songs
                self.featuredTableView.reloadData()
            }
        }
    }
    
    func populate() {
        // called on search tapped
    }
    
    func clear() {
        featuredTableView.reloadData()
    }
    
    func getFeaturedSongs(completion: @escaping ([Song]) -> Void) {
        db?.collection("topSongs").order(by: "count", descending: true).limit(to: 25).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            var songs = [Song]()
            for doc in snap.documents {
                let newSong = Song(
                    name: doc.data()["name"] as! String,
                    artist: doc.data()["artist"] as! String,
                    imageURL: doc.data()["imageURL"] as! String,
                    docID: "",
                    votes: 1,
                    uri: doc.data()["uri"] as! String,
                    next: false
                )
                songs.append(newSong)
            }
            completion(songs)
        })
    }
    
    func requestAdditionalData(fromIndex index: Int, limit: Int) {
        // used to query more data when scrolling
    }
    
    func addSongTapped(song: Song) {
        delegate?.addSongTapped(song: song)
    }
    
}
