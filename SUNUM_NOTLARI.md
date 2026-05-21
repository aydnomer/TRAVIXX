# 🎓 Bitirme Sunumu — Talking Points

Bu dosya jürij/hocaya proje sunumu yaparken kullanacağın notlardır. Her başlığın altında **ne söyleyeceğin** ve **neden önemli olduğu** yazıyor.

---

## 1. Açılış (2 dakika)

> "Travixx, Türkiye'nin 81 ilindeki tarihi mekanları, müzeleri ve gezilecek yerleri tek bir uygulamada sunan **akıllı turizm rehberidir**. Hem **yerli** hem **yabancı turistlere** hitap eder."

**Vurgulanacak değer önerisi:**
- "Türkiye'ye gelen turistler şu an Google Maps + birden çok dil sözlüğü + ayrı tarihçe siteleri kullanıyor."
- "Travixx hepsini birleştiriyor: GPS sıralama + QR ile anında bilgi + 6 dil + favoriler."

**Demo:**
- URL'i göster: `aydnomer.github.io/TRAVIXX`
- "Görüyorsunuz, **canlıda yayında**, internetten herkes erişebilir."

---

## 2. Teknik Mimarisi (3 dakika)

### Frontend: Flutter
> "Flutter ile **tek kod tabanı** üzerinden hem web hem Android için derleniyor. Bu çok büyük bir verimlilik kazancı — iOS, Web ve Android için ayrı ayrı kod yazmaya gerek yok."

**Önemli paketler:**
- `go_router`: Modern navigasyon ve auth gate
- `flutter_map`: Açık kaynak harita (ücretsiz)
- `mobile_scanner`: QR tarama
- `geolocator`: GPS konumu

### Backend: Supabase
> "**Supabase** açık kaynak bir Firebase alternatifi. PostgreSQL veritabanı + Auth + Row Level Security veriyor. Ücretsiz tier projemize fazlasıyla yetiyor."

**4 Tablo:**
- `cities` (81 il)
- `places` (~750 mekan)
- `qr_codes` (QR ↔ mekan eşleştirme)
- `favorites` (kullanıcı bazlı, RLS'li)

### Sıfır Maliyet
> "Bütçemiz sıfır. Hiçbir ücretli servis kullanmıyoruz."
- Google Places API → **OpenStreetMap Overpass API** (ücretsiz)
- Google Maps → **flutter_map + OpenStreetMap**
- Firebase → **Supabase Free Tier**
- Hosting → **GitHub Pages**

---

## 3. Öne Çıkan Özellikler (5 dakika — DEMO)

### Demo akışı:

**a) Landing page**
- Dil seçici: 🇹🇷 → 🇬🇧 → 🇸🇦 (Arapça'da RTL'i göster!)
- "Bakın layout otomatik sağa kaydı — gerçek anlamda **uluslararasılaştırma** var."

**b) Giriş yap**
- E-posta + şifre ile giriş
- "Auth Gate sayesinde otomatik home'a yönlendirildim."

**c) Home — GPS Sıralama**
- "Konum izni verdim. Şu an bulunduğum yere göre mekanlar **en yakından en uzağa** sıralı geliyor."
- "Mesafe **Haversine formülü** ile hesaplanıyor — büyük daire mesafe, küresel yüzey için doğru."

**d) Şehirler ekranı**
- "81 şehrin tümü burada. Bölge filtresi göstereyim — Karadeniz'e bas, sadece o bölge geldi."

**e) Mekan detay**
- Bir mekana tıkla
- "Burada **gerçek harita** var, **favori** butonu Supabase'e yazıyor, **kategori** ve **puan** rozetleri."

**f) Arama**
- Yaygın bir mekan ara (örn "Ayasofya") → Travixx sonuçları
- Olmayan bir şey ara (örn "asdf") → "Sonuç yok. **Geniş Ara** butonu görünüyor."
- Geniş Ara → "Şimdi OpenStreetMap'te tüm Türkiye'de tarama yapıyor."

**g) QR Tarama**
- "Burada kamera açılır. Bir mekanın QR kodunu okutunca direkt detay sayfasına atar."

---

## 4. Teknik Zorluklar ve Çözümler (2 dakika)

Bu kısımda **kritik düşünme** yeteneğini gösteriyorsun.

### Zorluk 1: Dil değişiminde tüm uygulama yenilenmiyordu
> "İlk yaklaşımım Provider kullanmaktı ama go_router rotalarına dil değişimi propagasyon sorunlu oldu. Çözüm: `MaterialApp.router`'a `ValueKey('app_$lang')` ekledim. Dil değişince anahtar değişiyor, tüm tree zorla rebuild oluyor."

### Zorluk 2: Arapça layout
> "Arapça için **RTL (sağdan-sola)** layout gerekiyor. Flutter'ın `Directionality` widget'ını **MaterialApp.builder içine** koyarak çözdüm — dışına koyunca Material widget'ların Overlay'i bozuluyordu."

### Zorluk 3: CI/CD'de Flutter versiyon uyumsuzluğu
> "İlk deploy'ım GitHub Actions'ta `flutter pub get` aşamasında fail oluyordu. Çünkü pubspec'im Dart 3.11 istiyordu ama CI'da Flutter 3.27 (Dart 3.6) yüklüydü. Pin'i kaldırıp `channel: stable` yaptım."

### Zorluk 4: TextEditingController yazı silinmesi
> "Form alanlarına yazdığım metinler 5 saniyede siliniyordu. Sebep: Carousel timer'ım `setState` çağırınca form rebuild oluyor, controller'lar yeniden oluşuyordu. Çözüm: Controller'ları State seviyesine taşıdım."

---

## 5. Ne Öğrendim? (1 dakika)

