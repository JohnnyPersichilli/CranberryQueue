//
//  ViewController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager : CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScreen()
        setupLocation()
        
    }
    
    func setupLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupScreen() {
        self.navigationController?.isNavigationBarHidden = true
        //self.navigationController?.isToolbarHidden = true
        
        view.backgroundColor = UIColor.clear
        
        let colors = Colors()
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //self.mapView.setRegion(region, animated: true)
        
        self.locationManager.stopUpdatingLocation()
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
