//
//  SettingsViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/15/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import GoogleMaps

protocol SettingsMapDelegate: class {
    func logoutTapped()
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var optionsArray = [
        ["name": "About us", "text": "Explore music playlists from around the world or share your own. Spotify's SDK provides local playback for hosts and Firestore supports a location-based voting scheme." ],
        [ "name": "Legal Notices", "text": GMSServices.openSourceLicenseInfo() ],
        [ "name": "FAQ", "text": "Insert FAQ questions here" ],
        [ "name": "Report A Bug", "text": "Insert bug reporting here" ]
    ]
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var option = optionsArray[indexPath.row]
        
        UIView.animate(withDuration: 0.3, animations: {
            self.settingsOptionTable.alpha = 0
        }) { (val) in
            self.settingsOptionTable.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.optionMoreDetailView.alpha = 1
            }) { (val) in
                self.optionMoreDetailView.isHidden = false
                DispatchQueue.main.async {
                    self.moreDetailTitleLabel.text = option["name"]
                    self.moreDetailTextView.text = option["text"]
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = SettingsTableViewCell()
        cell = settingsOptionTable.dequeueReusableCell(withIdentifier: "aboutUsCell", for: indexPath) as! SettingsTableViewCell
        if(indexPath.row >= optionsArray.count){
            cell.isHidden = true
            return cell
        }
        var option = optionsArray[indexPath.row]
        cell.optionsNameLabel.text = option["name"]

        return cell
    }
    
    @objc func closeDetailModalClicked() {
        UIView.animate(withDuration: 0.3, animations: {
            self.optionMoreDetailView.alpha = 0
        }) { (val) in
            self.optionMoreDetailView.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsOptionTable.alpha = 1
            }) { (val) in
                self.settingsOptionTable.isHidden = false
            }
        }
    }
    
    @IBOutlet weak var mapIcon: UIImageView!
    
    @IBOutlet weak var spotifyProfilePicture: UIImageView!
    
    @IBOutlet weak var spotifyProfileView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var spotifyUsernameLabel: UILabel!
    
    @IBOutlet var logoutImageView: UIImageView!
    
    weak var mapDelegate: SettingsMapDelegate? = nil
    
    @IBOutlet weak var settingsOptionTable: UITableView!
    
    @IBOutlet weak var optionMoreDetailView: UIView!
    @IBOutlet weak var moreDetailTitleLabel: UILabel!
    @IBOutlet weak var moreDetailTextView: UITextView!
    @IBOutlet weak var closeMoreDetailImage: UIImageView!
    
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupGestureRecognizers()
        settingsOptionTable.tableFooterView = UIView(frame: .zero)
        
        settingsOptionTable.delegate = self
        settingsOptionTable.dataSource = self
        
        optionMoreDetailView.isHidden = true
        
        if token == "" {
            setDefaultInfo()
        }
        else {
            self.getUserSpotifyInfo()
        }
    }
    
    func setupGestureRecognizers() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(globeTapped))
        mapIcon.addGestureRecognizer(addTap)
        mapIcon.isUserInteractionEnabled = true
        
        let logoutTap = UITapGestureRecognizer(target: self, action: #selector(logoutTapped))
        logoutImageView.addGestureRecognizer(logoutTap)
        logoutImageView.isUserInteractionEnabled = true
        
        let closeDetailModal = UITapGestureRecognizer(target: self, action: #selector(closeDetailModalClicked))
        closeMoreDetailImage.addGestureRecognizer(closeDetailModal)
        closeMoreDetailImage.isUserInteractionEnabled = true
    }
    
    @objc func logoutTapped() {
        mapDelegate?.logoutTapped()
        setDefaultInfo()
        self.presentingViewController?.dismiss(animated:true, completion: {
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    @objc func globeTapped() {
        self.presentingViewController?.dismiss(animated:true, completion: { self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func setDefaultInfo() {
        setDefaultImage()
        nameLabel.text = "Guest"
        spotifyUsernameLabel.text = "--"
    }
    
    func setDefaultImage() {
        DispatchQueue.main.async {
            self.spotifyProfilePicture.image = UIImage(named: "defaultPerson")!
        }
    }
    
    func getUserSpotifyInfo() {

        let url = URL(string: "https://api.spotify.com/v1/me")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let res = response {
                print(res)
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
                DispatchQueue.main.async {
                    self.nameLabel.text = jsonRes?["display_name"] as? String
                    self.spotifyUsernameLabel.text = jsonRes?["id"] as? String
                }
                
                let imageRes = (jsonRes?["images"] as! [[String:Any]])
                if(imageRes.count != 0){
                    let url = URL(string: imageRes[0]["url"] as! String)!
                    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                        guard let data = data else {
                            print("no data")
                            return }
                        DispatchQueue.main.async {
                            self.spotifyProfilePicture.image = UIImage(data: data)
                        }
                    }
                    
                    task.resume()
                }else{
                    self.setDefaultImage()
                }

            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
}
