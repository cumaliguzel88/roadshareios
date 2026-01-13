//
//  RoadPage.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import MapKit

// MARK: - RoadPage
/// Uygulamanın ana sayfası - Harita görünümü
/// Kullanıcı konumunu native pulsing marker ile gösterir
struct RoadPage: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: RoadViewModel
    
    // MARK: - Init
    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: RoadViewModel(locationService: locationService))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Ana harita görünümü
            mapView
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Components
private extension RoadPage {
    
    /// Apple Maps görünümü
    /// UserAnnotation: Native mavi yanıp sönen konum noktası (pulsing blue dot)
    /// GPS accuracy'ye göre etrafındaki mavi daire büyür/küçülür
    var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            // Native pulsing blue dot - Apple'ın default MKUserLocationView
            UserAnnotation(anchor: .center)
        }
        .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapUserLocationButton() // Kullanıcı konumuna git butonu
            MapCompass()            // Pusula
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    RoadPage(locationService: LocationService())
}
#endif
