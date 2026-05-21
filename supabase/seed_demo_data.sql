-- ═══════════════════════════════════════════════════════════════════
-- Travixx — Demo Veri Seed Script
-- ═══════════════════════════════════════════════════════════════════
-- Bu script Türkiye'nin 10 en ünlü turistik mekanını TAM detayla
-- günceller. Mekanlar zaten places tablosunda olmalı (isim eşleşmesi
-- ILIKE ile yapılır — case-insensitive, kısmi eşleşme).
--
-- Eğer mekan yoksa UPDATE 0 satır etkiler (hata vermez).
-- Eklenmesi gereken mekan varsa script sonunda INSERT bölümü var.
--
-- Çalıştırmak için: Supabase Dashboard > SQL Editor > yapıştır > Run.
-- ═══════════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────────
-- 1. AYASOFYA — İstanbul
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Sultan Ahmet Mh., Ayasofya Meydanı No:1, 34122 Fatih/İstanbul',
  admission_fee = 'Ücretsiz (cami kısmı). Üst kat müze: 25 EUR',
  opening_hours = 'Pazartesi-Pazar: 09:00-19:00 (namaz saatlerinde geçici kapanış)',
  website = 'https://ayasofyacamii.gov.tr',
  phone = '+90 212 522 1750',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Hagia_Sophia_Mars_2013.jpg/1280px-Hagia_Sophia_Mars_2013.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Hagia_Sophia_Interior_Dome.jpg/1280px-Hagia_Sophia_Interior_Dome.jpg'
  ],
  is_featured = true
WHERE name ILIKE '%ayasofya%' OR name_en ILIKE '%hagia sophia%';


-- ──────────────────────────────────────────────────────────────────
-- 2. TOPKAPI SARAYI — İstanbul
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Cankurtaran Mh., 34122 Fatih/İstanbul',
  admission_fee = 'Topkapı: 30 EUR · Harem ek: 12 EUR · MüzeKart geçerli',
  opening_hours = 'Salı: Kapalı / Çar-Pzt: 09:00-18:00 (gişe 17:00''da kapanır)',
  website = 'https://muze.gov.tr/muze-detay?SectionId=TSM01',
  phone = '+90 212 512 0480',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Topkapi_Palace_The_Imperial_Gate.JPG/1280px-Topkapi_Palace_The_Imperial_Gate.JPG'
  ],
  is_featured = true
WHERE name ILIKE '%topkapı%' OR name ILIKE '%topkapi%' OR name_en ILIKE '%topkapi%';


-- ──────────────────────────────────────────────────────────────────
-- 3. GALATA KULESİ — İstanbul
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Bereketzade Mh., Galata Kulesi Sk., 34421 Beyoğlu/İstanbul',
  admission_fee = '30 EUR (yetişkin), MüzeKart geçerli',
  opening_hours = 'Pazartesi-Pazar: 08:30-23:00',
  website = 'https://muze.gov.tr/muze-detay?SectionId=GLT01',
  phone = '+90 212 244 1160',
  images = ARRAY[
    'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=1600&q=80&auto=format&fit=crop'
  ],
  is_featured = true
WHERE name ILIKE '%galata kule%';


-- ──────────────────────────────────────────────────────────────────
-- 4. KAPADOKYA / GÖREME AÇIK HAVA MÜZESİ — Nevşehir
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Göreme Beldesi, 50180 Nevşehir Merkez/Nevşehir',
  admission_fee = '20 EUR (Açık Hava Müzesi) · Karanlık Kilise ek: 5 EUR',
  opening_hours = 'Pazartesi-Pazar: 08:00-17:00 (kış saatleri kısalır)',
  website = 'https://muze.gov.tr',
  phone = '+90 384 271 2167',
  images = ARRAY[
    'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?w=1600&q=80&auto=format&fit=crop'
  ],
  is_featured = true
WHERE name ILIKE '%kapadokya%' OR name ILIKE '%göreme%' OR name_en ILIKE '%cappadocia%';


-- ──────────────────────────────────────────────────────────────────
-- 5. PAMUKKALE TRAVERTENLERİ — Denizli
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Pamukkale, 20190 Pamukkale/Denizli',
  admission_fee = '25 EUR (Pamukkale + Hierapolis dahil)',
  opening_hours = 'Yaz: 06:30-21:00 / Kış: 08:00-17:00',
  website = 'https://muze.gov.tr',
  phone = '+90 258 272 2034',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Pamukkale_Travertines_2014.jpg/1280px-Pamukkale_Travertines_2014.jpg'
  ],
  is_featured = true
WHERE name ILIKE '%pamukkale%';


-- ──────────────────────────────────────────────────────────────────
-- 6. EFES ANTİK KENTİ — İzmir / Selçuk
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Atatürk Mh., Park Cd., 35920 Selçuk/İzmir',
  admission_fee = '40 EUR · Teras Evler ek: 20 EUR',
  opening_hours = 'Yaz: 08:00-19:00 / Kış: 08:30-17:00',
  website = 'https://muze.gov.tr/muze-detay?SectionId=EFS01',
  phone = '+90 232 892 6010',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Celsus-Bibliothek_Ephesos_2017_002.jpg/1280px-Celsus-Bibliothek_Ephesos_2017_002.jpg'
  ],
  is_featured = true
