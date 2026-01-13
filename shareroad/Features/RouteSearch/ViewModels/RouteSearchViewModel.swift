//
//  RouteSearchViewModel.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import Combine
import CoreLocation

// MARK: - Field Enum
enum RouteField: Equatable, Hashable {
    case pickup
    case stop(Int) // 0, 1, 2 for up to 3 stops
    case destination
}

// MARK: - RouteSearchViewModel
@MainActor
final class RouteSearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Başlangıç noktası
    @Published var pickupLocation: RouteLocation?
    
    /// Varış noktası
    @Published var destinationLocation: RouteLocation?
    
    /// Duraklar (en fazla 3)
    @Published var stops: [RouteLocation?] = []
    
    /// Pickup text field değeri
    @Published var pickupText: String = ""
    
    /// Destination text field değeri
    @Published var destinationText: String = ""
    
    /// Durak text değerleri
    @Published var stopTexts: [String] = []
    
    /// Arama sonuçları
    @Published var searchResults: [RouteLocation] = []
    
    /// Son aramalar (UserDefaults'tan)
    @Published var recentSearches: [RouteLocation] = []
    
    /// Favoriler (UserDefaults'tan)
    @Published var favoriteLocations: [RouteLocation] = []
    
    /// Yükleniyor durumu
    @Published var isLoading: Bool = false
    
    /// Aktif olarak hangi field'da arama yapılıyor
    @Published var activeField: RouteField = .destination
    
    /// Favoriler bölümü açık mı?
    @Published var showFavorites: Bool = false
    
    /// Durak uyarısı göster
    @Published var showStopLimitWarning: Bool = false
    
    // MARK: - Private Properties
    
    private let searchService = LocationSearchService()
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    private let stopSearchSubject = PassthroughSubject<(Int, String), Never>()
    
    /// UserDefaults keys
    private let recentSearchesKey = "com.shareroad.recentSearches"
    private let favoritesKey = "com.shareroad.favorites"
    
    /// Maximum number of stops
    let maxStops = 3
    
    // MARK: - Init
    
    init() {
        loadRecentSearches()
        loadFavorites()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Pickup text değişikliklerini dinle (debounce ile)
        $pickupText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard self?.activeField == .pickup else { return }
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
        
        // Destination text değişikliklerini dinle (debounce ile)
        $destinationText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard self?.activeField == .destination else { return }
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
            
        // Stop text değişikliklerini dinle (debounce ile)
        stopSearchSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] (index, query) in
                guard let self = self,
                      case .stop(let activeIndex) = self.activeField,
                      activeIndex == index else { return }
                self.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Durak metnini güncelle ve arama yap
    func updateStopText(at index: Int, text: String) {
        guard stopTexts.indices.contains(index) else { return }
        stopTexts[index] = text
        stopSearchSubject.send((index, text))
    }
    
    /// Kullanıcının mevcut konumunu pickup olarak ayarla (tam adresle)
    func setUserLocation(_ location: CLLocation) {
        // Önce koordinatları kaydet
        pickupLocation = RouteLocation(
            title: "route.pickup.my_location".localized,
            subtitle: "",
            coordinate: location.coordinate
        )
        
        // Reverse geocoding ile tam adresi al
        Task {
            if let address = await reverseGeocode(location: location) {
                pickupLocation = RouteLocation(
                    title: address,
                    subtitle: "",
                    coordinate: location.coordinate
                )
                pickupText = address
            } else {
                pickupText = "route.pickup.my_location".localized
            }
        }
    }
    
    /// Reverse geocoding ile koordinatı adrese çevir
    private func reverseGeocode(location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            
            var addressParts: [String] = []
            
            // Mahalle
            if let subLocality = placemark.subLocality {
                addressParts.append(subLocality)
            }
            
            // Cadde/Sokak
            if let thoroughfare = placemark.thoroughfare {
                addressParts.append(thoroughfare)
            }
            
            // Kapı numarası
            if let subThoroughfare = placemark.subThoroughfare {
                addressParts.append("No. \(subThoroughfare)")
            }
            
            return addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")
        } catch {
            #if DEBUG
            print("⚠️ Reverse geocoding error: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    
    /// Pickup ve Destination'ı yer değiştir
    func swapLocations() {
        // Swap locations
        let tempLocation = pickupLocation
        pickupLocation = destinationLocation
        destinationLocation = tempLocation
        
        // Swap texts
        let tempText = pickupText
        pickupText = destinationText
        destinationText = tempText
    }
    
    /// Durak ekle (en fazla 3)
    func addStop() {
        if stops.count < maxStops {
            stops.append(nil)
            stopTexts.append("")
        } else {
            showStopLimitWarning = true
            // 2 saniye sonra uyarıyı kapat
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showStopLimitWarning = false
            }
        }
    }
    
    /// Durak kaldır
    func removeStop(at index: Int) {
        guard index >= 0 && index < stops.count else { return }
        stops.remove(at: index)
        stopTexts.remove(at: index)
    }
    
    /// Arama sonuçlarından bir sonuç seç
    func selectResult(_ result: RouteLocation, for field: RouteField) {
        switch field {
        case .pickup:
            pickupLocation = result
            pickupText = result.title
        case .stop(let index):
            if index < stops.count {
                stops[index] = result
                stopTexts[index] = result.title
            }
        case .destination:
            destinationLocation = result
            destinationText = result.title
        }
        
        // Arama sonuçlarını temizle
        searchResults = []
        
        // "Konumum" değilse son aramalara ekle
        if result.title != "route.pickup.my_location".localized &&
           result.title != "Konumum" &&
           result.title != "My Location" {
            addToRecentSearches(result)
        }
    }
    
    /// Arama sonuçlarını temizle
    func clearSearchResults() {
        searchResults = []
    }
    
    /// Son aramaları temizle
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
    
    /// Konumu favorilere ekle/çıkar
    func toggleFavorite(_ location: RouteLocation) {
        if let index = favoriteLocations.firstIndex(where: { $0.id == location.id }) {
            // Zaten favori, çıkar
            favoriteLocations.remove(at: index)
        } else {
            // Favorilere ekle
            favoriteLocations.insert(location, at: 0)
        }
        saveFavorites()
    }
    
    /// Konum favori mi kontrol et
    func isFavorite(_ location: RouteLocation) -> Bool {
        return favoriteLocations.contains { $0.id == location.id }
    }
    
    /// Favorileri göster/gizle toggle
    func toggleShowFavorites() {
        showFavorites.toggle()
    }
    
    // MARK: - Private Methods
    
    /// Arama yap
    private func performSearch(query: String) {
        // Önceki aramayı iptal et
        searchTask?.cancel()
        
        // Minimum karakter kontrolü
        guard query.count >= 4 else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            isLoading = true
            
            do {
                let results = try await searchService.search(query: query)
                
                // Task iptal edilmediyse sonuçları güncelle
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                #if DEBUG
                print("⚠️ Search error: \(error.localizedDescription)")
                #endif
                searchResults = []
            }
            
            isLoading = false
        }
    }
    
    /// UserDefaults'tan son aramaları yükle
    private func loadRecentSearches() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let searches = try? JSONDecoder().decode([RouteLocation].self, from: data) else {
            return
        }
        // "Konumum" olanları filtrele
        recentSearches = searches.filter {
            $0.title != "route.pickup.my_location".localized &&
            $0.title != "Konumum" &&
            $0.title != "My Location"
        }
    }
    
    /// Son aramalara ekle (max 10)
    private func addToRecentSearches(_ location: RouteLocation) {
        // "Konumum" ise ekleme
        if location.title == "route.pickup.my_location".localized ||
           location.title == "Konumum" ||
           location.title == "My Location" {
            return
        }
        
        // Zaten varsa çıkar (duplicate önleme)
        recentSearches.removeAll { $0.id == location.id }
        
        // Başa ekle
        recentSearches.insert(location, at: 0)
        
        // Max 10 tut
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        // UserDefaults'a kaydet
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }
    
    /// Favorileri yükle
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let favorites = try? JSONDecoder().decode([RouteLocation].self, from: data) else {
            return
        }
        favoriteLocations = favorites
    }
    
    /// Favorileri kaydet
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteLocations) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
}
