//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit

class MapViewController: UIViewController, mapDelegate {
    
    @IBOutlet var cityLabel: UILabel!
    
    @IBOutlet var regionLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScreen()
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is MapController
        {
            let vc = segue.destination as? MapController
            vc?.delegate = self
        }
    }

}

class Colors {
    var gl:CAGradientLayer!
    
    init() {
        let colorTop = UIColor(red: 166.0 / 255.0, green: 166.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 146.0 / 255.0, green: 160.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl.colors = [colorTop, colorBottom]
        self.gl.locations = [0.0, 1.0]
    }
}
