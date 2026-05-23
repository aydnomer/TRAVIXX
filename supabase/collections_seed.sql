-- ═══════════════════════════════════════════════════════════════════
-- Tematik Koleksiyonlar — Tablolar + Seed Veri
-- ═══════════════════════════════════════════════════════════════════
-- Bu SQL:
-- 1. collections + collection_places tablolarını oluşturur
-- 2. 6 hazır koleksiyon ekler
-- 3. Mevcut places'lara isim eşleştirmesi ile mekanları ekler
-- ═══════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────
-- 1. TABLOLAR
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE,
  name TEXT NOT NULL,
  name_en TEXT,
  emoji TEXT,
  description TEXT,
  description_en TEXT,
  gradient_start TEXT DEFAULT '#1A2744',
  gradient_end TEXT DEFAULT '#F97316',
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS collection_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  place_id UUID REFERENCES places(id) ON DELETE CASCADE,
  display_order INT DEFAULT 0,
  added_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(collection_id, place_id)
);

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_places ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read collections" ON collections;
CREATE POLICY "public read collections" ON collections
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "public read collection_places" ON collection_places;
CREATE POLICY "public read collection_places" ON collection_places
  FOR SELECT USING (true);


-- ──────────────────────────────────────────────────────────────────
-- 2. KOLEKSIYONLARI EKLE (id'leri sonra kullanacağız)
-- ──────────────────────────────────────────────────────────────────
INSERT INTO collections (slug, name, name_en, emoji, description, description_en, gradient_start, gradient_end, display_order)
VALUES
  ('unesco', 'UNESCO Dünya Mirası', 'UNESCO World Heritage', '🏛️',
   'Türkiye''nin UNESCO listesindeki paha biçilmez kültürel ve doğal hazineleri.',
   'Türkiye''s priceless cultural and natural treasures on the UNESCO list.',
   '#7C3AED', '#EAB308', 1),
  ('coast', 'Sahil Tatili', 'Coastal Getaways', '🏖️',
   'Akdeniz ve Ege''nin en güzel sahil şehirleri. Plaj, deniz, güneş.',
   'The most beautiful coastal cities of the Mediterranean and Aegean.',
   '#0891B2', '#67E8F9', 2),
  ('historic', 'Antik Kentler', 'Ancient Cities', '🗿',
   'Bin yıllık antik yerleşimler ve arkeolojik kazı alanları.',
   'Thousand-year-old ancient settlements and archaeological sites.',
   '#78350F', '#FBBF24', 3),
  ('nature', 'Doğa Harikaları', 'Natural Wonders', '🌿',
   'Türkiye''nin nefes kesici doğal güzellikleri ve milli parkları.',
   'Türkiye''s breathtaking natural beauty and national parks.',
   '#14532D', '#4ADE80', 4),
  ('mosques', 'Tarihi Camiler', 'Historic Mosques', '🕌',
   'Osmanlı ve Selçuklu mimarisinin dini eserleri.',
   'Religious works of Ottoman and Seljuk architecture.',
   '#134E4A', '#0D9488', 5),
  ('romantic', 'Romantik Şehirler', 'Romantic Cities', '💕',
   'İki kişilik kaçamak için en büyüleyici Türkiye rotaları.',
   'The most enchanting routes for a romantic escape.',
   '#831843', '#EC4899', 6)
ON CONFLICT (slug) DO NOTHING;


-- ──────────────────────────────────────────────────────────────────
-- 3. KOLEKSIYON ↔ MEKAN BAĞLANTILARI
-- ──────────────────────────────────────────────────────────────────
-- Her koleksiyon için, isim pattern'i eşleşen mekanları junction tablosuna ekle.
-- ON CONFLICT DO NOTHING — tekrarları atlar.

-- UNESCO koleksiyonu
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'unesco'
  AND (
    p.name ILIKE '%pamukkale%' OR
    p.name ILIKE '%efes%' OR p.name_en ILIKE '%ephesus%' OR
    p.name ILIKE '%diyarbakır sur%' OR
    p.name ILIKE '%göbeklitepe%' OR p.name_en ILIKE '%gobekli%' OR
    p.name ILIKE '%nemrut%' OR
    p.name ILIKE '%hattuşa%' OR
    p.name ILIKE '%truva%' OR p.name_en ILIKE '%troy%' OR
    p.name ILIKE '%bursa han%' OR
    p.name ILIKE '%safranbolu%' OR
    p.name ILIKE '%afrodisias%'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;

-- Sahil Tatili
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'coast'
  AND (
    p.name ILIKE '%konyaaltı%' OR
    p.name ILIKE '%antalya%' OR
    p.name ILIKE '%bodrum%' OR
    p.name ILIKE '%ölüdeniz%' OR
    p.name ILIKE '%fethiye%' OR
    p.name ILIKE '%marmaris%' OR
    p.name ILIKE '%çeşme%' OR
    p.name ILIKE '%alanya%' OR
    p.name ILIKE '%kuşadası%' OR
    p.name ILIKE '%kaş%'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;

-- Antik Kentler
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'historic'
  AND (
    p.name ILIKE '%efes%' OR p.name_en ILIKE '%ephesus%' OR
    p.name ILIKE '%truva%' OR p.name_en ILIKE '%troy%' OR
    p.name ILIKE '%antik%' OR p.name ILIKE '%antik kent%' OR
    p.name ILIKE '%hattuşa%' OR
    p.name ILIKE '%afrodisias%' OR
    p.name ILIKE '%bergama%' OR
    p.name ILIKE '%aspendos%' OR
    p.name ILIKE '%side%' OR
    p.name ILIKE '%perge%' OR
    p.name ILIKE '%göbeklitepe%' OR
    p.name ILIKE '%nemrut%' OR
    p.name ILIKE '%hierapolis%' OR
    p.category ILIKE '%antik%'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;

-- Doğa Harikaları
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'nature'
  AND (
    p.category = 'Doğa' OR
    p.name ILIKE '%göl%' OR
    p.name ILIKE '%dağ%' OR
    p.name ILIKE '%şelale%' OR
    p.name ILIKE '%kanyon%' OR
    p.name ILIKE '%pamukkale%' OR
    p.name ILIKE '%uludağ%' OR
    p.name ILIKE '%kaçkar%' OR
    p.name ILIKE '%ayder%' OR
    p.name ILIKE '%sümela%' OR
    p.name ILIKE '%hazar%' OR
    p.name ILIKE '%van göl%'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;

-- Tarihi Camiler
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'mosques'
  AND (
    p.name ILIKE '%cami%' OR
    p.name ILIKE '%ayasofya%' OR
    p.name ILIKE '%mosque%' OR
    p.name_en ILIKE '%mosque%' OR
    p.category = 'Dini'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;

-- Romantik Şehirler
INSERT INTO collection_places (collection_id, place_id, display_order)
SELECT c.id, p.id, ROW_NUMBER() OVER (ORDER BY p.rating DESC NULLS LAST)
FROM collections c, places p
WHERE c.slug = 'romantic'
  AND (
    p.name ILIKE '%kapadokya%' OR
    p.name ILIKE '%göreme%' OR
    p.name ILIKE '%mardin%' OR
    p.name ILIKE '%safranbolu%' OR
    p.name ILIKE '%amasya%' OR
    p.name ILIKE '%ölüdeniz%' OR
    p.name ILIKE '%abant%' OR
    p.name ILIKE '%uzungöl%' OR
    p.name ILIKE '%galata%'
  )
ON CONFLICT (collection_id, place_id) DO NOTHING;


-- ──────────────────────────────────────────────────────────────────
-- 4. KONTROL — Kaç koleksiyon, her birinde kaç mekan?
-- ──────────────────────────────────────────────────────────────────
SELECT
  c.emoji,
  c.name,
  COUNT(cp.place_id) AS place_count
FROM collections c
LEFT JOIN collection_places cp ON cp.collection_id = c.id
GROUP BY c.id, c.emoji, c.name, c.display_order
ORDER BY c.display_order;
