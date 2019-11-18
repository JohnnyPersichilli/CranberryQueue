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
    
    @IBOutlet weak var mapIcon: UIImageView!
    
    @IBOutlet weak var spotifyProfilePicture: UIImageView!
    
    @IBOutlet weak var spotifyProfileView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var spotifyUsernameLabel: UILabel!
    
    @IBOutlet var logoutImageView: UIImageView!
    
    weak var mapDelegate: SettingsMapDelegate? = nil
    
    @IBOutlet weak var settingsOptionTable: UITableView!
    
    @IBOutlet weak var settingsMoreDetailView: UIView!

    @IBOutlet weak var moreDetailTitleLabel: UILabel!
    
    @IBOutlet weak var moreDetailTextView: UITextView!
    @IBOutlet weak var closeMoreDetailImage: UIImageView!
    
    struct SettingsOption {
        var name = String()
        var text = String()
    }
    
    var aboutUsOption = SettingsOption(
        name: "About us",
        text: "Explore music playlists from around the world or share your own. Spotify's SDK provides local playback for hosts and Firestore supports a location-based voting scheme."
    )
    var legalNoticeOption = SettingsOption(
        name: "Legal Notices",
        text: GMSServices.openSourceLicenseInfo()
    )
    var faqOption = SettingsOption(
        name: "FAQ",
        text: "Insert FAQ questions here"
    )
    var reportBugOption = SettingsOption(
        name: "Report A Bug",
        text: "Insert bug reporting here"
    )
    
    lazy var optionsArray = [
        aboutUsOption,
        legalNoticeOption,
        faqOption,
        reportBugOption,
    ]
    
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
        
        settingsMoreDetailView.isHidden = true
        
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
        
        let closeDetailModal = UITapGestureRecognizer(target: self, action: #selector(closeDetailViewTapped))
        closeMoreDetailImage.addGestureRecognizer(closeDetailModal)
        closeMoreDetailImage.isUserInteractionEnabled = true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = optionsArray[indexPath.row]
        self.showDetailViewWith(option: option)
        self.settingsOptionTable.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsOptionTable.dequeueReusableCell(withIdentifier: "aboutUsCell", for: indexPath) as! SettingsTableViewCell
        if(indexPath.row >= optionsArray.count){
            cell.isHidden = true
            return cell
        }
        let option = optionsArray[indexPath.row]
        cell.nameLabel.text = option.name
        return cell
    }
    
    @objc func closeDetailViewTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.settingsMoreDetailView.alpha = 0
        }) { (val) in
            self.settingsMoreDetailView.isHidden = true
            self.settingsOptionTable.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsOptionTable.alpha = 1
            })
        }
    }
    
    @objc func logoutTapped() {
        let alert = UIAlertController(title: "Are you sure want to sign out of Spotify?", message: "Signing out of Spotify will delete or leave your current queue.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            self.mapDelegate?.logoutTapped()
            self.setDefaultInfo()
            self.presentingViewController?.dismiss(animated:true, completion: {
                self.navigationController?.popToRootViewController(animated: true)
            })
         }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
        }
        ))
        self.present(alert, animated: true)
    }
    
    @objc func globeTapped() {
        self.presentingViewController?.dismiss(animated:true, completion: { self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func showDetailViewWith(option: SettingsOption) {
        UIView.animate(withDuration: 0.3, animations: {
            self.settingsOptionTable.alpha = 0
        }) { (val) in
            self.settingsOptionTable.isHidden = true
            self.settingsMoreDetailView.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.settingsMoreDetailView.alpha = 1
            })
        }
        DispatchQueue.main.async {
            self.moreDetailTitleLabel.text = option.name
            self.moreDetailTextView.text = option.text
        }
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
            guard let data0 = data else {
                print(error!)
                return
            }
            do {
                let jsonRes = try JSONSerialization.jsonObject(with: data0, options: []) as? [String: Any]
                DispatchQueue.main.async {
                    self.nameLabel.text = jsonRes?["display_name"] as? String
                    self.spotifyUsernameLabel.text = jsonRes?["id"] as? String
                }
                let imageInfoArray = (jsonRes?["images"] as! [[String:Any]])
                if(imageInfoArray.count != 0) {
                    let url = imageInfoArray[0]["url"] as! String
                    self.downloadDataFrom(url: url) { data in
                        DispatchQueue.main.async {
                            self.spotifyProfilePicture.image = UIImage(data: data)
                        }
                    }
                }else{
                    self.setDefaultImage()
                }
            } catch {
                print("Could not serialize JSON")
            }
        }
        task.resume()
    }
    
    func downloadDataFrom(url: String, completion: @escaping (Data)->Void) {
        guard let url = URL(string: url) else {
            print("Invalid URL")
            return
        }
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                print("No data downloaded from URL")
                return
            }
            completion(data)
        }
        task.resume()
    }
    
}
