//
//  MapController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import GoogleMaps

protocol mapDelegate: class {
    func updateGeoCode(city: String, region: String)
}

class MapController: UIViewController, CLLocationManagerDelegate, mapControllerDelegate {

    weak var delegate: mapDelegate?
    
    var locationManager : CLLocationManager!
    
    var map: GMSMapView? = nil
    
    var curCoords: CLLocationCoordinate2D? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocation()
        
        self.view.layer.borderWidth = 1
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
    
    func setupMap(withCoords coords: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withTarget: coords, zoom: 13.0)
        let mapView0 = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView0.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        mapView0.isMyLocationEnabled = true
        map = mapView0
        
        DispatchQueue.main.async {
            self.view = mapView0
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        print(center)
        
        curCoords = center
        
        setupMap(withCoords: center)
        getGeoCode(withLocation: location!)
        
        self.locationManager.stopUpdatingLocation()
    }
    
    func getGeoCode(withLocation loc: CLLocation) {
        let coder = CLGeocoder()
        coder.reverseGeocodeLocation(loc) { (marks, error) in
            guard let res = marks else {
                print(error!)
                return
            }
            self.delegate?.updateGeoCode(city: res[0].locality!, region: res[0].administrativeArea!)
        }
        
    }
    
    func addTapped() {
        print("yes")
        
        let marker = GMSMarker()
        marker.position = curCoords!
        marker.map = map
    }
    
    func createQueue() {
        
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