> "Bu proje sırasında öğrendiklerim:"
- **Reactive programlama** (ValueNotifier, ChangeNotifier)
- **Row Level Security** ile veritabanı seviyesinde yetkilendirme
- **CI/CD** (GitHub Actions workflow yazımı)
- **Coğrafi hesaplamalar** (Haversine formülü)
- **Uluslararasılaştırma** (i18n, RTL desteği)
- **OpenStreetMap ekosistemi** (Overpass API, harita tile'ları)

---

## 6. Gelecek Geliştirmeler (1 dakika)

Jüriye projenin **bitmediğini, evrildiğini** göstermek için:

- **Yapay zeka asistanı**: ChatGPT API entegrasyonu ile kişisel gezi planı
- **Sosyal özellikler**: Mekan yorumları, fotoğraf yükleme
- **Offline mode**: Bağlantı kesilse de favori mekanlar erişilebilsin
- **Pro plan**: Yerel rehberlerle entegrasyon
- **iOS desteği**: Flutter zaten destekliyor, sadece sertifika gerekiyor

---

## 7. Soru-Cevap Hazırlık

### "Neden Flutter?"
> "Cross-platform ihtiyacı vardı — bir kullanıcı sokakta cep telefonundan QR taracak ama hocamla bilgisayardan göstereceğim. Tek kod tabanı + native performans gerekiyordu. React Native'e göre rendering daha akıcı."

### "Neden Supabase, neden Firebase değil?"
> "Supabase **açık kaynak** (vendor lock-in yok), **PostgreSQL** (SQL biliyorum, NoSQL öğrenmem gerekmiyor), **Row Level Security** (yetkilendirme uygulama kodunda değil, veritabanında). Firebase'in NoSQL yapısı bu proje için fazla esnek olurdu."

### "GPS doğru mu hesaplanıyor?"
> "Haversine formülü kullandım — büyük daire mesafe. Dünyayı düzlem kabul etmek yerine küre olarak modelliyor. Ortalama 50 km/s hız varsayımıyla süre tahmini de yapıyorum. Trafik gerçek zamanlı değil ama temel doğru tahmin için yeterli."

### "Hangi sürümde Flutter kullandın?"
> "Flutter 3.41+, Dart 3.11+. CI'da `channel: stable` ile en son kararlı sürüm otomatik alınıyor, bu sayede gelecekte güncellemelerle uyumlu kalıyor."

### "QR kod sistemi gerçek hayatta nasıl çalışır?"
> "Her tarihi mekanın yetkilisi (örn. müze müdürü) Travixx admin paneline (yapım aşamasında) girer, kendi mekanı için bir QR kodu üretir, basıp duvara yapıştırır. Turist QR'ı tarayınca o `qr_data` ile veritabanından eşleşen mekan açılır. `scan_count` her okutmada artar, popülerite analizi yapılabilir."

### "RLS nedir ve neden önemli?"
> "Row Level Security — PostgreSQL'in satır bazlı yetkilendirmesi. Örnek: Favorites tablosunda her kullanıcı sadece **kendi favorilerini** okuyup yazabilir. Bu kontrol veritabanı seviyesinde — kullanıcı API'ı manipüle etmeye çalışsa bile başkasının favorilerine erişemez. Uygulama koduna güvenmek zorunda değiliz."

### "6 dil sistemini nasıl yaptın?"
> "build_runner ile kod jenerasyonu yerine basit `Map<String, Map<String, String>>` kullandım — 130+ string her dilde. `ValueNotifier` ile reaktif, `SharedPreferences` ile kalıcı. Arapça için `Directionality` widget'ı RTL'i sağlıyor."

### "Demo URL'in nasıl her zaman güncel kalıyor?"
> "GitHub Actions ile **CI/CD pipeline** kurdum. `main` branch'e push attığım anda otomatik build başlıyor, web çıktısı GitHub Pages'e deploy ediliyor. 5 dakika içinde canlıda."

---

## 8. Demo Sırasında Dikkat Edilecekler

- ✅ **İnternet bağlantın olduğundan emin ol** (deploy'a erişmek + Supabase için)
- ✅ **Önce gizli sekme aç** (cache temiz)
- ✅ **Tam ekran moduna geç** (F11) — daha profesyonel görünür
- ✅ **Birkaç dakika önce sayfayı aç** — ilk yükleme gözlemcide görünmesin
- ✅ **GPS demosu için**: Chrome'da konum iznine "İzin Ver" de
- ⚠️ **QR demosu için**: telefondan QR kod gösteren bir resim hazır olsun (Supabase'de `qr_codes` tablosunda gerçek kayıt olduğundan emin ol)

---

## 9. Süre Tahmini

| Bölüm | Süre |
|---|:---:|
| Açılış | 2 dk |
| Mimari | 3 dk |
| Demo | 5 dk |
| Zorluklar | 2 dk |
| Öğrenilenler + Gelecek | 2 dk |
| Soru-Cevap | 6 dk |
| **Toplam** | **20 dk** |

---

## 10. Yedek Plan

### Eğer demo açılmazsa:
1. **Yerel sürüm**: `flutter run -d chrome` ile bilgisayarından çalıştır
2. **Ekran kaydı**: Önceden yaptığın bir ekran kaydı/video hazır olsun (mobil için OBS kullan)
3. **Screenshot serisi**: README'deki ekran görüntülerini PDF'e koy

### Eğer GitHub Actions bir push'ta bozulursa:
> "Geliştirme döngüsünün doğal bir parçası bu — bir commit'te hata oldu, hemen düzeltici commit attım. Repository'de commit history'de görebilirsiniz."

---

**Hayırlı sunumlar! 🎓✈️**
