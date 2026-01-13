//
//  Vehicle.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import CoreLocation

// MARK: - Vehicle Model
/// Haritada gösterilecek araç modeli
struct Vehicle: Identifiable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let type: VehicleType
    let isAvailable: Bool
    
    // Equatable conformance for coordinate check
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

// MARK: - VehicleType Enum
enum VehicleType {
    case taxi
    
    var iconName: String {
        switch self {
        case .taxi: return "maptaximove"
        }
    }
}
