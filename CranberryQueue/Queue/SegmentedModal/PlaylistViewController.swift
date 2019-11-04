//
//  PlaylistViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 11/4/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var playlistTableView: UITableView!
    
    var playlists = [Playlist]()
    
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        getPlaylists()
    }
    
    func getPlaylists() {
        let url = URL(string: "https://api.spotify.com/v1/me/playlists")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data0 = data else {
                print(error!)
                return
            }
            do {
                self.playlists = []
                let jsonRes = try JSONSerialization.jsonObject(with: data0, options: []) as! [String: Any]
                let items = jsonRes["items"] as! [[String:Any]]
                print(items)
                for item in items {
                    let name = item["name"] as! String
                    let author = (item["owner"] as! [String:Any])["display_name"] as! String
                    var imageURL = "https://icons-for-free.com/iconfiles/png/512/playlist+icon-1320183325473913098.png"
                    if let images = item["images"] as? [[String:Any]] {
                        if images.count != 0 {
                            imageURL = images[0]["url"] as! String
                        }
                    }
                    let tracksURL = (item["tracks"] as! [String:Any])["href"] as! String
                    let playlist = Playlist(name: name, author: author, imageURL: imageURL, tracksURL: tracksURL)
                    self.playlists.append(playlist)
                }
                DispatchQueue.main.async {
                    self.playlistTableView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playlists.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = playlistTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlaylistCell
        if indexPath.section > playlists.count - 1 {
            return cell
        }
        let playlist = playlists[indexPath.section]
        cell.nameLabel.text = playlist.name
        cell.authorLabel.text = "by " + playlist.author
        cell.imageURL = playlist.imageURL
        return cell
    }
    
    struct Playlist {
        var name: String
        var author: String
        var imageURL: String
        var tracksURL: String
    }
    
}

class PlaylistCell: UITableViewCell {
    @IBOutlet var playlistImageView: UIRoundedImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var authorLabel: UILabel!
    
    var imageURL = String() {
        didSet {
            if imageURL == "" {
                DispatchQueue.main.async {
                    self.playlistImageView.image = nil
                }
            }
            else {
                guard let url = URL(string: imageURL) else { return }
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else {
                        print(error!)
                        return }
                    DispatchQueue.main.async() {
                        self.playlistImageView.image = UIImage(data: data)
                    }
                }
                task.resume()
            }
        }
    }
}
