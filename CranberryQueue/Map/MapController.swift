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
    var circles = [TCCircle]()
    
    var locations: [String: [String: Any]] = [:]
    var isFirstLoad = true
    var queueId: String? = nil
    var region: String? = nil
    var city: String? = nil
    
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
            if(self.curZoom > 10)   {
                if self.city != city {
                    self.removeAllLocations()
                    self.getTopQueuesInCity(city: city, region: region)
                }
            } else {
                if self.region != region {
                    self.removeAllLocations()
                    self.getTopQueuesInState(region: region, zoom: self.curZoom)
                }
            }
            self.mapControllerDelegate?.updateGeoCode(city: city, region: region)
            self.city = city
            self.region = region
        }
    }
    // this alters the color of a marker
    // called when leaveQueue is tapped and when a user joins a queue
    func colorMarker(_ homeColor: Bool?, _ queueId: String?) {
        //access the queue in hash
        let marker = locations[queueId!]!["marker"] as! GMSMarker
        if homeColor! {
            marker.icon = GMSMarker.markerImage(with: UIColor.green)
        } else {
            marker.icon = GMSMarker.markerImage(with: UIColor(displayP3Red: 145/255, green: 158/255, blue: 188/255, alpha: 1))
        }
    }
    
    // when a locations data is modifed ex: numMembers or currentSong
    func modifyLocation(diff: DocumentChange) {
        let data = diff.document.data()
        let updatedLoc = CQLocation(
            name: data["name"] as! String,
            city:  data["city"] as! String,
            region:  data["region"] as! String,
            long:  data["long"] as! Double,
            lat:  data["lat"] as! Double,
            queueId: diff.document.documentID,
            numMembers: data["numMembers"] as! Int
        )
        let docId = diff.document.documentID
        locations[docId]!["location"] = updatedLoc
    }
    
    // add a new location to the locations dictionary, keyed by queueId
    func addLocation(diff: DocumentChange) {
        let data = diff.document.data()
        let newLoc = CQLocation(
            name: data["name"] as! String,
            city:  data["city"] as! String,
            region:  data["region"] as! String,
            long:  data["long"] as! Double,
            lat:  data["lat"] as! Double,
            queueId: diff.document.documentID,
            numMembers:data["numMembers"] as! Int
        )
        let docId = diff.document.documentID
        locations[docId] = ["location": newLoc]
        self.drawMarker(location: newLoc)
    }
    
    // remove a location from dict, also removes the circle and marker on the map
    func removeLocation(diff: DocumentChange) {
        let docId = diff.document.documentID
        let circle = locations[docId]!["circle"] as! TCCircle
        circle.fillColor = UIColor(red: 180/255, green: 0/255, blue: 0/255, alpha: 0.3)
        let marker = locations[docId]!["marker"] as! GMSMarker
        circle.removeCircleAnimation(from: 200, duration: 2, completion: {
            marker.map = nil
        })
        // remove entire key from dictionary
        locations[docId] = nil
    }
    
    // draw a marker and circle at a given location
    func drawMarker(location: CQLocation) {
        let circleCenter = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
        // class that allows creation animation
        let circle = TCCircle(position: circleCenter, radius: 0.0)
        let defaultColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.3)
        let homeColor = UIColor(displayP3Red: 189/255, green: 209/255, blue: 199/255, alpha: 0.7)
        circle.fillColor = location.queueId == self.queueId ? homeColor : defaultColor
        let position = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
        let marker = GMSMarker(position: position)
        circle.beginCircleAnimation(to: 200.0, duration: 2, completion: {
           //popup animation for markers
           marker.appearAnimation = GMSMarkerAnimation.pop
           marker.icon = location.queueId == self.queueId ? GMSMarker.markerImage(with: UIColor.green) : GMSMarker.markerImage(with: UIColor(displayP3Red: 145/255, green: 158/255, blue: 188/255, alpha: 1))
           marker.title = location.name
           marker.map = self.map
           marker.userData = location
        })
        circle.strokeColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.5)
        circle.strokeWidth = 2
        circle.zIndex = 0
        circle.map = map
        locations[location.queueId]!["marker"] = marker
        locations[location.queueId]!["circle"] = circle
    }
    
    // this function takes in an array of document changes and handles them accordingly
    func processDocumentChanges(documentChanges: [DocumentChange]) {
        documentChanges.forEach { diff in
            if (diff.type == .added) {
                self.addLocation(diff: diff)
            }
            if (diff.type == .modified) {
               self.modifyLocation(diff: diff)
            }
            if (diff.type == .removed) {
               self.removeLocation(diff: diff)
            }
        }
    }
    
    // this function iterates over the locations dictionary and removes all of them
    func removeAllLocations() {
        let keys = Array(locations.keys)
        for key in keys {
            let circle = locations[key]!["circle"] as! TCCircle
            circle.fillColor = UIColor(red: 180/255, green: 0/255, blue: 0/255, alpha: 0.3)
            let marker = locations[key]!["marker"] as! GMSMarker
            circle.removeCircleAnimation(from: 200, duration: 2, completion: {
               marker.map = nil
            })
            locations[key] = nil
        }
    }
    
    func getTopQueuesInCity(city: String, region: String) {
        queuesInLocationRef?.remove()
        queuesInLocationRef = db?.collection("location").whereField("city", isEqualTo: city).whereField("region", isEqualTo: region).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print("watch location err: ", error!)
                return
            }
            // handle the incoming document changes
            self.processDocumentChanges(documentChanges: snap.documentChanges)
        })
    }
    
    func getTopQueuesInState(region: String, zoom: Float) {
        let queueLimitFromZoom = (1/zoom)*150
        queuesInLocationRef?.remove()
        queuesInLocationRef = db?.collection("location").whereField("numMembers", isGreaterThan: 0).whereField("region", isEqualTo: region).order(by: "numMembers", descending: true).limit(to: Int(queueLimitFromZoom)).addSnapshotListener({ (snapshot, error) in
            guard let snap = snapshot else {
                print("watch location err: ", error!)
                return
            }
            // handle the incoming document changes
            self.processDocumentChanges(documentChanges: snap.documentChanges)
        })
    }
    
    func setCircle (_ circle : TCCircle) {
        circle.strokeColor = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.5)
        circle.strokeWidth = 2
        circle.zIndex = 0
        circle.map = map
        circles.append(circle)
    }
    
    // class that removes locations from the map one at a time, rather than clearing everything
    func removeLocations(queues: [CQLocation]) {
        for queue in queues {
            let dex = self.queues.firstIndex(where: {$0.queueId == queue.queueId})!
            let circle = circles[dex]
            circle.fillColor = UIColor(red: 180/255, green: 0/255, blue: 0/255, alpha: 0.3)
            let marker = self.markers[dex]
            markers.remove(at: dex)
            circles.remove(at: dex)
            self.queues.remove(at: dex)
            circle.removeCircleAnimation(from: 200, duration: 2, completion: {
                UIView.animate(withDuration: 2, animations: {
                    marker.opacity = 0
                }) { (_) in
                    marker.map = nil
                }
            })
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
        mapView(map!, idleAt: GMSCameraPosition(latitude: center.latitude, longitude: center.longitude, zoom: 14))
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
    
    func setQueue(_ queueId: String?) {
        self.queueId = queueId
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

class TCCircle : GMSCircle {
    var duration : TimeInterval!
    var begin : NSDate!
    var to : CLLocationDistance = 0.0
    var from : CLLocationDistance = 0.0
    var completion: (() -> Void)? = nil
    
    func beginCircleAnimation(to: CLLocationDistance, duration: TimeInterval, completion: @escaping () -> Void ) {
        self.to = to
        self.completion = completion
        self.duration = duration
        self.begin = NSDate()
        self.performSelector(onMainThread: #selector(expandRadius), with: nil, waitUntilDone: false)
  }
    
    func removeCircleAnimation(from: CLLocationDistance, duration: TimeInterval, completion: @escaping () -> Void ) {
          self.from = from
          self.completion = completion
          self.duration = duration
          self.begin = NSDate()
          self.performSelector(onMainThread: #selector(shrinkRadius), with: nil, waitUntilDone: false)
    }

    @objc func expandRadius() {
        let i : TimeInterval = NSDate().timeIntervalSince(self.begin as Date)
        
        if (i >= self.duration) {
            self.radius = self.to
            completion!()
            return
        } else {
            let dex = (i/duration)
            let d = to * ((dex*dex)/(2*(dex*dex-dex)+1))
            self.radius = d
            self.performSelector(onMainThread: #selector(expandRadius), with: nil, waitUntilDone: false)
        }
    }
    
    @objc func shrinkRadius() {
        let i : TimeInterval = NSDate().timeIntervalSince(self.begin as Date)
        if (i >= self.duration) {
            self.radius = 0
            completion?()
            return
        } else {
            let dex = (i/duration)
            let d = from * ((dex*dex)/(2*(dex*dex-dex)+1))
            self.radius = from - d
            self.performSelector(onMainThread: #selector(shrinkRadius), with: nil, waitUntilDone: false)
        }
    }
}
