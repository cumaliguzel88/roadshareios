//
//  LocationSearchService.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import MapKit

// MARK: - LocationSearchService
/// Apple Maps MKLocalSearch wrapper
/// Türkiye sınırları içinde konum araması yapar
final class LocationSearchService {
    
    // MARK: - Constants
    
    /// Türkiye bounding box
    private let turkeyRegion: MKCoordinateRegion = {
        // Türkiye merkezi (yaklaşık Ankara)
        let center = CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0)
        // Geniş span (tüm Türkiye'yi kapsar)
        let span = MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 20.0)
        return MKCoordinateRegion(center: center, span: span)
    }()
    
    /// Minimum arama karakter sayısı
    private let minQueryLength = 4
    
    /// Maksimum sonuç sayısı
    private let maxResults = 15
    
    // MARK: - Public Methods
    
    /// Verilen sorgu ile konum araması yapar
    /// - Parameter query: Arama metni (min 4 karakter)
    /// - Returns: RouteLocation array
    func search(query: String) async throws -> [RouteLocation] {
        // Minimum karakter kontrolü
        guard query.count >= minQueryLength else { return [] }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = turkeyRegion
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        // Map items'ı RouteLocation'a dönüştür
        let results = response.mapItems.prefix(maxResults).map { mapItem -> RouteLocation in
            RouteLocation(
                title: mapItem.name ?? mapItem.placemark.title ?? "Bilinmeyen Konum",
                subtitle: formatSubtitle(from: mapItem.placemark),
                coordinate: mapItem.placemark.coordinate
            )
        }
        
        return Array(results)
    }
    
    // MARK: - Private Methods
    
    /// Placemark'tan okunabilir adres oluşturur
    private func formatSubtitle(from placemark: MKPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if components.isEmpty, let title = placemark.title {
            return title
        }
        
        return components.joined(separator: "/ ")
    }
}
