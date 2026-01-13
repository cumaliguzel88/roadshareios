//
//  RoadViewModel.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import MapKit
import Combine

// MARK: - RoadViewModel
/// Road sayfasının ViewModel'i
/// Konum servisi ile harita state'ini yönetir
@MainActor
final class RoadViewModel: ObservableObject {
    
    // MARK: - Published Properties
    /// Harita kamera pozisyonu
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    // MARK: - Dependencies
    let locationService: LocationService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(locationService: LocationService) {
        self.locationService = locationService
        setupBindings()
        requestLocationPermission()
    }
    
    // MARK: - Private Methods
    
    /// Konum servisindeki değişiklikleri dinle
    private func setupBindings() {
        // Konum güncellendiğinde kamerayı kullanıcıya odakla
        locationService.$currentLocation
            .compactMap { $0 }
            .first() // Sadece ilk konum için zoom yap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.centerOnUserLocation(location)
            }
            .store(in: &cancellables)
    }
    
    /// Konum izni iste
    private func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    /// Kamerayı kullanıcı konumuna odakla
    private func centerOnUserLocation(_ location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(region)
        }
        
        #if DEBUG
        print("🗺️ Camera centered on user: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        #endif
    }
}
