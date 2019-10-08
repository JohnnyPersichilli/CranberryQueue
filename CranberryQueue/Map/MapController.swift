//
//  MapController.swift
//  CranberryQueue
//
//  Created by Rolf Locher on 9/13/19.
//  Copyright © 2019 Rolf Locher. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

protocol mapDelegate: class {
    func updateGeoCode(city: String, region: String)
    //func joinQueue(data: CQLocation)
    func openDetailModal(data: CQLocation)
    func joinQueue(data: CQLocation)
    func setLocationEnabled(status: Bool)
}

class MapController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, mapControllerDelegate {
    
    weak var delegate: mapDelegate?
    
    var db: Firestore? = nil
    var queuesInLocationRef: ListenerRegistration? = nil
    
    var locationManager : CLLocationManager!
    
    var map: GMSMapView? = nil

    var queues = [CQLocation]()
    var markers = [GMSMarker]()
    
    var curCoords: CLLocationCoordinate2D? = nil
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layer.borderWidth = 1
        
        db = Firestore.firestore()
    }
     
    override func viewWillDisappear(_ animated: Bool) {
        queuesInLocationRef?.remove()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isFirstLoad {
            isFirstLoad = false
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func enableLocation(){
        
    }
    
    func disableLocation() {
        
    }
    
//    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
//        delegate?.joinQueue(data: marker.userData as! CQLocation)
//    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("called did tap marker")
        delegate?.openDetailModal(data: marker.userData as! CQLocation)
        return true
    }

    func watchLocationQueues(city: String, region: String) {
        queuesInLocationRef = db?.collection("location").whereField("city", isEqualTo: city).whereField("region", isEqualTo: region).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print(error!)
                return
            }
            self.map!.clear()
            self.markers = []
            self.queues = []
            for doc in snap.documents {
                let newLoc = CQLocation(
                    name: doc.data()["name"] as! String,
                    city: doc.data()["city"] as! String,
                    region: doc.data()["region"] as! String,
                    long: doc.data()["long"] as! Double,
                    lat: doc.data()["lat"] as! Double,
                    queueId: doc.documentID)
                self.queues.append(newLoc)
            }
            self.drawMarkers()
            
        })
    }
    
    func drawMarkers() {
        for queue in queues {
            let position = CLLocationCoordinate2D(latitude: queue.lat, longitude: queue.long)
            let marker = GMSMarker(position: position)
            marker.title = queue.name
            marker.snippet = "Tap Here to Join"
            marker.map = map
            marker.userData = queue
            self.markers.append(marker)
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
        map?.delegate = self
        
        DispatchQueue.main.async {
            self.view = mapView0
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var isEnabled = Bool()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isEnabled = true
        default:
            isEnabled = false
        }
        delegate?.setLocationEnabled(status: isEnabled)
        UserDefaults.standard.set(isEnabled, forKey: "isLocationEnabled")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        
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
            self.watchLocationQueues(city: res[0].locality!, region: res[0].administrativeArea!)
        }
    }
    
    func getCoords() -> ([String : Double]) {
        return [
            "long": curCoords?.longitude ?? 0,
            "lat": curCoords?.latitude ?? 0
        ]
    }
    
    func addTapped() {
        let marker = GMSMarker()
        marker.position = curCoords!
        marker.map = map
    }
    
}