WHERE name ILIKE '%efes%' OR name_en ILIKE '%ephesus%';


-- ──────────────────────────────────────────────────────────────────
-- 7. ANITKABİR — Ankara
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Anıttepe Mh., Akdeniz Cd., 06570 Çankaya/Ankara',
  admission_fee = 'Ücretsiz',
  opening_hours = 'Pazartesi-Pazar: 09:00-17:00 (yaz: 19:00''a kadar)',
  website = 'https://www.tsk.tr/Anitkabir',
  phone = '+90 312 231 7975',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/An%C4%B1tkabir_general_view2.jpg/1280px-An%C4%B1tkabir_general_view2.jpg'
  ],
  is_featured = true,
  is_free = true
WHERE name ILIKE '%anıtkabir%' OR name ILIKE '%anitkabir%';


-- ──────────────────────────────────────────────────────────────────
-- 8. SÜMELA MANASTIRI — Trabzon
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Altındere Vadisi Milli Parkı, 61750 Maçka/Trabzon',
  admission_fee = '15 EUR · Park girişi ek: 5 EUR',
  opening_hours = 'Pazartesi-Pazar: 08:00-18:00 (kış aylarında kar nedeniyle kapanabilir)',
  website = 'https://muze.gov.tr',
  phone = '+90 462 531 1064',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Sumela_Monastery_2009.jpg/1280px-Sumela_Monastery_2009.jpg'
  ],
  is_featured = true
WHERE name ILIKE '%sümela%' OR name ILIKE '%sumela%';


-- ──────────────────────────────────────────────────────────────────
-- 9. DİYARBAKIR SURLARI — Diyarbakır
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Sur İlçesi, 21300 Diyarbakır',
  admission_fee = 'Ücretsiz (UNESCO Dünya Mirası)',
  opening_hours = '24 saat açık (dış görünüm). İç burçlar gündüz erişilebilir.',
  website = 'https://www.diyarbakir.bel.tr',
  phone = '+90 412 251 2055',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Diyarbakir_walls.jpg/1280px-Diyarbakir_walls.jpg'
  ],
  is_featured = true,
  is_free = true
WHERE name ILIKE '%diyarbakır sur%' OR name ILIKE '%diyarbakir wall%';


-- ──────────────────────────────────────────────────────────────────
-- 10. AKDAMAR KİLİSESİ / VAN GÖLÜ — Van
-- ──────────────────────────────────────────────────────────────────
UPDATE places SET
  address = 'Akdamar Adası, Gevaş, 65700 Van',
  admission_fee = '5 EUR (kilise girişi) · Tekne ücreti ayrı',
  opening_hours = 'Yaz: 08:00-19:00 / Kış: 09:00-17:00 (tekne saatlerine bağlı)',
  website = 'https://muze.gov.tr',
  phone = '+90 432 612 5601',
  images = ARRAY[
    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Akdamar_Adasi%2C_Akdamar_Kilisesi_-_panoramio.jpg/1280px-Akdamar_Adasi%2C_Akdamar_Kilisesi_-_panoramio.jpg'
  ],
  is_featured = true
WHERE name ILIKE '%akdamar%' OR name ILIKE '%van göl%';


-- ═══════════════════════════════════════════════════════════════════
-- DEMO YORUMLAR (opsiyonel)
-- ═══════════════════════════════════════════════════════════════════
-- Aşağıdaki INSERT'ler bir 'fake user' adına yorum ekler.
-- Önce sahte bir kullanıcı oluşturmak isterseniz Supabase Auth'ta
-- demo@travixx.com ile bir hesap yaratıp UUID'sini alın, sonra
-- buradaki user_id'leri değiştirin.
--
-- Mevcut kendi kullanıcı id'inizi bulmak için:
-- SELECT id FROM auth.users WHERE email = 'sizin@email.com';
--
-- Bu örnek için yorum eklemeden geçiyoruz. Kullanıcı kendi hesabıyla
-- uygulama içinden yorum yazabilir (UI çalışıyor).
-- ═══════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════
-- KONTROL — Güncellenen mekanları doğrula
-- ═══════════════════════════════════════════════════════════════════
SELECT
  name,
  CASE WHEN address IS NOT NULL THEN '✅' ELSE '❌' END AS adres,
  CASE WHEN opening_hours IS NOT NULL THEN '✅' ELSE '❌' END AS saat,
  CASE WHEN admission_fee IS NOT NULL THEN '✅' ELSE '❌' END AS ücret,
  CASE WHEN website IS NOT NULL THEN '✅' ELSE '❌' END AS web,
  CASE WHEN phone IS NOT NULL THEN '✅' ELSE '❌' END AS tel,
  CASE WHEN array_length(images, 1) > 0 THEN '✅' ELSE '❌' END AS foto,
  is_featured
FROM places
WHERE is_featured = true
ORDER BY name;
