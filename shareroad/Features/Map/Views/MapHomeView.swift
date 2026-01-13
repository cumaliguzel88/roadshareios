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
    @StateObject private var routeSearchViewModel = RouteSearchViewModel()
    @State private var showRouteSearch = false
    
    // MARK: - Init
    init(locationService: LocationService) {
        _viewModel = StateObject(wrappedValue: MapHomeViewModel(locationService: locationService))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            // Harita (tam ekran, arka planda)
            mapView
            
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
        .fullScreenCover(isPresented: $showRouteSearch) {
            RouteSearchView(viewModel: routeSearchViewModel)
                .onAppear {
                    // Kullanıcının gerçek konumunu RouteSearchViewModel'e geç
                    if let userLocation = viewModel.locationService.currentLocation {
                        routeSearchViewModel.setUserLocation(userLocation)
                    }
                }
        }
        .onChange(of: routeSearchViewModel.destinationLocation) { _, newDestination in
            // Varış noktası seçildiğinde haritaya çiz
            if let destination = newDestination {
                showRouteSearch = false // Sayfayı kapat
                
                // Biraz gecikme ile rota hesapla (animasyon için)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Durakları hazırla
                    let stops = routeSearchViewModel.stops
                        .compactMap { $0 }
                        .map { ($0.coordinate, $0.title) }
                    
                    viewModel.setDestination(destination.coordinate, name: destination.title, stops: stops)
                }
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
            
            // Duraklar (Stop Markers - Kırmızı)
            ForEach(Array(viewModel.stops.enumerated()), id: \.offset) { index, stop in
                Annotation(coordinate: stop.coordinate) {
                    StopMarkerView(number: index + 1)
                } label: {
                    Text(stop.name)
                }
            }
            
            // Varış noktası marker
            if let destCoord = viewModel.destinationCoordinate,
               let destName = viewModel.destinationName {
                Annotation(coordinate: destCoord) {
                    DestinationMarkerView()
                } label: {
                    Text(destName)
                }
            }
            
            // Rota çizgileri (Siyah, statik, tüm segmentler)
            ForEach(viewModel.routeSegments, id: \.self) { segment in
                MapPolyline(segment.polyline)
                    .stroke(.black, lineWidth: 8)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapCompass()
        }
    }
    
    /// Alt bottom sheet
    var bottomSheet: some View {
        RideSelectionSheet(viewModel: viewModel) {
            showRouteSearch = true
        }
    }
}

// MARK: - Stop Marker View
/// Durak için kırmızı marker
struct StopMarkerView: View {
    let number: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin başlığı
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Pin iğnesi
            Triangle()
                .fill(.red)
                .frame(width: 12, height: 10)
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Destination Marker View
/// Varış noktası için özel marker
struct DestinationMarkerView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Pin başlığı
            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
            }
            
            // Pin iğnesi
            Triangle()
                .fill(.black)
                .frame(width: 12, height: 10)
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    MapHomeView(locationService: LocationService())
}
#endif
