# ✈️ Travixx — Türkiye'yi Akıllıca Keşfet

> Türkiye'nin 81 ilindeki tarihi mekanları, müzeleri ve gezilecek yerleri **QR kod**, **GPS** ve **6 dil desteği** ile tek uygulamada sunan akıllı turizm rehberi.

**Live demo:** [aydnomer.github.io/TRAVIXX](https://aydnomer.github.io/TRAVIXX/)
**Geliştirici:** Ömer Faruk Aydın
**Proje türü:** Üniversite bitirme projesi

---

## 📸 Ekran Görüntüleri

| Landing Page | Home (GPS sıralı) | Mekan Detay |
|:---:|:---:|:---:|
| `[ekran görüntüsü 1]` | `[ekran görüntüsü 2]` | `[ekran görüntüsü 3]` |

| 81 Şehir Listesi | Profil | 6 Dil Desteği |
|:---:|:---:|:---:|
| `[ekran görüntüsü 4]` | `[ekran görüntüsü 5]` | `[ekran görüntüsü 6]` |

> **Not:** Sunum öncesi yukarıdaki yer tutucuları gerçek ekran görüntüleriyle değiştir. `assets/screenshots/` klasörüne PNG dosyaları koy ve markdown link'lerini güncelle.

---

## 🎯 Özellikler

### 1. 🌍 81 İl, 750+ Mekan
Türkiye'nin tüm illeri ve içindeki önemli mekanlar Supabase veritabanında. Bölge bazlı filtreleme (Marmara, Ege, Akdeniz, İç Anadolu, Karadeniz, Doğu Anadolu, Güneydoğu Anadolu).

### 2. 📍 GPS Tabanlı Mesafe Sıralaması
Tarayıcı/cihaz konumunu alır, **Haversine formülü** ile her mekana mesafe (km) ve tahmini varış süresi (dk) hesaplar. **En yakın mekan en üstte.**

### 3. 📱 QR Kod Sistemi
Her mekanda fiziksel QR kodu olur. Turist tarayıcıyı/uygulamayı açıp QR'ı okutunca **anında o mekanın detay sayfası** açılır. Tarama sayısı veritabanında izlenir.

### 4. 🗣️ 6 Dil Desteği
**Türkçe / English / Deutsch / العربية / Français / Русский** — uygulama arayüzü seçilen dilde. Arapça için **RTL (sağdan-sola) layout** otomatik. Seçilen dil `SharedPreferences` ile kalıcı saklanır.

### 5. 🔍 İki Katmanlı Arama
- **Katman 1 (Travixx):** İç veritabanında TR + EN isim eşleşmesi
- **Katman 2 (Geniş Arama):** Sonuç yoksa **OpenStreetMap Overpass API**'sinden Türkiye sınırında tüm tarihi/turistik yerler gelir (ücretsiz)

### 6. ❤️ Kullanıcı Hesabı + Favoriler
Supabase Auth ile e-posta kayıt/giriş. Beğendiğin mekanları favorilere ekle, kişisel listede topla. RLS ile her kullanıcı sadece kendi favorilerini görür.

### 7. 🗺️ Harita Entegrasyonu
Her mekan detayında **OpenStreetMap tabanlı interaktif harita** (zoom, kaydırma, marker).

---

## 🛠️ Teknoloji Yığını

### Frontend
- **Flutter 3.41+** (Dart 3.11+) — tek kod tabanı, web + Android
- **flutter_riverpod** — state management
- **go_router** — sayfa yönlendirme + auth gate
- **flutter_map + latlong2** — harita
- **mobile_scanner** — QR kod tarama
- **geolocator** — GPS konumu
- **shared_preferences** — dil tercihi kalıcılığı
- **intl** — Türkçe tarih formatlama

### Backend
- **Supabase** (PostgreSQL + Auth + Row Level Security)
  - 4 tablo: `cities`, `places`, `qr_codes`, `favorites`
  - Row Level Security tüm tablolarda aktif
  - Public okuma (cities, places, qr_codes), private favorites (kullanıcı bazlı)

### External Services (hepsi ücretsiz)
- **OpenStreetMap Overpass API** — geniş arama
- **OpenStreetMap Tiles** — harita karoları
- **Unsplash CDN** — destinasyon görselleri

### DevOps
- **GitHub Pages** — web hosting
- **GitHub Actions** — her push'ta otomatik build & deploy

---

## 🏗️ Mimari

```
travixx/
├── lib/
│   ├── main.dart                            # App entry, Supabase init, i18n load
│   ├── core/
│   │   ├── constants/                       # Supabase URL, kategori sabitleri
│   │   ├── i18n/i18n.dart                   # 6 dilde ~130 string + RTL
│   │   ├── theme/app_theme.dart             # Lacivert + turuncu palet
│   │   └── utils/
│   │       ├── database_service.dart        # Supabase sorguları
│   │       ├── gps_service.dart             # Haversine + konum izni
│   │       ├── overpass_service.dart        # OSM geniş arama
│   │       └── router.dart                  # 9 rota + auth gate
│   ├── features/
│   │   ├── auth/landing_screen.dart         # Marketing + giriş/kayıt
│   │   ├── cities/
│   │   │   ├── home_screen.dart             # GPS sıralı mekan listesi
│   │   │   ├── cities_screen.dart           # 81 şehir grid + bölge filtre
│   │   │   └── city_model.dart
│   │   ├── places/
│   │   │   ├── places_screen.dart           # Şehrin mekan listesi
│   │   │   ├── place_detail_screen.dart     # Detay + harita + favori
│   │   │   └── place_model.dart
│   │   ├── search/search_screen.dart        # Travixx + OSM arama
│   │   ├── qr_scanner/qr_scanner_screen.dart
│   │   ├── favorites/favorites_screen.dart
│   │   └── profile/profile_screen.dart
│   └── shared/widgets/language_selector.dart
├── web/
│   ├── index.html                           # SEO + Open Graph + loader
│   └── manifest.json                        # PWA metadata
├── .github/workflows/deploy.yml             # Otomatik deploy
└── pubspec.yaml
```

### Sayfa Rotaları

| Path | Ekran | Auth gerekli? |
|---|---|:---:|
| `/` | Landing (marketing + giriş/kayıt) | ❌ |
| `/home` | Ana sayfa (GPS sıralı mekanlar) | ✅ |
| `/cities` | 81 şehir listesi + bölge filtre | ❌ |
| `/city/:id` | Bir şehrin mekanları | ❌ |
| `/place/:id` | Mekan detayı | ❌ |
| `/search?q=...` | Mekan arama | ❌ |
| `/qr-scan` | Kamera QR tarayıcı | ❌ |
| `/favorites` | Favori mekanlar | ✅ |
| `/profile` | Profil | ✅ |

### Auth Gate
`go_router` + `Supabase.auth.onAuthStateChange` Stream listener:
- Oturum yok + `/home`'a gidişten → `/`
- Oturum var + `/`'a gidişten → `/home`

---

## 🚀 Kurulum

### Önkoşullar
- Flutter 3.41+ ([yükleme rehberi](https://docs.flutter.dev/get-started/install))
- Bir Supabase projesi (ücretsiz tier yeterli)

### 1. Repo'yu klonla
```bash
git clone https://github.com/aydnomer/TRAVIXX.git
cd TRAVIXX
```

### 2. Bağımlılıkları indir
```bash
flutter pub get
```

### 3. Supabase yapılandırması
`lib/core/constants/supabase_constants.dart` dosyasını aç ve kendi Supabase URL + anon key'ini gir:
```dart
class SupabaseConstants {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

### 4. Veritabanı şeması
Supabase SQL Editor'da aşağıdaki tabloları oluştur (Row Level Security aktif):

```sql
-- cities
CREATE TABLE cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  region TEXT,
  emoji TEXT,
  image_url TEXT,
  place_count INT DEFAULT 0,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- places
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id UUID REFERENCES cities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_en TEXT,
  description TEXT,
  description_en TEXT,
  category TEXT,
  emoji TEXT,
  image_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  is_free BOOLEAN DEFAULT FALSE,
  has_qr BOOLEAN DEFAULT FALSE,
  rating DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- qr_codes
CREATE TABLE qr_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id UUID REFERENCES places(id) ON DELETE CASCADE,
  qr_data TEXT UNIQUE NOT NULL,
  scan_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- favorites
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id UUID REFERENCES places(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, place_id)
);

-- RLS
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public read cities" ON cities FOR SELECT USING (true);
CREATE POLICY "public read places" ON places FOR SELECT USING (true);
CREATE POLICY "public read qr_codes" ON qr_codes FOR SELECT USING (true);
CREATE POLICY "own favorites" ON favorites FOR ALL USING (auth.uid() = user_id);
```

### 5. Çalıştır
```bash
# Web
flutter run -d chrome

# Android
flutter run

# Web build (production)
flutter build web --release
```

---

## 🌐 Otomatik Deploy

`.github/workflows/deploy.yml` dosyası her `main` push'unda:
1. Ubuntu sunucusu açar
2. Flutter SDK kurar (cache'ten)
3. `flutter pub get`
4. `flutter build web --release --base-href "/TRAVIXX/"`
5. GitHub Pages'e deploy eder

Sonuç **5 dakika içinde** [aydnomer.github.io/TRAVIXX](https://aydnomer.github.io/TRAVIXX/) adresinde canlıya çıkar.

---

## 🎨 Tasarım Kararları

### Renk Paleti
- **Lacivert** `#1A2744` — ana renk (üst bar, başlıklar)
- **Turuncu** `#F97316` — vurgu (butonlar, CTA, marka)
- **Altın** `#EAB308` — ikincil vurgu (yıldız puanları)
- **Açık mavi** `#3B82F6 → #93C5FD` — home ekranı (Booking/Airbnb tarzı)
- **Nötr gri** `#F5F5F5` — arka plan

### Mimari Prensipler
1. **Feature-first klasör yapısı** — her özellik kendi klasöründe (auth, cities, places...)
2. **Reactive i18n** — `ValueNotifier<String>` + `MaterialApp` key ile dil değişiminde tüm app rebuild
3. **No build_runner** — kod jenerasyonu yerine basit `Map<String, Map<String, String>>` ile çeviri
4. **Auth state tek kaynak** — Supabase `onAuthStateChange` → router redirect → UI

---

## 💰 Bütçe Kuralı: Sıfır Maliyet

Bu proje **tamamen ücretsiz araçlarla** çalışır:
- Supabase Free Tier (500 MB DB, 50K aylık aktif kullanıcı)
- GitHub Pages (sınırsız)
- GitHub Actions (ayda 2000 dk ücretsiz)
- OpenStreetMap (ücretsiz, sınırsız)
- Unsplash (ücretsiz)

**Google Places API, Mapbox** gibi ücretli servisler **kullanılmaz**.

---

## 📊 Geliştirme Süreci

| Faz | Durum | İçerik |
|---|:---:|---|
| **Faz 1** Kurulum | ✅ | Flutter projesi, klasör yapısı, paketler |
| **Faz 2** Auth + Landing | ✅ | Supabase Auth, landing page, navigasyon |
| **Faz 3** Veritabanı + Liste Ekranları | ✅ | Supabase tabloları, modeller, cities/places |
| **Faz 4** Mekan Detay + Favoriler + GPS | ✅ | Place detail, harita, favoriler, mesafe sıralama |
| **Faz 5** QR + Çoklu Dil + Arama | ✅ | QR scanner, 6 dil sistemi, Overpass arama |
| **Faz 6** Deploy + Polish | ✅ | GitHub Actions, SEO, profesyonel açılış |

---

## 🔬 Teknik Detaylar

### Haversine Mesafe Formülü
İki coğrafi nokta arasındaki büyük daire mesafesini hesaplar (km):
```dart
static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthR = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = sin(dLat/2) * sin(dLat/2) +
            cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLng/2) * sin(dLng/2);
  return earthR * 2 * atan2(sqrt(a), sqrt(1-a));
}
```

### Overpass API Sorgusu
OpenStreetMap'te Türkiye sınırı içinde tourism/historic etiketli noktaları arar:
```overpassql
[out:json][timeout:25];
area["ISO3166-1"="TR"]->.tr;
(
  node["tourism"~"museum|attraction"](area.tr);
  node["historic"](area.tr);
);
out body 50;
```

### Reactive i18n
```dart
ValueListenableBuilder<String>(
  valueListenable: I18n.language,
  builder: (context, lang, _) => MaterialApp.router(
    key: ValueKey('app_$lang'),  // dil değişince tüm tree rebuild
    builder: (ctx, child) => Directionality(
      textDirection: I18n.isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
      child: child!,
    ),
    routerConfig: appRouter,
  ),
)
```

---

## 📝 Bilinen Sınırlamalar

- **Mekan görselleri**: Şu an Kapadokya ve İstanbul dışındaki destinasyonlar tasarımlı gradient kartlar olarak gösteriliyor. Gerçek görseller `_destinations` listesine eklenebilir.
- **QR Kodları**: Web'de bazı tarayıcılarda kamera erişimi sınırlı olabilir (Chrome ✅, Safari sınırlı).
- **GPS**: HTTPS gerektirir (GitHub Pages'te otomatik var).
- **Email confirmation**: Supabase'de açıksa, kullanıcı kayıt sonrası e-postadaki linki **bir kere** tıklamalı.

---

## 📜 Lisans

Üniversite bitirme projesi olarak hazırlanmıştır. Akademik kullanım serbesttir.

---

## 👤 İletişim

**Ömer Faruk Aydın**
- GitHub: [@aydnomer](https://github.com/aydnomer)
- Repo: [github.com/aydnomer/TRAVIXX](https://github.com/aydnomer/TRAVIXX)
- Demo: [aydnomer.github.io/TRAVIXX](https://aydnomer.github.io/TRAVIXX/)
