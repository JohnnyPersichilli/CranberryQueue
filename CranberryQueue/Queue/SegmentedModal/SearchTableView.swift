//
//  SearchTableView.swift
//  CranberryQueue
//
//  Created by Johnny Persichilli on 11/3/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

//import UIKit
//import Firebase
//
//class SearchTableView: UITableView {
//
//    /*
//    // Only override draw() if you perform custom drawing.
//    // An empty implementation adversely affects performance during animation.
//    override func draw(_ rect: CGRect) {
//        // Drawing code
//    }
//    */
//    var db: Firestore?
//
//    var songs = [Song]()
//
//      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//          return 1
//      }
//
//      func numberOfSections(in tableView: UITableView) -> Int {
//          return songs.count
//      }
//
//      func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
//          (view as! UITableViewHeaderFooterView).isHidden = true
//      }
//
//      func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//          (view as! UITableViewHeaderFooterView).isHidden = true
//      }
//
//      func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//          return 15
//      }
//
//      func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//          return 0
//      }
//
//      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//          let cell = self.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchTableViewCell
//          if !songs.indices.contains(indexPath.section) {
//              print("bad error searchcontroller L147")
//              return cell
//          }
//          cell.songLabel.text = songs[indexPath.section].name
//          cell.artistLabel.text = songs[indexPath.section].artist
//
//          cell.song = songs[indexPath.section]
//
//          let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped(sender:)))
//          cell.addIconImageView.addGestureRecognizer(addTap)
//          cell.addIconImageView.isUserInteractionEnabled = true
//
//          cell.albumImageView.image = nil
//          let url = URL(string: songs[indexPath.section].imageURL)
//          let task = URLSession.shared.dataTask(with: url!) { data, response, error in
//              guard let data = data, error == nil else {
//                  print(error!)
//                  return }
//
//              DispatchQueue.main.async() {
//                  let updatingCell = self.cellForRow(at: indexPath) as? SearchTableViewCell
//                  updatingCell?.albumImageView.image = UIImage(data: data)
//              }
//          }
//          task.resume()
//
//          return cell
//      }
//
//    @objc func addTapped(sender : UITapGestureRecognizer) {
//        let tapLocation = sender.location(in: self)
//        let indexPath : IndexPath = self.indexPathForRow(at: tapLocation)!
//
//        if let cell = self.cellForRow(at: indexPath) as? SearchTableViewCell {
//            songs = []
//            searchBar.text = ""
//
//            DispatchQueue.main.async {
//                self.reloadData()
//            }
//
//            var newSong = self.songToJSON(song: cell.song)
//            var ref: DocumentReference? = nil
//            ref = db?.collection("song").addDocument(data: [
//                "queueId": self.queueId!
//                ], completion: { (val) in
//                    newSong["docID"] = ref!.documentID
//                    self.delegate?.addSongTapped(song: self.JSONToSong(json: newSong))
//
//                    self.db?.collection("playlist").document(self.queueId!).collection("songs").getDocuments(completion: { (snapshot, error) in
//                        guard let snap = snapshot else {
//                            print(error!)
//                            return
//                        }
//                        if snap.documents.count == 0 {
//                            newSong["next"] = true
//                        }
//                        self.db?.collection("playlist").document(self.queueId!).collection("songs").document(ref!.documentID).setData(newSong, completion: { err in
//                            self.db?.collection("song").document(ref!.documentID).collection("upvoteUsers").document(self.uid!).setData([:], completion: { (err) in  })
//                        })
//                    })
//            })
//        }
//    }
//    func songToJSON(song: Song) -> [String:Any] {
//        return [
//            "artist": song.artist,
//            "name": song.name,
//            "imageURL": song.imageURL,
//            "docID": song.docID,
//            "votes": 0,
//            "uri": song.uri,
//            "next": song.next
//        ]
//    }
//
//    func JSONToSong(json: [String:Any]) -> Song {
//        var song = Song()
//        song.artist = json["artist"] as! String
//        song.name = json["name"] as! String
//        song.imageURL = json["imageURL"] as! String
//        song.docID = json["docID"] as! String
//        song.votes = json["votes"] as! Int
//        song.uri = json["uri"] as! String
//        song.next = json["next"] as! Bool
//        return song
//    }
//
//}
