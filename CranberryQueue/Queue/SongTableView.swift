//
//  SongTableView.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

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
    
    var db: Firestore? = nil
    
    func watchPlaylist() {
        db = Firestore.firestore()
        
        db?.collection("playlist").document(queueId!).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            if snap.data()?["songs"] == nil {
                return
            }
            self.songs = []
            for song in snap.data()?["songs"] as! [[String:Any]] {
                let newSong = Song(
                    name: song["name"] as! String,
                    artist: song["artist"] as! String,
                    imageURL: song["imageURL"] as! String,
                    docID: song["docID"] as! String)
                self.songs.append(newSong)
            }
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
        cell.songLabel.text = songs[indexPath.section].name
        cell.artistLabel.text = songs[indexPath.section].artist
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


