//
//  SearchTableView.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 11/4/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

protocol TableSegmentedDelegate: class {
    func addSongTapped(song: Song)
    func requestAdditionalData(fromIndex index: Int, limit: Int)
}

class SearchTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    var songs = [Song]()
    var shouldStopRequestingSongs = false
    weak var controllerDelegate: TableSegmentedDelegate?

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
    
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
          if let cell = cellForRow(at: indexPath) as? SearchTableViewCell {
              controllerDelegate?.addSongTapped(song: cell.song)
          }
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchTableViewCell
          if !songs.indices.contains(indexPath.section) {
              print("bad error searchcontroller L147")
              return cell
          }
          cell.songLabel.text = songs[indexPath.section].name
          cell.artistLabel.text = songs[indexPath.section].artist
          
          cell.song = songs[indexPath.section]
          
          cell.albumImageView.image = nil
          let url = URL(string: songs[indexPath.section].imageURL)
          let task = URLSession.shared.dataTask(with: url!) { data, response, error in
              guard let data = data, error == nil else {
                  print(error!)
                  return }
              
              DispatchQueue.main.async() {
                let updatingCell = self.cellForRow(at: indexPath) as? SearchTableViewCell
                  updatingCell?.albumImageView.image = UIImage(data: data)
              }
          }
          task.resume()

          return cell
      }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if shouldStopRequestingSongs { return }
        let endIndex = songs.count - 1
        if indexPath.section == endIndex {
            controllerDelegate?.requestAdditionalData(fromIndex: endIndex, limit: 20)
        }
    }
    
    func clear() {
        songs = []
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
}
