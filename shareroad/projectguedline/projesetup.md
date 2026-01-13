📁 Proje Klasör Yapısı
├── Core/
│   ├── Network/
│   ├── Location/
│   ├── Logging/
│   └── Extensions/
│
├── Domain/
│   ├── Models/
│   ├── Repositories/
│   └── UseCases/
│
├── Features/
│   ├── Authentication/
│   ├── Map/
│   ├── Ride/
│   └── Profile/
│
└── UI/
    ├── Components/
    ├── Styles/
    └── Modifiers/
Not: Yeni dosyalar klasörleme mantığına göre ilgili klasöre eklenmelidir.

🎯 Katman Sorumlulukları
Core/ - Temel Altyapı

Network: Backend iletişimi (HTTP + WebSocket), token yönetimi, retry logic
Location: Konum servisleri (CLLocationManager wrapper), background tracking
Logging: Debug log sistemi (sadece DEBUG modda aktif, production sessiz)
Extensions: Swift/Foundation/UIKit extension'lar

Domain/ - İş Mantığı

Models: Veri yapıları (struct, Codable, Identifiable)
Repositories: Veri katmanı soyutlaması (Protocol + Implementation)
UseCases: Kompleks iş akışları, birden fazla repository koordinasyonu

Features/ - UI Modülleri
Her feature kendi içinde ViewModels, Views ve Services içerir. Bağımsız çalışabilir modüller.
UI/ - Ortak UI

Components: Reusable SwiftUI componentleri (button, card, input vb.)
Styles: Renkler, fontlar, theme tanımları
Modifiers: Custom ViewModifier'lar


🌐 Çoklu Dil Desteği - KRİTİK KURAL
❌ ASLA YAPMA
swiftText("Sürücü bulunamadı")
Button("Devam Et") { }
errorMessage = "Bağlantı hatası"
✅ MUTLAKA YAP
swiftText("error.no_driver_found")
Button("button.continue") { }
errorMessage = NSLocalizedString("error.connection_failed", comment: "")
```

### Localizable.strings Yapısı
```
Resources/
├── Localizations/
│   ├── tr.lproj/
│   │   └── Localizable.strings
│   └── en.lproj/
│       └── Localizable.strings
String Extension (Kolaylık için)
swiftextension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// Kullanım:
Text("welcome.title".localized)
Text("ride.distance".localized(with: 5.2))
```

### Key Naming Convention
```
// Format: category.subcategory.description
"button.continue"
"button.cancel"
"error.network.timeout"
"error.ride.no_driver"
"map.search.placeholder"
"profile.settings.title"
```

---

## 🏗️ Mimari Akış
```
View → ViewModel → UseCase → Repository → Network/Database
  ↓        ↓          ↓           ↓             ↓
@State  @Published  Business   Protocol    URLSession
                     Logic     Interface   WebSocket
Dependency Injection Pattern

Tüm servisler Protocol tanımla
ViewModel'lere Protocol injection yap
Mock/Production implementasyonları ayrı tut


🧵 Thread Yönetimi - Altın Kurallar
✅ DOĞRU Örnekler
swift// 1. UI güncellemeleri - @MainActor
@MainActor class ViewModel: ObservableObject {
    @Published var data: [Item] = []
    
    func load() async {
        data = await repository.fetch() // Otomatik main thread
    }
}

// 2. Background işlemler - async/await
func processData() async throws -> Result {
    let data = await heavyTask() // Otomatik background
    return transform(data)
}

// 3. Thread-safe shared state - Actor
actor Cache {
    private var storage: [String: Data] = [:]
    
    func store(_ data: Data, key: String) {
        storage[key] = data
    }
}

// 4. Combine ile reactive updates
locationManager.locationPublisher
    .receive(on: DispatchQueue.main)
    .sink { location in
        self.updateUI(location)
    }

// 5. Task cancellation
private var task: Task<Void, Never>?

func start() {
    task?.cancel()
    task = Task {
        while !Task.isCancelled {
            await doWork()
        }
    }
}

// 6. Main thread'e geri dönüş
func updateFromBackground() async {
    let result = await backgroundWork()
    
    await MainActor.run {
        self.uiProperty = result
    }
}
❌ YANLIŞ Örnekler
swift// 1. UI update background'da
Task {
    let data = await fetch()
    self.items = data // CRASH! Main thread değil
}

// 2. Shared mutable state (thread-safe değil)
class Cache {
    var data: [String: Any] = [:] // DATA RACE!
}

