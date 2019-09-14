//
//  SongTableView.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SongTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var songs = [Song]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
        
        cell.songLabel.text = songs[indexPath.row].name
        cell.artistLabel.text = songs[indexPath.row].artist
        
        let url = URL(string: songs[indexPath.row].imageURL)
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


