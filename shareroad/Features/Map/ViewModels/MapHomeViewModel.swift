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
    
    // MARK: - Vehicle State
    @Published var nearbyVehicles: [Vehicle] = []
    @Published var isLoadingVehicles: Bool = false
    private var movementTimer: Timer?
    
    // MARK: - Dependencies
    let locationService: LocationService
    private let vehicleService = NearbyVehiclesService()
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
        // İlk konum geldiğinde araçları yükle
        locationService.$currentLocation
            .compactMap { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self else { return }
                self.userLocation = location.coordinate
                self.centerOnUserLocation(location)
                
                // Araçları yükle (0.5s gecikmeli)
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.loadNearbyVehicles(around: location)
                    
                    // Animasyonları başlat (2s gecikmeli)
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        self.startVehicleAnimations()
                    }
                }
            }
            .store(in: &cancellables)
            
        // Sürekli konum güncellemeleri
        locationService.$currentLocation
            .compactMap { $0?.coordinate }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.userLocation = coordinate
            }
            .store(in: &cancellables)
    }
    
    /// Yakındaki araçları yükle
    private func loadNearbyVehicles(around location: CLLocation) async {
        guard !isLoadingVehicles else { return }
        
        isLoadingVehicles = true
        let vehicles = await vehicleService.generateVehicles(around: location, count: 9)
        
        withAnimation {
            self.nearbyVehicles = vehicles
        }
        isLoadingVehicles = false
        
        #if DEBUG
        print("🚕 Loaded \(vehicles.count) nearby vehicles")
        #endif
    }
    
    // MARK: - Animation Logic
    
    /// Araç animasyonlarını başlatır
    func startVehicleAnimations() {
        // Timer zaten varsa başlatma
        guard movementTimer == nil else { return }
        
        // Timer interval: 2 saniye (Sürekli akış, hiç bekleme yok)
        movementTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.animateRandomVehicles()
            }
        }
    }
    
    /// Araç animasyonlarını durdurur
    func stopVehicleAnimations() {
        movementTimer?.invalidate()
        movementTimer = nil
    }
    
    /// Rastgele araçları hareket ettirir
    private func animateRandomVehicles() {
        guard !nearbyVehicles.isEmpty else { return }
        
        // Rastgele 1 araç seç (Her 2 saniyede bir, tek tek kalksınlar)
        let numberOfVehiclesToMove = 1
        // Eğer toplam araç sayısı azsa hepsini hareket ettir
        let count = min(numberOfVehiclesToMove, nearbyVehicles.count)
        
        // Rastgele indeksler seç (Set kullanarak uniqueness sağla)
        var selectedIndices = Set<Int>()
        while selectedIndices.count < count {
            selectedIndices.insert(Int.random(in: 0..<nearbyVehicles.count))
        }
        
        for index in selectedIndices {
            animateVehicle(at: index)
        }
    }
    
    /// Belirtilen indeksteki aracı hareket ettirir
    private func animateVehicle(at index: Int) {
        guard index < nearbyVehicles.count else { return }
        
        let vehicle = nearbyVehicles[index]
        let newCoordinate = vehicleService.generateRandomNearbyCoordinate(from: vehicle.coordinate)
        
        // Rotasyon hesapla
        let newBearing = calculateBearing(from: vehicle.coordinate, to: newCoordinate)
        
        // Çok YAVAŞ akış (40-60 saniye)
        // Kısa mesafeyi çok uzun sürede alacaklar -> Çok düşük hız
        let duration = Double.random(in: 40.0...60.0)
        
        // SwiftUI Animation ile koordinat ve rotasyon güncelle
        withAnimation(.linear(duration: duration)) {
            nearbyVehicles[index].coordinate = newCoordinate
            nearbyVehicles[index].bearing = newBearing
        }
    }
    
    /// İki nokta arasındaki açıyı (bearing) hesaplar
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var bearing = atan2(y, x) * 180 / .pi
        
        // Normalize: 0-360
        if bearing < 0 {
            bearing += 360
        }
        
        return bearing
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