// 3. Blocking main thread
func loadData() {
    let data = repository.fetchSync() // DONMA!
    self.items = data
}

// 4. Force unwrap background thread
Task {
    let view = UIView() // CRASH! UIKit main thread'de olmalı
}

// 5. Retain cycle
Task {
    self.data = await fetch() // Memory leak potential
}

// 6. Nested DispatchQueue (gereksiz)
DispatchQueue.global().async {
    DispatchQueue.main.async {
        // Karmaşık, async/await kullan
    }
}
```

---

## 🌐 Backend İletişimi

### HTTP (REST API) - Core/Network
```
Sorumluluklar:
- Generic request method <T: Decodable>
- Automatic token injection
- Retry logic (exponential backoff)
- Error mapping (NetworkError)
- Request timeout handling
- Response validation
- JSON encode/decode

Teknoloji:
- URLSession (native)
- async/await
- Result type
```

### WebSocket (Gerçek Zamanlı) - Core/Network
```
Sorumluluklar:
- Persistent connection
- Auto-reconnection (bağlantı koptuğunda)
- Heartbeat (ping/pong - 30s)
- Message queue (offline durumda)
- Thread-safe message handling
- Publisher ile event yayını

Teknoloji:
- URLSessionWebSocketTask
- Combine (Publisher/Subscriber)
- Actor (thread safety)
```

---

## 🗺️ Harita İşlemleri - Features/Map/Services

### MapService Sorumlulukları
```
1. MapKit Integration:
   - UIViewRepresentable wrapper
   - MKMapView lifecycle yönetimi
   - Coordinator pattern (delegate handling)

2. Annotation Management:
   - Driver pin'leri (diff algoritması)
   - User location pin
   - Custom annotation view'lar
   - Reuse pool optimization

3. Route Drawing:
   - Polyline rendering
   - Turn-by-turn directions
   - ETA calculations

4. Camera Control:
   - Zoom animations
   - Center on location
   - Region fitting (tüm pin'ler görünsün)

Performans:
- Sadece görünen alan içindeki pin'leri render et
- Annotation update'leri diff ile (delta updates)
- Heavy calculations background thread'de
```

---

## 🎨 UI & Animasyon - Best Practices

### SwiftUI Patterns
```
✅ State Management:
- @StateObject: Lifecycle owner (ViewModel)
- @ObservedObject: Passed down (child view)
- @State: Local view state
- @Binding: Two-way data flow
- @EnvironmentObject: Shared across hierarchy

✅ Performance:
- LazyVStack/HStack: On-demand rendering
- ScrollViewReader: Scroll to position
- .id() modifier: Force re-render control
- GeometryReader: Dikkatli kullan (expensive)

✅ Composition:
- ViewBuilder: Custom container views
- ViewModifier: Reusable styling
- PreferenceKey: Child → Parent data flow
```

### Animasyon Kuralları
```
GPU-Accelerated (✅ Kullan):
- opacity: .opacity(0.5)
- scale: .scaleEffect(1.2)
- rotation: .rotationEffect(.degrees(45))
- offset: .offset(x: 10, y: 20)
- position: .position(x: 100, y: 200)

CPU-Bound (❌ Kaçın):
- frame: .frame(width: 100) animasyonu
- background color direct değişimi
- path drawing animations

Timing:
- Subtle: 0.2-0.3 saniye
- Standard: 0.3-0.4 saniye
- Dramatic: 0.5-0.8 saniye
- Spring: .spring(response: 0.3, dampingFraction: 0.8)

Kontrol:
- withAnimation { } → Explicit, preferred
- .animation(.default) → Implicit, dikkatli kullan

Hedef: 60 FPS (16.67ms per frame)
✅ Animasyon Doğru Örnekler
swift// 1. Explicit animation
withAnimation(.easeInOut(duration: 0.3)) {
    isExpanded.toggle()
}

// 2. Spring animation
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
    offset = isShowing ? 0 : 300
}

// 3. Chained animations
withAnimation(.easeIn(duration: 0.2)) {
    opacity = 0
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
    withAnimation(.easeOut(duration: 0.3)) {
        scale = 1.2
    }
}

// 4. Gesture-driven animation
.gesture(
    DragGesture()
        .onChanged { value in
            offset = value.translation.height
        }
        .onEnded { _ in
            withAnimation(.spring()) {
                offset = 0
            }
        }
)
❌ Animasyon Yanlış Örnekler
swift// 1. Her state değişiminde animasyon
.animation(.default) // Kontrolsüz, performans düşer

