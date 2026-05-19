# Travixx — Otonom Oturum Logu

## 📅 Bu Oturumda Yapılanlar

Sen dışarıdayken proje üzerinde substantial ilerleme kaydedildi. Tüm değişiklikler `flutter analyze` ile temiz ve `flutter build web` ile derleniyor.

---

## 🚀 Yeni Özellikler

### 1. GPS + Mesafe Sıralaması ✅
**Dosyalar:** `lib/core/utils/gps_service.dart`

- `geolocator` paketi eklendi
- `GpsService.getCurrentPosition()`: konum izni ister, cache'ler
- `GpsService.distanceKm()`: Haversine formülü ile gerçek mesafe
- `GpsService.estimateMinutes()`: 50 km/s ortalamayla süre tahmini
- Android için `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` izinleri

### 2. Home Ekranı Gerçek Veriye Bağlandı ✅
**Dosyalar:** `lib/features/cities/home_screen.dart`

- `_demoPlaces` hardcoded liste silindi
- `DatabaseService.getAllPlaces()` ile gerçek Supabase verisi
- GPS varsa: en yakın 20 mekan, sıralı, gerçek km/dk
- GPS yoksa: popüler mekanlar (rating'e göre)
- "GPS aktif" / "Konum kapalı" durum göstergesi
- "Tekrar dene" butonu
- Mekan kartı tıklayınca → `/place/:id` detaya

### 3. QR Tarama Ekranı ✅
**Dosyalar:** `lib/features/qr_scanner/qr_scanner_screen.dart`

- `mobile_scanner` v7 ile kamera kontrolü
- Flaş aç/kapat + ön/arka kamera değiştirme
- QR kod okuyunca `qr_codes` tablosunda eşleşme ara
- Bulduysa `scan_count++` + `/place/:id`'ye yönlendir
- Çerçeve görselleştirmesi + alt bilgi metni
- Camera izin hatası için açık mesaj
- Android `CAMERA` izni eklendi

### 4. Mekan Arama Ekranı ✅
**Dosyalar:** `lib/features/search/search_screen.dart`

- Debounce 350ms (yazma esnasında bekle)
- TR + EN isim arama (`DatabaseService.searchPlaces`)
- 4 durum: ipucu, yükleniyor, sonuç yok, sonuçlar
- Home arama çubuğu tıklanınca → `/search` açılır

### 5. Overpass API "Geniş Ara" ✅
**Dosyalar:** `lib/core/utils/overpass_service.dart`

- ÜCRETSİZ OpenStreetMap servisi
- Türkiye sınırında `tourism` + `historic` etiketli mekanlar
- Travixx'te bulunmadığında "Geniş Ara" butonuyla tetiklenir
- Sonuçlar ayrı bölümde, OSM rozetiyle
- Karta tıklayınca OpenStreetMap web haritası açar

### 6. Cities Bölge Filtresi ✅
**Dosyalar:** `lib/features/cities/cities_screen.dart`

- 7 bölge chip'i: Tümü, Marmara, Ege, Akdeniz, İç Anadolu, Karadeniz, Doğu, Güneydoğu
- Arama + bölge filtresi birlikte
- Sonuç sayısı + "Temizle" butonu
- "Sonuç bulunamadı" boş durum tasarımı

---

## 🗺️ Tüm Rotalar

| URL | Ekran | Auth Gerekli |
|---|---|---|
| `/` | Landing (giriş/kayıt) | Hayır |
| `/home` | Ana ekran (Supabase + GPS) | **Evet** ✋ |
| `/cities` | 81 şehir + filtre | Hayır |
| `/city/:id` | Şehirdeki mekanlar | Hayır |
| `/place/:id` | Mekan detayı + harita + favori | Hayır |
| `/search?q=...` | Mekan arama (TR+EN+OSM) | Hayır |
| `/qr-scan` | QR kod tarama | Hayır |
| `/favorites` | Favorilerim | Hayır (giriş yapılmamışsa CTA) |
| `/profile` | Profil + çıkış | Hayır (giriş yapılmamışsa CTA) |

---

## 🔐 Auth Gate (Otomatik Yönlendirme)

`lib/core/utils/router.dart` içindeki `redirect` callback:

- **Oturum yokken `/home`'a gitmeye çalışırsan** → otomatik `/` (landing)
- **Oturum varken `/`'a düşersen** → otomatik `/home` (giriş sonrası UI sorununu çözer)

`_AuthRefreshListenable`, Supabase `onAuthStateChange` stream'ini dinler, her auth değişiminde router'ı tetikler.

---

## 📦 Eklenen Paketler (`pubspec.yaml`)

```yaml
geolocator: ^13.0.2   # GPS
http: ^1.2.2           # Overpass API isteği
```

Zaten vardı: `mobile_scanner ^7.0.0`, `flutter_map ^7.0.0`, `latlong2 ^0.9.1`, `url_launcher ^6.3.0`, `intl ^0.20.2`.

---

## 🧪 Test Et Listesi (Önemli!)

```powershell
C:\src\flutter\bin\flutter.bat run -d chrome
```

### Akışlar
- [ ] Giriş yap → otomatik `/home`'a düşüyor mu? ✅ (auth gate)
- [ ] Chrome konum izni iste → izin verince GPS aktif, mekanlar mesafeye göre
- [ ] Mekan kartına tıkla → detay açılıyor mu? Harita gözüküyor mu?
- [ ] Favori kalp ikonuna bas → `/favorites`'te görünüyor mu?
- [ ] Profil → email/tarih/avatar → çıkış dialog'u
- [ ] Üst arama çubuğuna tıkla → search ekranı açılıyor mu?
- [ ] Olmayan bir kelime ara (örn. "asdfgh") → "Geniş Ara" butonu çıkıyor mu?
- [ ] Bilinen bir mekan ara (örn. "ayasofya") → Travixx sonuçları + altta OSM linki
- [ ] QR Tara'ya bas → kamera açılıyor mu?

### Sidebar / Bottom Nav Bağlantıları
- [ ] Ana Sayfa
- [ ] Şehirler → `/cities`
- [ ] QR Tara → `/qr-scan`
- [ ] Favoriler → `/favorites`
- [ ] Profil → `/profile`

---

## ⚠️ Bilinen / Yapılmayan

### Şimdilik Yapılmadı (Sen Karar Verirsin)
- **Multi-language (ADIM 5):** 6 dil tüm UI'yı çevirmek riskli ve uzun. Şimdilik atlandı, ilerleyen oturumda `flutter_localizations` + .arb dosyalarıyla yapılır.
- **Foto'lar:** İstanbul + Kapadokya gerçek foto, diğer 18 destinasyon gradient kartlar. Sen indirip eklersen `_destinations` listesine `url` koyabiliriz.

### Test Edilmesi Gerekenler (Sen Yapacaksın)
- **Supabase email confirmation:** Kayıt sonrası gelen onay maili. Once tıklayınca giriş yapabilirsin.
- **Konum izni:** Chrome ilk girişte sorar. İzin verirsen GPS sıralaması aktif olur.
- **Kamera izni:** QR Tara için ilk girişte sorar.
- **Overpass API:** İnternet bağlantısı şart, bazen yavaş olabilir (25 sn timeout).

---

## 📊 Commit Geçmişi (Bu Oturumda)

```
f37e256 feat: Overpass API geniş arama (Katman 2)
527a398 feat: mekan arama ekranı + home arama bağlantısı
c8990a4 feat: GPS sıralaması + QR tarama + bölge filtresi + gerçek veri
25a7504 feat: favoriler ekranı + profil ekranı + Türkçe tarih formatı
34d55f1 feat: mekan detay ekranı + auth gate + harita entegrasyonu
448a687 feat: tema, navigasyon, foto carousel ve UX iyileştirmeleri
```

GitHub: https://github.com/aydnomer/TRAVIXX

---

## 🎯 Faz Durumu

| Faz | Adım | Durum |
|---|---|---|
| 1 | Kurulum | ✅ |
| 2 | Auth + Landing | ✅ |
| 3 | Veritabanı + Liste ekranları | ✅ |
| - | Adım 1: flutter analyze | ✅ |
| - | **Adım 2: Mekan Detay** | ✅ |
| - | **Adım 3: GPS + Mesafe** | ✅ |
| 4 | **QR Sistemi** | ✅ |
| - | Adım 5: 6 Dil | ⏳ (sonra) |
| - | **Adım 6: Favoriler** | ✅ |
| - | **Adım 7: Overpass API** | ✅ |
| 5 | Deploy (web hosting + APK) | ⏳ (sonra) |

**Beklenen sonraki adımlar:** 6 dil, deploy, ileri özellikler (kullanıcı bildirimi, favori paylaşma, premium hesaplar vb).
