//
//  LocationService.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import CoreLocation
import Combine

// MARK: - LocationService Protocol
/// Konum servislerinin soyutlaması (test edilebilirlik için)
protocol LocationServiceProtocol: ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

// MARK: - LocationService
/// Kullanıcı konumunu yöneten ana servis
/// CLLocationManager wrapper - konum izni ve güncellemeler
final class LocationService: NSObject, LocationServiceProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    
    // MARK: - Init
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 metre değişimde güncelle
    }
    
    // MARK: - Public Methods
    
    /// Konum izni iste
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Konum güncellemelerini başlat
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Konum güncellemelerini durdur
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        #if DEBUG
        print("📍 Authorization status changed: \(authorizationStatus.rawValue)")
        #endif
        
        // İzin verildiğinde konum güncellemelerini başlat
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        #if DEBUG
        print("📍 User location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("❌ Location error: \(error.localizedDescription)")
        #endif
    }
}
