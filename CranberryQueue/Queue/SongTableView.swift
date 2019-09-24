//
//  SongTableView.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol SongTableDelegate: class {
    func updateNumSongs(_ numSongs: Int)
}

class SongTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var songs = [Song]()
    var isHost = false {
        didSet {
            if isHost {
                // can do host things
            }
        }
    }
    var queueId: String? = nil
    var uid: String? = nil
    
    var songId: String? = nil
    
    var db: Firestore? = nil
    
    weak var songDelegate: SongTableDelegate? = nil
    
    func watchPlaylist() {
        db = Firestore.firestore()
        
        db?.collection("playlist").document(queueId!).collection("songs").order(by: "votes", descending: true).addSnapshotListener({ (snapshot, error) in
            self.songs = []
            guard let snap = snapshot else {
                print(error!)
                DispatchQueue.main.async {
                    self.reloadData()
                }
                return
            }
            if snap.documents.count == 0 {
                DispatchQueue.main.async {
                    self.reloadData()
                }
                return
            }
            for song in snap.documents {
                if (song["name"] as? String) == nil {
                    continue
                }
                let newSong = Song(
                    name: song["name"] as! String,
                    artist: song["artist"] as! String,
                    imageURL: song["imageURL"] as! String,
                    docID: song["docID"] as! String,
                    votes: song["votes"] as! Int,
                    uri: song["uri"] as! String
                )
                self.songs.append(newSong)
            }
            self.songDelegate?.updateNumSongs(self.songs.count)
            DispatchQueue.main.async {
                self.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 90
        }
        else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete && isHost) {
            let song = songs[indexPath.section]
            
            self.db?.collection("song").document(song.docID).getDocument(completion: { (snapshot, error) in
                if let err = error {
                    print(err)
                }
                if let docQueueId = snapshot?.data()?["queueId"] as? String {
                    if self.queueId == docQueueId {
                        print("Delete song with id:",docQueueId )
                        self.db?.collection("song").document(song.docID).delete(completion: { (err) in
                            if let err = err{
                                print(err)
                            }
                            self.db?.collection("playlist").document(self.queueId!).collection("songs").document(song.docID).delete()
                            })
                    }
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
        let song = songs[indexPath.section]
        cell.songLabel.text = song.name
        cell.artistLabel.text = song.artist
        cell.songId = song.docID
        cell.uid = self.uid
        cell.voteLabel.text = String(song.votes)
        
        //cell.layer.borderWidth = 1
        
        let url = URL(string: songs[indexPath.section].imageURL)
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return }
            
            DispatchQueue.main.async() {
                cell.albumImageView.image = UIImage(data: data)
            }
        }
        
        task.resume()
        
        if indexPath.section == 0 {
            
        }
        
        return cell
    }
    

}


