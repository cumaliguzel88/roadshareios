//
//  shareroadApp.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - App Entry Point
/// Uygulamanın giriş noktası
/// LocationService'i oluşturur ve MapHomeView'e inject eder
@main
struct shareroadApp: App {
    
    // MARK: - Dependencies
    /// Konum servisi - uygulama boyunca tek instance
    private let locationService = LocationService()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            MapHomeView(locationService: locationService)
        }
    }
}
