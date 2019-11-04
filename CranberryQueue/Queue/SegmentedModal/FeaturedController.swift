//
//  SearchController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

class FeaturedController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SegmentedChildDelegate {
    
    @IBOutlet weak var featuredTableView: UITableView!
    
    weak var delegate: SegmentedJointDelegate?
    
    var db: Firestore?
    
    var city: String? = nil
    var region: String? = nil
    
    var songs = [Song]()
    var isHost = false
    var queueId: String? = nil
    var uid: String? = nil
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        featuredTableView.delegate = self
        featuredTableView.dataSource = self
        getFeaturedSongs() { (songs) in
            self.songs = songs
            DispatchQueue.main.async {
                self.featuredTableView.reloadData()
            }
        }
        
    }
    
    func clear() {
        featuredTableView.reloadData()
    }
    
    func getFeaturedSongs(completion: @escaping ([Song]) -> Void) {
        db?.collection("playbackArchive").whereField("city", isEqualTo: self.city).whereField("region", isEqualTo: self.region).getDocuments(completion: { (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            var songs = [Song]()
            for doc in snap.documents {
            let newSong = Song (
                name: doc.data()["name"] as! String,
                artist: doc.data()["artist"] as! String,
                imageURL: doc.data()["imageURL"] as! String,
                docID: "f",
                votes: 1,
                uri: doc.data()["uri"] as! String,
                next: false
                )
            songs.append(newSong)
            }
        completion(songs)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return songs.count
    }
  
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).isHidden = true
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).isHidden = true
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = featuredTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeaturedTableViewCell
        if !songs.indices.contains(indexPath.section) {
            print("bad error searchcontroller L147")
            return cell
        }
        cell.songLabel.text = songs[indexPath.section].name
        cell.artistLabel.text = songs[indexPath.section].artist
        
        cell.song = songs[indexPath.section]
        print("Cell song",cell.song)
        
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped(sender:)))
        cell.addIconImageView.addGestureRecognizer(addTap)
        cell.addIconImageView.isUserInteractionEnabled = true
        
        cell.albumImageView.image = nil
        let url = URL(string: songs[indexPath.section].imageURL)
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return }
            
            DispatchQueue.main.async() {
                let updatingCell = self.featuredTableView.cellForRow(at: indexPath) as? FeaturedTableViewCell
                updatingCell?.albumImageView.image = UIImage(data: data)
            }
        }
        task.resume()

        return cell
    }
    
    @objc func addTapped(sender : UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.featuredTableView)
        let indexPath : IndexPath = self.featuredTableView.indexPathForRow(at: tapLocation)!
        
        if let cell = self.featuredTableView.cellForRow(at: indexPath) as? FeaturedTableViewCell {
            
            DispatchQueue.main.async {
                self.featuredTableView.reloadData()
            }
            
            var newSong = self.songToJSON(song: cell.song)
            var ref: DocumentReference? = nil
            ref = db?.collection("song").addDocument(data: [
                "queueId": self.queueId!
                ], completion: { (val) in
                    newSong["docID"] = ref!.documentID
                    self.delegate?.addSongTapped(song: self.JSONToSong(json: newSong))
                    
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
    
}
