//
//  MapHomeViewModel.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import MapKit
import Combine

// MARK: - PaymentMethod Enum
/// Ödeme yöntemi seçenekleri
enum PaymentMethod: String, CaseIterable {
    case cash = "payment.cash"
    case pos = "payment.pos"
    
    /// Localized gösterim metni
    var displayName: String {
        rawValue.localized
    }
}

// MARK: - TaxiType Enum
/// Taksi tipi seçenekleri
enum TaxiType: String, CaseIterable, Identifiable {
    case yellow = "yellow"
    case turquoise = "turquoise"
    
    var id: String { rawValue }
    
    /// Taksi ismi (localized)
    var name: String {
        switch self {
        case .yellow: return "ride.vehicle.yellow_taxi".localized
        case .turquoise: return "ride.vehicle.turquoise_taxi".localized
        }
    }
    
    /// Taksi açıklaması (localized)
    var description: String {
        switch self {
        case .yellow: return "ride.vehicle.description.fast".localized
        case .turquoise: return "ride.vehicle.description.comfort".localized
        }
    }
    
    /// Kapasite
    var capacity: Int {
        switch self {
        case .yellow: return 4
        case .turquoise: return 8
        }
    }
    
    /// Tahmini bekleme süresi (dakika)
    var estimatedTime: Int {
        switch self {
        case .yellow: return 1
        case .turquoise: return 8
        }
    }
    
    /// İkon ismi (Assets.xcassets)
    var iconName: String {
        switch self {
        case .yellow: return "taxi"
        case .turquoise: return "turkuaz"
        }
    }
    
    /// Accent rengi
    var accentColor: Color {
        switch self {
        case .yellow: return .orange
        case .turquoise: return .cyan
        }
    }
}

// MARK: - MapHomeViewModel
/// MapHomeView için state yönetimi
/// Şimdilik sadece UI state'leri, backend entegrasyonu sonra eklenecek
@MainActor
final class MapHomeViewModel: ObservableObject {
    
    // MARK: - Search State
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    
    // MARK: - Map State
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // İstanbul
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
    )
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var destinationLocation: CLLocationCoordinate2D?
    
    // MARK: - Selection State
    @Published var selectedTaxiType: TaxiType = .yellow
    @Published var selectedPaymentMethod: PaymentMethod = .cash
    @Published var isDropdownOpen: Bool = false
    
    // MARK: - Dependencies
    let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Yolculuk oluşturma butonu aktif mi?
    var canCreateRide: Bool {
        // Şimdilik her zaman aktif, backend entegrasyonunda değişecek
        true
    }
    
    // MARK: - Init
    init(locationService: LocationService) {
        self.locationService = locationService
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /// Konum servisini dinle
    private func setupBindings() {
        locationService.$currentLocation
            .compactMap { $0?.coordinate }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.userLocation = coordinate
            }
            .store(in: &cancellables)
        
        // İlk konumu aldığında haritayı oraya odakla
        locationService.$currentLocation
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.centerOnUserLocation(location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Konum butonuna basıldığında
    func centerOnUser() {
        guard let location = locationService.currentLocation else {
            locationService.requestLocationPermission()
            return
        }
        centerOnUserLocation(location)
    }
    
    /// Dropdown toggle
    func toggleDropdown() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isDropdownOpen.toggle()
        }
    }
    
    /// Ödeme yöntemi seç
    func selectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod = method
        withAnimation(.easeInOut(duration: 0.2)) {
            isDropdownOpen = false
        }
    }
    
    /// Taksi tipi seç
    func selectTaxiType(_ type: TaxiType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTaxiType = type
        }
    }
    
    /// Yolculuk oluştur (şimdilik placeholder)
    func createRide() {
        #if DEBUG
        print("🚕 Create ride tapped - Taxi: \(selectedTaxiType.name), Payment: \(selectedPaymentMethod.displayName)")
        #endif
        // Backend entegrasyonu sonra eklenecek
    }
    
    // MARK: - Private Helpers
    
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
        print("🗺️ Camera centered: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        #endif
    }
}
