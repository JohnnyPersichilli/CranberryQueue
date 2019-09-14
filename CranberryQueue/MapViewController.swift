//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import Firebase

protocol mapControllerDelegate: class {
    func addTapped()
    func getCoords() -> ([String:Double])
}

class MapViewController: UIViewController, mapDelegate, UITextFieldDelegate {
    
    @IBOutlet var cityLabel: UILabel!
    
    @IBOutlet var regionLabel: UILabel!
    
    @IBOutlet var addIconImageView: UIImageView!
    
    @IBOutlet var createQueueForm: createQueueForm!
    
    var db : Firestore? = nil
    
    weak var delegate: mapControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        setupScreen()
        setupGestureRecognizers()
        
        createQueueForm.queueNameTextField.delegate = self
    }
    
    func updateGeoCode(city: String, region: String) {
        cityLabel.text = city
        regionLabel.text = region
    }
    
    func setupScreen() {
        self.navigationController?.isNavigationBarHidden = true
        
        view.backgroundColor = UIColor.clear
        
        let colors = Colors()
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
        
    }
    
    func setupGestureRecognizers() {
        let addTap = UITapGestureRecognizer(target: self, action: #selector(addTapped))
        addIconImageView.addGestureRecognizer(addTap)
        addIconImageView.isUserInteractionEnabled = true
    }
    
    @objc func addTapped() {
        delegate?.addTapped()
        createQueueForm.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.createQueueForm.alpha = 1
        }
        createQueueForm.queueNameTextField.becomeFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController
        {
            let vc = segue.destination as? MapController
            vc?.delegate = self
            self.delegate = vc
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createQueueForm.queueNameTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.3, animations: {
            self.createQueueForm.alpha = 0
        }) { (val) in
            self.createQueueForm.isHidden = true
        }
        
        createQueue(withName: createQueueForm.queueNameTextField.text ?? "")
        
        return true
    }
    
    func createQueue(withName name: String) {
        let coords = delegate?.getCoords()
        
        var ref : DocumentReference? = nil
        ref = db?.collection("location").addDocument(data: [
            "lat" : coords?["lat"] ?? 0,
            "long" : coords?["long"] ?? 0,
            "city": "",
            "region": "",
            "numMembers": "",
            "currentSong": "",
            "name" : name
        ]) { (val) in
            let id = ref!.documentID
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            
            let vc = storyBoard.instantiateViewController(withIdentifier: "queueViewController") as! QueueViewController
            vc.queueName = self.createQueueForm.queueNameTextField.text
            vc.queueId = id
            
            
            
            self.present(vc, animated:true, completion:nil)
        }
    }

}

class Colors {
    var gl:CAGradientLayer!
    var gl1:CAGradientLayer!
    
    init() {
        let colorTop = UIColor(red: 166.0 / 255.0, green: 166.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 146.0 / 255.0, green: 160.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl.colors = [colorTop, colorBottom]
        self.gl.locations = [0.0, 1.0]
        
        self.gl1 = CAGradientLayer()
        self.gl1.colors = [colorBottom, colorTop]
        self.gl1.locations = [0.0, 1.0]
    }
}
