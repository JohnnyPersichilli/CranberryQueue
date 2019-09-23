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

class SongTableView: UITableView, UITableViewDelegate, UITableViewDataSource, QueueCellDelegate {
    
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
    
    var upvotes = [String]()
    var downvotes = [String]()
    var pendingUpvotes = [Song]()
    var pendingDownvotes = [Song]()
    
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
                
                self.pendingUpvotes.removeAll(where: {$0 == newSong && $0.votes != newSong.votes})
                self.pendingDownvotes.removeAll(where: {$0 == newSong && $0.votes != newSong.votes})
            }
            self.songDelegate?.updateNumSongs(self.songs.count)
            DispatchQueue.main.async {
                self.reloadData()
            }
        })
    }
    
    func voteTapped(isUpvote: Bool, song: Song) {
        if isUpvote {
            pendingUpvotes.append(song)
            upvotes.append(song.docID)
            pendingDownvotes.removeAll(where: {$0 == song})
            downvotes.removeAll(where: {$0 == song.docID})
        }
        else {
            pendingDownvotes.append(song)
            downvotes.append(song.docID)
            pendingUpvotes.removeAll(where: {$0 == song})
            upvotes.removeAll(where: {$0 == song.docID})
        }
        reloadData()
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
        let song = songs[indexPath.section]
        cell.songLabel.text = song.name
        cell.artistLabel.text = song.artist
        cell.songId = song.docID
        cell.voteLabel.text = String(song.votes)
        
        cell.song = song // need to depreciate above
        cell.delegate = self
        cell.uid = self.uid
        
        if upvotes.contains(where: {$0 == song.docID}) {
            cell.upvoteButtonImageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
            cell.downvoteButtonImageView.backgroundColor = UIColor.clear
        }
        else if downvotes.contains(where: {$0 == song.docID}) {
            cell.downvoteButtonImageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
        }
        else {
            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
            cell.downvoteButtonImageView.backgroundColor = UIColor.clear
        }
        if pendingUpvotes.contains(where: {$0 == song}) {
            cell.voteLabel.text = String(song.votes + 1)
        }
        else if pendingDownvotes.contains(where: {$0 == song}) {
            cell.voteLabel.text = String(song.votes - 1)
        }
        
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