// 2. Heavy operation ile animasyon
withAnimation {
    processLargeDataset() // UI kasması
}

// 3. Frame değişimi animasyonu
withAnimation {
    frameWidth = 200 // CPU-bound, yavaş
}

// 4. Background thread'de UI animasyon
Task {
    withAnimation { // YANLIŞ! Main thread'de olmalı
        self.items = newItems
    }
}

🐛 Logging Sistemi - Core/Logging
Katı Kurallar
swift1. Sadece DEBUG modda aktif
2. Release build'de compile edilmemeli (#if DEBUG)
3. Sensitive data asla loglama
4. Kategorize et (network, location, ui, map, ride)
5. File + function + line otomatik
6. os.Logger kullan (Apple native)
Kullanım Örnekleri
swift// ✅ DOĞRU
#if DEBUG
Logger.network.info("Request: GET /api/drivers")
Logger.map.debug("Pin updated: \(driverId)")
Logger.location.warning("Low accuracy: \(accuracy)")
Logger.ride.error("Failed to create ride: \(error)")
#endif

// ❌ YANLIŞ
print("User token: \(token)") // Sensitive data
Logger.network.info("Password: \(pwd)") // Production'da görünür
os_log("Message") // Kategorisiz

📦 Error Handling - Kapsamlı Strateji
Error Type Hierarchy
swift// Network errors
enum NetworkError: LocalizedError {
    case invalidURL
    case timeout
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .timeout: return "error.network.timeout".localized
        case .unauthorized: return "error.auth.unauthorized".localized
        // ...
        }
    }
}

// Domain errors
enum RideError: LocalizedError {
    case noDriversAvailable
    case invalidLocation
    case paymentFailed
    
