//
//  VehicleAnnotationView.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import CoreLocation

// MARK: - VehicleAnnotationView
/// Harita üzerinde araçları temsil eden Annotation View
/// Fade-in animasyonu ile gelir
struct VehicleAnnotationView: View {
    
    // MARK: - Properties
    let vehicle: Vehicle
    
    // MARK: - State
    @State private var opacity: Double = 0.0
    
    // MARK: - Body
    var body: some View {
        Image(vehicle.type.iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40) // User marker (~48pt) dan biraz küçük, 32 -> 40 büyütüldü
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
            }
            .accessibilityLabel("Taksi")
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VehicleAnnotationView(
        vehicle: Vehicle(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            type: .taxi,
            isAvailable: true
        )
    )
}
#endif
