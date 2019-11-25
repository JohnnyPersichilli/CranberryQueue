//
//  SearchController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/14/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class SearchController: UIViewController, UISearchBarDelegate, SegmentedChildDelegate, TableSegmentedDelegate {
        
    @IBOutlet var searchTableView: SearchTableView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    weak var delegate: SegmentedJointDelegate?
    
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTableView.delegate = searchTableView
        searchTableView.dataSource = searchTableView
        searchTableView.controllerDelegate = self
        
        searchBar.delegate = self
        searchBar.showsCancelButton = false
    }
    
    func populate() {
        // called on search tapped
    }
    
    func clear() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        searchTableView.clear()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        if text == "" { return }
        
        trackSearchWith(string: text) { (songs) in
            DispatchQueue.main.async {
                self.searchBar.resignFirstResponder()
                self.searchBar.showsCancelButton = false
                self.searchTableView.songs = songs
                self.searchTableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }
    
    func trackSearchWith(string: String, completion: @escaping ([Song]) -> Void) {
        let searchString = (string).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(searchString)&type=track")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data0 = data else {
                print(error!)
                return
            }
            do {
                let jsonRes = try JSONSerialization.jsonObject(with: data0, options: []) as? [String: Any]
                let tracks = jsonRes?["tracks"] as! [String:Any]
                let items = tracks["items"] as! [[String:Any]]
                var songs = [Song]()
                for x in items {
                    let artistInfo = x["artists"] as! [[String:Any]]
                    let albumInfo = x["album"] as! [String:Any]
                    let imageInfo = (albumInfo["images"] as? [[String:Any]]) ?? [["url":"https://i.scdn.co/image/239ec906572231368d8ebd72614094bd3bd10b33"]]
                    let newSong = Song(
                        name: x["name"] as! String,
                        artist: artistInfo[0]["name"] as! String,
                        imageURL: imageInfo.count > 0 ? imageInfo[0]["url"] as! String : "https://i.scdn.co/image/239ec906572231368d8ebd72614094bd3bd10b33",
                        docID: "f",
                        votes: 1,
                        uri: x["uri"] as! String,
                        next: false
                    )
                    songs.append(newSong)
                }
                completion(songs)
                
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func addSongTapped(song: Song) {
        searchBar.text = ""
        clear()
        delegate?.addSongTapped(song: song)
    }
    
    func requestAdditionalData(fromIndex index: Int, limit: Int) {
        // used to query more data when scrolling
    }
    
}