    var errorDescription: String? { 
        // Localized strings
    }
}
ViewModel Error Handling Pattern
swift@MainActor
class ViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var showError = false
    
    func performAction() async {
        do {
            let result = try await repository.fetch()
            handleSuccess(result)
            
        } catch let error as DomainError {
            handleDomainError(error)
            
        } catch let error as NetworkError {
            handleNetworkError(error)
            
        } catch {
            #if DEBUG
            Logger.error("Unexpected: \(error)")
            #endif
            errorMessage = "error.unexpected".localized
            showError = true
        }
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .unauthorized:
            authManager.logout()
        case .timeout:
            scheduleRetry()
        default:
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

---

## 🚀 Performans Optimizasyonu

### Memory Management
```
✅ Weak References:
- Delegate pattern: weak var delegate
- Closures: [weak self] in
- Combine subscribers: .store(in: &cancellables)

✅ Resource Cleanup:
- deinit { task?.cancel() }
- Image cache size limit
- Cancellable collection cleanup

❌ Retain Cycles:
- Strong closure captures
- Delegate without weak
- Circular references
```

### Network Optimization
```
✅ Strategies:
- Request batching (multiple calls → 1 call)
- Response caching (Expires header)
- Image compression (thumbnail/full)
- Pagination (infinite scroll)
- Retry with exponential backoff

❌ Anti-patterns:
- Polling yerine WebSocket
- Her scroll'da request
- Unnecessary data fetching
```

### UI Performance
```
✅ Rendering:
- Lazy loading (LazyVStack)
- View reuse (List)
- .drawingGroup() for complex views
- Async image loading
- Minimal re-renders

❌ Expensive Operations:
- GeometryReader abuse
- Excessive @State
- Heavy body computations
- Synchronous image loading
```

### Location Tracking
```
✅ Battery Optimization:
- distanceFilter: 10-50 meters
- desiredAccuracy: kCLLocationAccuracyHundredMeters (çoğu durum)
- Background: Sadece gerektiğinde
- pausesLocationUpdatesAutomatically: true

❌ Battery Drain:
- kCLLocationAccuracyBest continuous
- distanceFilter: kCLDistanceFilterNone
- Gereksiz background tracking

📋 Kod Yazma Süreci - Mutlaka Takip Et
ADIM 1: Implementation Plan (Onay Gerekli)
Her görev için plan oluştur ve kullanıcıya sun:
markdown## Implementation Plan

**Görev:** [Yapılacak işi açıkla]

**Etkilenen Katmanlar:**
- Core: [Network/Location/Logging/Extensions]
- Domain: [Models/Repositories/UseCases]
- Features: [Authentication/Map/Ride/Profile]
- UI: [Components/Styles/Modifiers]

**Yeni Dosyalar:**
- [Klasör/DosyaAdı]: [Açıklama]

**Güncellenecek Dosyalar:**
- [Klasör/DosyaAdı]: [Ne değişecek]

**Dependencies:**
- [Gerekli servisler, protocol'ler]

**Thread Stratejisi:**
- Main Thread: [UI updates]
- Background: [Heavy operations]
- Actor: [Shared state]

**Localization Keys:**
- [Eklenecek string key'leri]

**Performans Considerations:**
- [Dikkat edilecek noktalar]

**Tahmini Complexity:** [Düşük/Orta/Yüksek]
```

**ONAY BEKLEYİN - Kullanıcı "devam et" demeden kod yazma!**

### ADIM 2: Kod Yazma (Onay Sonrası)

Onay aldıktan sonra kod yaz:
- Clean, okunabilir, maintainable
- Best practice'lere uygun
- Thread-safe garantili
- Performans odaklı
- Localized string'ler
- Comprehensive error handling

---

## ✅ Pre-Code Checklist - Her Satır İçin
```
□ Hard-coded string var mı? → Localized key'e çevir
□ UI update mi? → @MainActor kullan
□ Ağır işlem mi? → async/await background
□ Shared state mi? → Actor veya @Published
□ Log ekliyor musun? → #if DEBUG ile sar
□ Animasyon ekliyor musun? → GPU-accelerated property
□ Memory leak riski var mı? → [weak self] ekle
□ Error handle edildi mi? → do-catch var
□ Test edilebilir mi? → Protocol injection var
□ Performans check edildi mi? → Lazy/cache kullanıldı mı
□ User-friendly mi? → Loading/error/empty states var
```

---

## 🎯 İsimlendirme Standartları
```
Variables/Functions:    camelCase
    → currentLocation, fetchDrivers()

Types:                  PascalCase
    → Driver, RideRequest, MapViewModel

Boolean:                is/has/should prefix
    → isAvailable, hasActiveRide, shouldShowModal

Methods:                Verb + Object
    → fetchNearbyDrivers(), updateUserLocation()

Protocols:              -able/-ing suffix veya Protocol
    → Drivable, LocationTracking, DriverRepositoryProtocol

Constants:              camelCase (local) / SCREAMING_SNAKE (global)
    → maxRetryCount, API_BASE_URL

Enum Cases:             camelCase
    → case inProgress, case completed

Localization Keys:      category.subcategory.description
    → "button.continue", "error.network.timeout"
```

---

## 🎓 Temel Prensipler - Asla Unutma
```
1. Performans Öncelik #1
   → UI asla kasmamalı, donmamalı, 60 FPS hedef

2. Thread Safety Garantili
   → Data race yok, main/background ayrımı net

3. Localization Zorunlu
   → Hard-coded string asla, her text localized

4. Logging Sadece DEBUG
   → Production tamamen sessiz, sensitive data yok

5. Protocol-Oriented Design
   → Mock'lanabilir, test edilebilir, flexible

6. User-Friendly Errors
   → Türkçe/İngilizce, anlaşılır, actionable

7. Memory Efficient
   → Leak yok, cache limitli, cleanup var

8. Native First
   → Apple framework'ler önce, third-party son çare

9. Code Review Ready
   → Clean, documented, self-explanatory

10. Production Quality
    → Her satır canlıya gidecekmiş gibi

📚 Hızlı Referans
Thread Management
swift@MainActor          → UI updates
async/await         → Background operations
Actor               → Thread-safe shared state
Task { }            → Concurrent operations
State Management
swift@StateObject        → ViewModel (owner)
@ObservedObject     → Passed ViewModel
@State              → Local view state
@Binding            → Two-way binding
@Published          → Observable property
Networking
swiftURLSession          → HTTP requests
WebSocketTask       → Real-time updates
Combine             → Reactive streams
async/await         → Modern concurrency
Localization
swift"key".localized                          → Simple
"key".localized(with: arg1, arg2)       → With params
NSLocalizedString("key", comment: "")   → Direct

🔚 Final Reminder
Bu dökümanı her kod yazmadan önce oku. Implementation plan oluştur ve onay bekle. Kurallara sıkı sıkıya uy. Performans ve kullanıcı deneyimi her zaman öncelik. Production-ready, localized, thread-safe, performant kod yaz.
Unutma: Her string localized, her UI update main thread'de, her ağır işlem background'da, her log DEBUG'da.
