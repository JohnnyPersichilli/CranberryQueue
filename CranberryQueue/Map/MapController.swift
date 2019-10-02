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
    func joinQueue(data: CQLocation)
}

class MapController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, mapControllerDelegate {
    
    weak var delegate: mapDelegate?
    
    var db: Firestore? = nil
    var queuesInLocationRef: ListenerRegistration? = nil
    
    var locationManager : CLLocationManager!
    
    var map: GMSMapView? = nil
    
    var curCoords: CLLocationCoordinate2D? = nil
    
    var queues = [CQLocation]()
    
    var markers = [GMSMarker]()
    
    var uid = String()
    
    var queueId: String? = nil
    var isHost: Bool = false
    
    var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layer.borderWidth = 1
        
        db = Firestore.firestore()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isFirstLoad {
            isFirstLoad = false
            setupLocation()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        queuesInLocationRef?.remove()
    }
    
    func setUID(id: String) {
        uid = id
    }
    
    func setQueueInfo(queueId: String, isHost: Bool){
        self.queueId = queueId
        self.isHost = isHost
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        delegate?.joinQueue(data: marker.userData as! CQLocation)
    }
    
//    func updatePlayerWith(queueId: String?, isHost: Bool) {
//        delegate?.updatePlayerWith(queueId: queueId, isHost: isHost)
//    }
    
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
        map?.delegate = self
        
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
