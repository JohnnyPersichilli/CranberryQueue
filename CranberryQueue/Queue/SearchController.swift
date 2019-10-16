//
//  SearchController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol searchDelegate: class {
    func addSongTapped(song: Song)
}

class SearchController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, queueDelegate {
    
    func searchTapped(shouldHideContents: Bool) {
        if(shouldHideContents) {
            songs = []
            searchTextField.resignFirstResponder()
            searchTextField.text = ""
            DispatchQueue.main.async {
                self.searchTableView.reloadData()
            }
        } else {
            searchTextField.becomeFirstResponder()
        }
    }
    
    @IBOutlet var searchTextField: UITextField!
    
    @IBOutlet var searchTableView: UITableView!
    
    weak var delegate: searchDelegate?
    
    var db: Firestore?
    
    var searchFirstTap: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTableView.delegate = self
        searchTableView.dataSource = self
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        
        db = Firestore.firestore()
        
    }
    
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
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.text == nil || textField.text == "" {
            return false
        }
        
        let searchString = (textField.text ?? "").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(searchString)&type=track")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let res = response {
                //print(res)
            }
            if let err = error {
                print(err)
                return
            }
            guard let data0 = data else {
                return
            }
            do {
                let jsonRes = try JSONSerialization.jsonObject(with: data0, options: []) as? [String: Any]
                let tracks = jsonRes?["tracks"] as! [String:Any]
                let items = tracks["items"] as! [[String:Any]]
                self.songs = []
                for x in items {
                    let artistInfo = x["artists"] as! [[String:Any]]
                    let albumInfo = x["album"] as! [String:Any]
                    let imageInfo = (albumInfo["images"] as? [[String:Any]]) ?? [["url":"https://i.scdn.co/image/239ec906572231368d8ebd72614094bd3bd10b33"]]
                    if(imageInfo.count > 0){
                        let newSong = Song(
                            name: x["name"] as! String,
                            artist: artistInfo[0]["name"] as! String,
                            imageURL: imageInfo[0]["url"] as! String,
                            docID: "f",
                            votes: 1,
                            uri: x["uri"] as! String,
                            next: false
                        )
                        self.songs.append(newSong)
                    }else{
                        let newSong = Song(
                            name: x["name"] as! String,
                            artist: artistInfo[0]["name"] as! String,
                            imageURL: "https://i.scdn.co/image/239ec906572231368d8ebd72614094bd3bd10b33",
                            docID: "f",
                            votes: 1,
                            uri: x["uri"] as! String,
                            next: false
                        )
                        self.songs.append(newSong)
                    }
                }
                DispatchQueue.main.async {
                    self.searchTableView.reloadData()
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
        //        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        //            guard let data = data else {
        //                print("no data")
        //                return }
        //            print(String(data: data, encoding: .utf8)!)
        //        }
        //
        //        task.resume()
        searchTextField.resignFirstResponder()
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return songs.count
    }
    
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        if indexPath.section == 0 {
    //            return 90
    //        }
    //        else {
    //            return 60
    //        }
    //    }
    
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
        let cell = searchTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchTableViewCell
        if !songs.indices.contains(indexPath.section) {
            print("bad error searchcontroller L147")
            return cell
        }
        cell.songLabel.text = songs[indexPath.section].name
        cell.artistLabel.text = songs[indexPath.section].artist
        //cell.layer.borderWidth = 1
        
        cell.song = songs[indexPath.section]
        
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped(sender:)))
        cell.addIconImageView.addGestureRecognizer(addTap)
        cell.addIconImageView.isUserInteractionEnabled = true
        
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
    
    @objc func addTapped(sender : UITapGestureRecognizer)
    {
        let tapLocation = sender.location(in: self.searchTableView)
        let indexPath : IndexPath = self.searchTableView.indexPathForRow(at: tapLocation)!
        
        if let cell = self.searchTableView.cellForRow(at: indexPath) as? SearchTableViewCell
        {
            songs = []
            searchTextField.text = ""
            
            DispatchQueue.main.async {
                self.searchTableView.reloadData()
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
