//
//  Backgrounder.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 20/8/25.
//

import CoreLocation

class Backgrounder: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Location persistence started")
    }
    
    func startBackgroundLocation() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
        print("Started background location")
    }
    
    func stopBackgroundLocation() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        print("Stopped backgrounding")
    }
    
    func requestPermissionsForBackgrounding() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermissionsForBackgrounding() {
        manager.requestAlwaysAuthorization()
    }
    
    func checkPermissionsStatus() -> String {
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .denied, .restricted:
            return "Denied"
        case .authorizedWhenInUse:
            return "Partial"
        case .authorizedAlways:
            return "Full"
        case .notDetermined:
            return "Denied"
        @unknown default:
            return "Denied"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            print("no access given")
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("access fully granted!")
        case .notDetermined:
            print("user still deciding")
        @unknown default:
            print("kanfusion")
        }
    }
}

