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

class SongTableView: UITableView, UITableViewDelegate, UITableViewDataSource, QueueCellDelegate, PlayerTableDelegate {
    
    var shouldBeEnqueued: String?
    
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
    var pendingVotes = [Song]()
    
    func watchPlaylist() {
        db = Firestore.firestore()
        
        songRef = db?.collection("playlist").document(queueId!).collection("songs").order(by: "next", descending: true).order(by: "votes", descending: true).addSnapshotListener({ (snapshot, error) in
            var newSongs = [Song]()
            let oldSongs = self.songs
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
                    self.songs = []
                    self.reloadData()
                }
                return
            }
            var sectionsToReload = [Int]()
            var sectionsToReloadSilently = [Int]()
            
            for (index, song) in snap.documents.enumerated() {
                if (song["name"] as? String) == nil {
                    continue
                }
                let newSong = Song(
                    name: song["name"] as! String,
                    artist: song["artist"] as! String,
                    imageURL: song["imageURL"] as! String,
                    docID: song["docID"] as! String,
                    votes: song["votes"] as! Int,
                    uri: song["uri"] as! String,
                    next: song["next"] as! Bool
                )
                newSongs.append(newSong)
                
                if self.songs.count <= index { }
                else if self.songs[index].docID != newSongs[index].docID {
                    sectionsToReload.append(index)
                }
                else if self.songs[index].votes != newSongs[index].votes {
                    sectionsToReloadSilently.append(index)
                }
                
                self.pendingVotes.removeAll(where: {$0 == newSong && $0.votes != newSong.votes})
            }
            // enqueue if the table was empty
            if oldSongs.count == 0 && newSongs.count == 1 {
                (UIApplication.shared.delegate as? AppDelegate)?.appRemote.playerAPI?.enqueueTrackUri(newSongs.first!.uri, callback: { (value, error) in
                    if let err = error {
                        print(err)
                        return
                    }
                })
            }
            self.songs = newSongs
            self.performBatchUpdates({
                if newSongs.count < oldSongs.count {
                    self.deleteSections(IndexSet(newSongs.count..<oldSongs.count), with: .fade)
                }
                else {
                    self.insertSections(IndexSet(oldSongs.count..<newSongs.count), with: .fade)
                }
                self.reloadSections(IndexSet(sectionsToReload), with: .fade)
                self.reloadSections(IndexSet(sectionsToReloadSilently), with: .none)
            }) { (_) in
                
            }
            
            self.songDelegate?.updateNumSongs(self.songs.count)
        })
    }
    
    func voteTapped(isUpvote: Bool, song: Song) {
        var weight = isUpvote ? 1 : -1
        if isUpvote {
            upvotes.append(song.docID)
            if pendingVotes.contains(where: {$0 == song}) {
                weight += 1
            }
            pendingVotes.removeAll(where: {$0 == song})
            downvotes.removeAll(where: {$0 == song.docID})
        }
        else {
            downvotes.append(song.docID)
            if pendingVotes.contains(where: {$0 == song}) || upvotes.contains(where: {$0 == song.docID}) {
                weight -= 1
            }
            pendingVotes.removeAll(where: {$0 == song})
            upvotes.removeAll(where: {$0 == song.docID})
        }
        pendingVotes.append(song)
        UserDefaults.standard.set(upvotes, forKey: "\(queueId!)/upvotes")
        UserDefaults.standard.set(downvotes, forKey: "\(queueId!)/downvotes")
        if let cell = visibleCells.first(where: {($0 as! QueueTableViewCell).song == song}) as? QueueTableViewCell {
            cell.voteLabel.text = String(song.votes + weight)
            (isUpvote ? cell.upvoteButtonImageView : cell.downvoteButtonImageView)?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
            (!isUpvote ? cell.upvoteButtonImageView : cell.downvoteButtonImageView)?.backgroundColor = UIColor.clear
        }
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
        return indexPath.section == 0 ? false : isHost
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
            cell.voteLabel.isHidden = true
            cell.downvoteButtonImageView.isHidden = true
            cell.upvoteButtonImageView.isHidden = true
        }
        else {
            cell = self.dequeueReusableCell(withIdentifier: "CellHorizontal", for: indexPath) as! QueueTableViewCell
            cell.shadOpacity = 0.3
            cell.removeGradient()
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            cell.alpha = 0
        }) { (val) in
            cell.contentView.layoutIfNeeded()
            cell.addShadow()
            UIView.animate(withDuration: 0.5) {
                cell.alpha = 1
            }
        }
        
        if indexPath.section >= songs.count {
            return cell
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
        if pendingVotes.contains(where: {$0 == song}) {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        
        cell.albumImageView.image = nil
        let url = URL(string: songs[indexPath.section].imageURL)
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return }
            DispatchQueue.main.async() {
                let updatingCell = self.cellForRow(at: indexPath) as? QueueTableViewCell
                updatingCell?.albumImageView.image = UIImage(data: data)
            }
        }
        
        task.resume()

        return cell
    }
    

}


