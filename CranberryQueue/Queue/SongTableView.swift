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
    
    var songRef: ListenerRegistration? = nil
    
    var upvotes = [String]()
    var downvotes = [String]()
    var pendingUpvotes = [Song]()
    var pendingDownvotes = [Song]()
    var superVotes = [String]()
    
    func watchPlaylist() {
        db = Firestore.firestore()
        
        songRef = db?.collection("playlist").document(queueId!).collection("songs").order(by: "next", descending: true).order(by: "votes", descending: true).addSnapshotListener({ (snapshot, error) in
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
                    self.songDelegate?.updateNumSongs(0)
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
                self.superVotes.removeAll(where: {$0 == song.documentID})
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
            if pendingDownvotes.contains(where: {$0 == song}) || downvotes.contains(where: {$0 == song.docID}) {
                superVotes.append(song.docID)
            }
            pendingDownvotes.removeAll(where: {$0 == song})
            downvotes.removeAll(where: {$0 == song.docID})
        }
        else {
            pendingDownvotes.append(song)
            downvotes.append(song.docID)
            if pendingUpvotes.contains(where: {$0 == song}) || upvotes.contains(where: {$0 == song.docID}) {
                superVotes.append(song.docID)
            }
            pendingUpvotes.removeAll(where: {$0 == song})
            upvotes.removeAll(where: {$0 == song.docID})
        }
        UserDefaults.standard.set(upvotes, forKey: "\(queueId!)/upvotes")
        UserDefaults.standard.set(downvotes, forKey: "\(queueId!)/downvotes")
        reloadData()
    }
    
    func loadPreviousVotes() {
        upvotes = UserDefaults.standard.array(forKey: "\(queueId!)/upvotes") as? [String] ?? []
        downvotes = UserDefaults.standard.array(forKey: "\(queueId!)/downvotes") as? [String] ?? []
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
        (view as! UITableViewHeaderFooterView).isHidden = true
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).isHidden = true
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isHost
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete && isHost) {
            let song = songs[indexPath.section]
            
            self.db?.collection("playlist").document(self.queueId!).collection("songs").document(song.docID).delete()
            self.db?.collection("song").document(song.docID).delete()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = QueueTableViewCell()
        if indexPath.section == 0 {
            cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
            cell.shadOpacity = 0.6
            cell.addGradient()
        }
        else {
            cell = self.dequeueReusableCell(withIdentifier: "CellHorizontal", for: indexPath) as! QueueTableViewCell
            cell.shadOpacity = 0.3
            cell.removeGradient()
        }
        
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
            cell.upvoteButtonImageView.isUserInteractionEnabled = false
            cell.downvoteButtonImageView.isUserInteractionEnabled = true
        }
        else if downvotes.contains(where: {$0 == song.docID}) {
            cell.downvoteButtonImageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
            cell.upvoteButtonImageView.isUserInteractionEnabled = true
            cell.downvoteButtonImageView.isUserInteractionEnabled = false
        }
        else {
            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
            cell.downvoteButtonImageView.backgroundColor = UIColor.clear
            cell.upvoteButtonImageView.isUserInteractionEnabled = true
            cell.downvoteButtonImageView.isUserInteractionEnabled = true
        }
        if pendingUpvotes.contains(where: {$0 == song}) {
            if superVotes.contains(song.docID) {
                cell.voteLabel.text = String(song.votes + 2)
            }
            else {
                cell.voteLabel.text = String(song.votes + 1)
            }
            cell.isUserInteractionEnabled = false
        }
        else if pendingDownvotes.contains(where: {$0 == song}) {
            if superVotes.contains(song.docID) {
                cell.voteLabel.text = String(song.votes - 2)
            }
            else {
                cell.voteLabel.text = String(song.votes - 1)
            }
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
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


