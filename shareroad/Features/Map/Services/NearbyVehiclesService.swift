//
//  NearbyVehiclesService.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation
import MapKit
import CoreLocation

// MARK: - NearbyVehiclesService
/// Yakındaki araçları simüle eden servis
/// Random koordinat üretimi ve Road Snapping işlemi yapar
final class NearbyVehiclesService {
    
    // MARK: - Public Methods
    
    /// Belirtilen merkez etrafında rastgele ve yola yaslanmış araçlar üretir
    /// - Parameters:
    ///   - center: Merkez koordinat (Kullanıcı konumu)
    ///   - count: İstenen araç sayısı (Default: 9)
    /// - Returns: Vehicle array
    func generateVehicles(around center: CLLocation, count: Int = 9) async -> [Vehicle] {
        var vehicles: [Vehicle] = []
        var attempts = 0
        let maxAttempts = count * 3 // Her araç için 3 deneme hakkı
        
        // Concurrent task group ile paralel işlem
        await withTaskGroup(of: Vehicle?.self) { group in
            for _ in 0..<maxAttempts {
                group.addTask {
                    // 1. Rastgele koordinat üret
                    let randomCoord = self.generateRandomCoordinate(around: center.coordinate, radiusInMeters: 1000)
                    
                    // 2. Yola yasla (Road Snapping - Fallback: Directions API)
                    if let snappedCoord = await self.snapToRoad(coordinate: randomCoord, userLocation: center.coordinate) {
                        return Vehicle(
                            id: UUID(),
                            coordinate: snappedCoord,
                            type: .taxi,
                            isAvailable: true
                        )
                    }
                    return nil
                }
            }
            
            // Sonuçları topla (istenilen sayıya ulaşana kadar)
            for await vehicle in group {
                if let vehicle = vehicle, vehicles.count < count {
                    // Çakışma kontrolü (Basitçe çok yakınları ele)
                    if !vehicles.contains(where: {
                        self.distanceBetween($0.coordinate, vehicle.coordinate) < 50
                    }) {
                        vehicles.append(vehicle)
                    }
                }
            }
        }
        
        return vehicles
    }
    
    // MARK: - Private Methods
    
    /// Verilen koordinata en yakın yol üzerindeki noktayı bulur
    /// iOS 14+ MKRoadSnapper API public olmadığı için MKDirections fallback'ini kullanıyoruz
    private func snapToRoad(coordinate: CLLocationCoordinate2D, userLocation: CLLocationCoordinate2D) async -> CLLocationCoordinate2D? {
        // MKDirections Request
        // Kullanıcı konumundan rastgele noktaya bir rota çizmeye çalışıyoruz
        // Bu rotanın bitiş noktası veya polyline üzerindeki noktalar kesinlikle yoldadır
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            // En kısa rotayı al
            if let route = response.routes.first {
                // Rotanın bitiş noktasına yakın bir nokta seçelim (hedef yola snap olmuş olur)
                // Veya rotanın son %10'luk kısmından bir nokta alabiliriz
                // Basit ve etkili yöntem: Rota üzerindeki son point (destination)
                // Ancak destination tam koordinat olabilir, rota geometrisinden bir nokta almak daha güvenli
                
                let pointCount = route.polyline.pointCount
                if pointCount > 0 {
                    // Son noktanın (hedefin) koordinatını al
                    var coords = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: 1)
                    route.polyline.getCoordinates(coords, range: NSRange(location: pointCount - 1, length: 1))
                    let snapped = coords.pointee
                    coords.deallocate()
                    return snapped
                }
            }
        } catch {
            // Rota bulunamazsa (deniz vs.) nil dön
            #if DEBUG
            print("⚠️ Road snap failed: \(error.localizedDescription)")
            #endif
        }
        return nil
    }
    
    /// Belirtilen merkez ve yarıçap içinde rastgele koordinat üretir (100m - 400m arası)
    private func generateRandomCoordinate(around center: CLLocationCoordinate2D, radiusInMeters radius: Double) -> CLLocationCoordinate2D {
        // 1 derece enlem ~ 111km
        // 100m ile 400m arası rastgele mesafe
        let minDistance: Double = 100
        let maxDistance: Double = 400
        let distance = Double.random(in: minDistance...maxDistance)
        
        let r = distance / 111000 // Derece cinsinden yarıçap
        
        let t = 2 * Double.pi * Double.random(in: 0...1) // Rastgele açı
        
        let x = r * cos(t)
        let y = r * sin(t)
        
        // Boylam düzeltmesi (x / cos(lat))
        let newLat = center.latitude + y
        let newLon = center.longitude + (x / cos(center.latitude * .pi / 180))
        
        return CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
    }
    
    /// Mevcut konumdan belirli bir mesafede (0-50m) rastgele bir koordinat üretir
    /// Idle animasyonu için kullanılır (30m - 80m arası - Yavaş Akış)
    func generateRandomNearbyCoordinate(from current: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // Rastgele mesafe (30 - 80m)
        let minDistance: Double = 30
        let maxDistance: Double = 80
        let distance = Double.random(in: minDistance...maxDistance)
        
        let r = distance / 111000 // Derece cinsinden
        
        let t = 2 * Double.pi * Double.random(in: 0...1) // Rastgele açı
        
        let x = r * cos(t)
        let y = r * sin(t)
        
        // Boylam düzeltmesi
        let newLat = current.latitude + y
        let newLon = current.longitude + (x / cos(current.latitude * .pi / 180))
        
        return CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
    }
    
    /// İki koordinat arası mesafe (metre)
    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return loc1.distance(from: loc2)
    }
}
