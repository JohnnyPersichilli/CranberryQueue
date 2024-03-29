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

protocol MapControllerDelegate: class {
    func updateGeoCode(city: String, region: String)
    func updateCanRecenter(val: Bool)
    func toggleDetailModal(withData data: CQLocation)
    func setLocationEnabled(status: Bool)
}

class MapController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, ControllerMapDelegate {
    
    weak var mapControllerDelegate: MapControllerDelegate?
    
    var db: Firestore? = nil
    var queuesInLocationRef: ListenerRegistration? = nil
    
    var locationManager : CLLocationManager!
    var map: GMSMapView? = nil
    
    var curCoords: CLLocationCoordinate2D? = nil
    var curZoom: Float = 15.0
    
    var queues = [CQLocation]()
    var markers = [GMSMarker]()
    var circles = [GMSCircle]()
    
    var isFirstLoad = true
    var queueId: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layer.borderWidth = 1        
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
    
    func setLocationEnabled(_ val: Bool){
        self.map?.isMyLocationEnabled = val
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        mapControllerDelegate?.toggleDetailModal(withData: marker.userData as! CQLocation)
        return true
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        curZoom = mapView.camera.zoom
        
        if let curCoords = curCoords {
            let recenterThreshold = 400.0
            let curCameraCoords = mapView.camera.target
            let canRecenter = getDistanceBetween(coordA: curCameraCoords, coordB: curCoords) > recenterThreshold
            mapControllerDelegate?.updateCanRecenter(val: canRecenter)
        }
        else {
            mapControllerDelegate?.updateCanRecenter(val: false)
        }
        
        let mapCenter = [
            "lat": mapView.camera.target.latitude,
            "long": mapView.camera.target.longitude
        ]
        getGeoCode(withLocation: mapCenter){ city, region in
            self.mapControllerDelegate?.updateGeoCode(city: city, region: region)
            self.watchLocationQueues(city: city, region: region)
        }
    }

    func watchLocationQueues(city: String, region: String) {
        if curZoom > 10 {
            getTopQueusInCity(city: city, region: region)
        } else {
            getTopQueusInState(region: region, zoom: curZoom)
        }
    }
    
