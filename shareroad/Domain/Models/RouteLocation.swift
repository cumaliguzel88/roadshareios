//
//  RouteLocation.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import CoreLocation

// MARK: - RouteLocation Model
/// Başlangıç veya varış noktasını temsil eden konum modeli
struct RouteLocation: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    // Equatable conformance
    static func == (lhs: RouteLocation, rhs: RouteLocation) -> Bool {
        lhs.id == rhs.id
    }
}
