//
//  SettingsViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/15/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

protocol SettingsMapDelegate: class {
    func logoutTapped()
}

class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var mapIcon: UIImageView!
    
    @IBOutlet weak var spotifyProfilePicture: UIImageView!
    
    @IBOutlet weak var spotifyProfileView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var spotifyUsernameLabel: UILabel!
    
    @IBOutlet var logoutImageView: UIImageView!
    
    weak var mapDelegate: SettingsMapDelegate? = nil
    
    @IBOutlet weak var settingsOptionTable: SettingsTableView!
    
    var token: String {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.token
        }
    }
    
    func setupGestureRecognizers() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(globeTapped))
        mapIcon.addGestureRecognizer(addTap)
        mapIcon.isUserInteractionEnabled = true
        
        let logoutTap = UITapGestureRecognizer(target: self, action: #selector(logoutTapped))
        logoutImageView.addGestureRecognizer(logoutTap)
        logoutImageView.isUserInteractionEnabled = true
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupGestureRecognizers()
        
        settingsOptionTable.delegate = self as? UITableViewDelegate
        settingsOptionTable.dataSource = self as? UITableViewDataSource
        
        if token == "" {
            setDefaultInfo()
        }
        else {
            self.getUserSpotifyInfo()
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