    func getTopQueusInCity(city: String, region: String) {
        queuesInLocationRef?.remove()
        queuesInLocationRef = db?.collection("location").whereField("city", isEqualTo: city).whereField("region", isEqualTo: region).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print("watch location err: ", error!)
                return
            }
            self.map!.clear()
            self.markers = []
            self.circles = []
            self.queues = []
            for doc in snap.documents {
                let newLoc = CQLocation(
                    name: doc.data()["name"] as! String,
                    city: doc.data()["city"] as! String,
                    region: doc.data()["region"] as! String,
                    long: doc.data()["long"] as! Double,
                    lat: doc.data()["lat"] as! Double,
                    queueId: doc.documentID,
                    numMembers: doc.data()["numMembers"] as! Int
                )
                self.queues.append(newLoc)
            }
            self.drawMarkers()
        })
    }
    
    func getTopQueusInState(region: String, zoom: Float) {
        let queueLimitFromZoom = (1/zoom)*150
        queuesInLocationRef?.remove()
        queuesInLocationRef = db?.collection("location").whereField("numMembers", isGreaterThan: 0).whereField("region", isEqualTo: region).order(by: "numMembers", descending: true).limit(to: Int(queueLimitFromZoom)).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print("watch location err: ", error!)
                return
            }
            self.map!.clear()
            self.markers = []
            self.circles = []
            self.queues = []
            for doc in snap.documents {
                let newLoc = CQLocation(
                    name: doc.data()["name"] as! String,
                    city: doc.data()["city"] as! String,
                    region: doc.data()["region"] as! String,
                    long: doc.data()["long"] as! Double,
                    lat: doc.data()["lat"] as! Double,
                    queueId: doc.documentID,
                    numMembers: doc.data()["numMembers"] as! Int
                )
                self.queues.append(newLoc)
            }
            self.drawMarkers()
        })
    }
    
    func setCircle (_ circle : GMSCircle) {
        circle.strokeColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.5)
        circle.strokeWidth = 2
        circle.zIndex = 0
        circle.map = map
        circles.append(circle)
    }
    
    func drawMarkers() {
        for queue in queues {
            let circleCenter = CLLocationCoordinate2D(latitude: queue.lat, longitude: queue.long)
            let circle = GMSCircle(position: circleCenter, radius: 200)
            let defaultColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.3)
            let homeColor = UIColor(displayP3Red: 189/255, green: 209/255, blue: 199/255, alpha: 0.7)
            circle.fillColor = queue.queueId == self.queueId ? homeColor : defaultColor
            setCircle(circle)
            
            let position = CLLocationCoordinate2D(latitude: queue.lat, longitude: queue.long)
            let marker = GMSMarker(position: position)
            marker.icon = queue.queueId == self.queueId ? GMSMarker.markerImage(with: UIColor.green) : GMSMarker.markerImage(with: UIColor(displayP3Red: 145/255, green: 158/255, blue: 188/255, alpha: 1))
            marker.title = queue.name
            marker.snippet = "Tap Here to Join"
            marker.map = map
            marker.userData = queue
            self.markers.append(marker)
        }
    }
   
    func setupMap(withCoords coords: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withTarget: coords, zoom: 15.0)
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
        case .notDetermined:
            return
        default:
            isEnabled = false
        }
        mapControllerDelegate?.setLocationEnabled(status: isEnabled)
        UserDefaults.standard.set(isEnabled, forKey: "isLocationEnabled")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        
        curCoords = center
        
        setupMap(withCoords: center)
        getGeoCode(withLocation: ["lat": center.latitude, "long": center.longitude]){ city, region in
            self.mapControllerDelegate?.updateGeoCode(city: city, region: region)
            self.watchLocationQueues(city: city, region: region)
        }
        
        self.locationManager.stopUpdatingLocation()
    }
    
    func getGeoCode(withLocation loc: [String : Double], completion: @escaping (String, String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: loc["lat"]!, longitude: loc["long"]!)) { (marks, error) in
            guard let res = marks else {
                print("Geo code err:", error!)
                return
            }
            var city = String()
            var region = String()
            
            if let locality = res[0].locality {
                city = locality
            } else {
                city = String(Double(Int(loc["lat"]!*100))/100)
            }
                        
            if let administrativeArea = res[0].administrativeArea {
               region = administrativeArea
            } else {
               region = String(Double(Int(loc["long"]!*100))/100)
            }

            completion(city, region)
        }
    }

    func getCoords() -> ([String : Double]) {
        if let curLoc = map?.myLocation {
            curCoords = curLoc.coordinate
        }
        return [
            "long": curCoords?.longitude ?? 0,
            "lat": curCoords?.latitude ?? 0
        ]
    }
    
    func recenterMap() {
        let myCoords = getCoords()
        let camera = GMSCameraPosition.camera(withLatitude: myCoords["lat"]! ,longitude: myCoords["long"]! , zoom: 15.0)
        map!.animate(to: camera)
    }
    
    func addTapped() {
        markers = []
        circles = []
        self.map?.clear()
        
        let marker = GMSMarker()
        marker.icon = GMSMarker.markerImage(with: UIColor(displayP3Red: 145/255, green: 158/255, blue: 188/255, alpha: 1))
        marker.position = curCoords!
        marker.map = map
        markers.append(marker)
        
        let circle = GMSCircle(position: curCoords!, radius: 200)
        circle.fillColor = UIColor(displayP3Red: 189/255, green: 209/255, blue: 199/255, alpha: 0.7)
        setCircle(circle)
        
        self.drawMarkers()
    }
    
    func setQueue(_ queueId: String?) {
        self.queueId = queueId
        self.markers = []
        self.circles = []
        self.map?.clear()
        self.drawMarkers()
    }
    
    func getDistanceFrom(_ queue: CQLocation) -> Double {
        let myCoords = getCoords()
        let myLocation = CLLocation(
            latitude: myCoords["lat"]!,
            longitude: myCoords["long"]!
        )
        let queueLocation = CLLocation(
            latitude: queue.lat,
            longitude: queue.long
        )
        return myLocation.distance(from: queueLocation)
    }
    
    func getDistanceBetween(coordA: CLLocationCoordinate2D, coordB: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: coordA.latitude, longitude: coordA.longitude)
        let locB = CLLocation(latitude: coordB.latitude, longitude: coordB.longitude)
        return locA.distance(from: locB)
    }
        
}
