# RoadShare — SwiftUI Map UI Clone (Uber / Martı / BiTaksi Style)

RoadShare, **Swift + SwiftUI** ile geliştirilmiş; **Uber / Martı / BiTaksi benzeri harita tabanlı UI/UX akışlarını** örnekleyen, **backend bağımlılığı olmayan** bir iOS demo projesidir.  
Amaç: Harita tabanlı uygulamalara hızlı başlamak isteyenler için **alınabilir, geliştirilebilir ve genişletilebilir** bir SwiftUI temelini sunmak.

> Bu repo **public** tutulmak üzere hazırlanmıştır ve özellikle **map-first** (harita merkezli) uygulamaların UI geliştirme sürecini hızlandırmak için tasarlanmıştır.

---

✨ Neler Var?

- **Uber/Martı/BiTaksi benzeri ana harita ekranı**
- Harita üzerinde **araç (taksi) gösterimi** ve **araç hareket/oynama animasyonları**
- **Konum seçme** (harita üzerinden pin/selection mantığı)
- Seçilen konuma göre **rota çizimi** (en kısa yol/route polyline yaklaşımı)
- **Bottom sheet / ride selection** akışı (SwiftUI sheet/overlay yaklaşımı)
- **Route Search**: başlangıç/varış arama ekranı ve sonuç listeleri (UI odaklı)
- **Localization** altyapısı (EN/TR içerikleri mevcut)

---

 🧱 Mimari

Bu proje **MVVM** yaklaşımıyla kurgulanmıştır ve SwiftUI state yönetimine uygun şekilde yapılandırılmıştır.

- **Views**: UI bileşenleri ve ekranlar
- **ViewModels**: ekran state’i, business logic, UI event handling
- **Domain / Models**: temel veri modelleri

Kod düzeninde hedef:
- **SOLID prensiplerine uygun**
- **Temiz kod (Clean Code)** odaklı
- Ekranlar arası bağımlılığı düşük, okunabilir, genişletilebilir yapı

---

 🗺️ Harita Özellikleri Nasıl Çalışır? (Genel Mantık)

RoadShare’ın harita akışı şu temel bileşenlere dayanır:

1. **Map State Yönetimi**
   - Kamera/region (harita konumu) state’i ViewModel’da yönetilir.
   - Kullanıcı etkileşimleri (drag/zoom, selection) UI event’leri olarak ViewModel’a akar.

2. **Konum Seçme**
   - Kullanıcı haritada bir nokta seçtiğinde (tap/drag pin mantığı), seçilen koordinat state’e yazılır.
   - Seçim sonrası UI (sheet, info card vb.) güncellenir.

3. **Rota Çizme (Polyline / Route)**
   - Start/End koordinatları belirlendikten sonra route hesaplanır.
   - Route sonucu polyline gibi çizim datasına çevrilip harita üzerinde gösterilir.
   - “En kısa yol” yaklaşımı route sağlayıcının (örn. MapKit directions mantığı) default optimizasyonu üzerinden modellenir.

4. **Araç Animasyonları**
   - Araçların konumları belirli bir “timer / tick” mantığıyla güncellenir.
   - SwiftUI tarafında marker/annotation konum değişimi animasyonlarla yumuşatılır.
   - Amaç: “harita üzerinde yaşayan araçlar” hissi vermek.

> Not: Proje backend içermediği için araç hareketleri ve bazı lokasyon akışları **demo/simülasyon** mantığıyla ilerler. Gerçek data kaynakları daha sonra eklenebilir.

---

 🧩 Bu Repo Kimler İçin?

- Harita tabanlı bir iOS uygulamasına başlayacak olanlar
- Uber/Martı/BiTaksi tarzı **UI akışlarını** SwiftUI ile kurgulamak isteyenler
- SwiftUI + MVVM ile “map-first” uygulama iskeleti arayanlar
- Bottom sheet, selection, rota çizimi gibi tipik harita bileşenlerini bir arada görmek isteyenler

---

🚀 Başlangıç

1. Repoyu klonla:
   ```bash
   git clone https://github.com/cumaliguzel88/roadshareios.git
