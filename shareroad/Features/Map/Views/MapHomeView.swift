//
//  MapHomeView.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import MapKit

// MARK: - MapHomeView
/// Uygulamanın ana harita ekranı
/// Harita + Arama çubuğu + Bottom sheet içerir
struct MapHomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: MapHomeViewModel
    
    // MARK: - Init
    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: MapHomeViewModel(locationService: locationService))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Harita (tam ekran, arka planda)
            mapView
            
            // Arama çubuğu - Artık bottom sheet içinde

            
            // Bottom sheet (altta overlay)
            VStack {
                Spacer()
                bottomSheet
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            viewModel.startVehicleAnimations()
        }
        .onDisappear {
            viewModel.stopVehicleAnimations()
        }
        .onTapGesture {
            // Dropdown açıkken dışarıya basılırsa kapat
            if viewModel.isDropdownOpen {
                viewModel.toggleDropdown()
            }
        }
    }
}

// MARK: - View Components
private extension MapHomeView {
    
    /// Apple Maps görünümü
    var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            // Kullanıcı konumu - native pulsing blue dot
            UserAnnotation(anchor: .center)
            
            // Yakındaki araçlar
            ForEach(viewModel.nearbyVehicles) { vehicle in
                Annotation(coordinate: vehicle.coordinate) {
                    VehicleAnnotationView(vehicle: vehicle)
                } label: {
                    EmptyView() // Label gizle
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapCompass()
        }
    }
    

    
    /// Alt bottom sheet
    var bottomSheet: some View {
        RideSelectionSheet(viewModel: viewModel)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    MapHomeView(locationService: LocationService())
}
#endif
