//
//  SettingsTableView.swift
//  CranberryQueue
//
//  Created by Johnny Persichilli on 10/21/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SettingsTableView: UITableView, UITableViewDelegate, UITableViewDataSource{

    func tableView(_ tableView: UITableView, didSelectSectionAt indexPath: IndexPath) {
        print("row", indexPath.section)
    }
    
    var optionsArray = [
    ["name": "About us", "text": ""], [ "name": "Legal Notices", "text": ""]
    
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return optionsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = SettingsTableViewCell()
        cell = self.dequeueReusableCell(withIdentifier: "aboutUsCell", for: indexPath) as! SettingsTableViewCell
        var option = optionsArray[indexPath.section]
        cell.optionsNameLabel.text = option["name"]
        return cell
    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//        if indexPath.section == 0 {
//            cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
//            cell.shadOpacity = 0.6
//            cell.addGradient()
//            cell.voteLabel.isHidden = true
//            cell.downvoteButtonImageView.isHidden = true
//            cell.upvoteButtonImageView.isHidden = true
//        }
//        else {
//            cell = self.dequeueReusableCell(withIdentifier: "CellHorizontal", for: indexPath) as! QueueTableViewCell
//            cell.shadOpacity = 0.3
//            cell.removeGradient()
//        }
//
//        UIView.animate(withDuration: 0.3, animations: {
//            cell.alpha = 0
//        }) { (val) in
//            cell.contentView.layoutIfNeeded()
//            cell.addShadow()
//            UIView.animate(withDuration: 0.5) {
//                cell.alpha = 1
//            }
//        }
//
//        if indexPath.section >= songs.count {
//            return cell
//        }
//        let song = songs[indexPath.section]
//        cell.songLabel.text = song.name
//        cell.artistLabel.text = song.artist
//        cell.songId = song.docID
//        cell.voteLabel.text = String(song.votes)
//
//        cell.song = song // need to depreciate above
//        cell.delegate = self
//        cell.uid = self.uid
//
//        if upvotes.contains(where: {$0 == song.docID}) {
//            cell.upvoteButtonImageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
//            cell.downvoteButtonImageView.backgroundColor = UIColor.clear
//            cell.upvoteButtonImageView.isUserInteractionEnabled = false
//            cell.downvoteButtonImageView.isUserInteractionEnabled = true
//        }
//        else if downvotes.contains(where: {$0 == song.docID}) {
//            cell.downvoteButtonImageView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2410657728)
//            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
//            cell.upvoteButtonImageView.isUserInteractionEnabled = true
//            cell.downvoteButtonImageView.isUserInteractionEnabled = false
//        }
//        else {
//            cell.upvoteButtonImageView.backgroundColor = UIColor.clear
//            cell.downvoteButtonImageView.backgroundColor = UIColor.clear
//            cell.upvoteButtonImageView.isUserInteractionEnabled = true
//            cell.downvoteButtonImageView.isUserInteractionEnabled = true
//        }
//        if pendingUpvotes.contains(where: {$0 == song}) || pendingDownvotes.contains(where: {$0 == song}) {
//            cell.isUserInteractionEnabled = false
//        }
//        else {
//            cell.isUserInteractionEnabled = true
//        }
//
//        cell.albumImageView.image = nil
//        let url = URL(string: songs[indexPath.section].imageURL)
//        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
//            guard let data = data, error == nil else {
//                print(error!)
//                return }
//            DispatchQueue.main.async() {
//                let updatingCell = self.cellForRow(at: indexPath) as? QueueTableViewCell
//                updatingCell?.albumImageView.image = UIImage(data: data)
//            }
//        }
//
//        task.resume()
//
//        return cell
//    }
//    }
    
    

    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
