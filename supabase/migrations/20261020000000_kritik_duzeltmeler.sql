-- ═══════════════════════════════════════════════════════════════════
-- Travixx — Kritik düzeltmeler (analiz raporu, Ekim 2026)
-- ═══════════════════════════════════════════════════════════════════
-- Bu dosya, aynı PR'daki uygulama kodundan ÖNCE canlı veritabanına
-- uygulanmalıdır (yorumlar artık user_name ve updated_at kullanıyor).
-- Supabase Dashboard > SQL Editor'e yapıştırıp çalıştırabilirsin.
-- Tekrar çalıştırılması güvenlidir (idempotent).
-- ═══════════════════════════════════════════════════════════════════

BEGIN;

-- ─── 1. Kategori yazımları ───────────────────────────────────────
-- Uygulama "Doğa", "Müze" arıyordu; veritabanında "Doga", "Muze" vardı.
UPDATE public.places SET category = 'Doğa'      WHERE category = 'Doga';
UPDATE public.places SET category = 'Müze'      WHERE category = 'Muze';
UPDATE public.places SET category = 'Kültür'    WHERE category = 'Kultur';
UPDATE public.places SET category = 'Alışveriş' WHERE category = 'Alisveris';
UPDATE public.place_suggestions SET category = 'Doğa'   WHERE category = 'Doga';
UPDATE public.place_suggestions SET category = 'Müze'   WHERE category = 'Muze';
UPDATE public.place_suggestions SET category = 'Kültür' WHERE category = 'Kultur';

-- ─── 2. Yorumlar: düzenleme hatası + e-posta gizliliği ──────────
-- reviews_updated_at tetikleyicisi updated_at sütununa yazıyordu ama
-- sütun yoktu; her güncelleme hata veriyordu.
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Tam e-posta herkese açık tablodaydı; yerine sadece görünen ad tutulur.
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS user_name text;
ALTER TABLE public.community_posts ADD COLUMN IF NOT EXISTS user_name text;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'reviews' AND column_name = 'user_email') THEN
    UPDATE public.reviews SET user_name = split_part(user_email, '@', 1)
      WHERE user_name IS NULL AND user_email IS NOT NULL;
    ALTER TABLE public.reviews DROP COLUMN user_email;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'community_posts' AND column_name = 'user_email') THEN
    UPDATE public.community_posts SET user_name = split_part(user_email, '@', 1)
      WHERE user_name IS NULL AND user_email IS NOT NULL;
    ALTER TABLE public.community_posts DROP COLUMN user_email;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ─── 3. QR sistemi ───────────────────────────────────────────────
-- QR içeriği artık mekan id'si (…/#/qr/<place_id>). has_qr=true olan
-- mekanlar için qr_codes kaydı oluştur ki tarama sayısı tutulsun.
INSERT INTO public.qr_codes (place_id, qr_data)
SELECT id, id::text FROM public.places WHERE has_qr
ON CONFLICT (qr_data) DO NOTHING;

-- Tarama sayacını atomik artırır. Kod, qr_data veya mekan id'si olabilir.
-- (İstemcide UPDATE izni yok; sadece bu fonksiyon sayacı değiştirebilir.)
CREATE OR REPLACE FUNCTION public.increment_qr_scan(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.qr_codes SET scan_count = scan_count + 1 WHERE qr_data = p_code;
  IF NOT FOUND AND p_code ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     AND EXISTS (SELECT 1 FROM public.places WHERE id = p_code::uuid) THEN
    INSERT INTO public.qr_codes (place_id, qr_data, scan_count)
    VALUES (p_code::uuid, p_code, 1)
    ON CONFLICT (qr_data) DO UPDATE SET scan_count = public.qr_codes.scan_count + 1;
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.increment_qr_scan(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_qr_scan(text) TO anon, authenticated;

-- ─── 4. Bildirimler ──────────────────────────────────────────────
-- Hoş geldin bildirimi tetikleyicisi canlıda yoktu.
CREATE OR REPLACE FUNCTION public.send_welcome_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, link)
  VALUES (
    NEW.id,
    'welcome',
    'Travixx''e Hoş Geldin! 🎉',
    'Hadi ilk mekanını keşfet — şehirler listesine göz at!',
    '/cities'
  );
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_user_signup_welcome ON auth.users;
CREATE TRIGGER on_user_signup_welcome
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.send_welcome_notification();

-- Canlı bildirim akışı için realtime yayınına ekle
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                 WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- ─── 5. Güvenlik danışmanı uyarıları ─────────────────────────────
-- Tetikleyici fonksiyonları REST üzerinden çağrılamasın.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.send_welcome_notification() FROM PUBLIC, anon, authenticated;

-- Kullanıcı kendi yüklediği fotoğrafı silebilsin (canlıda eksikti)
DROP POLICY IF EXISTS "own delete travixx-uploads" ON storage.objects;
CREATE POLICY "own delete travixx-uploads" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'travixx-uploads'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Aynı işi yapan yinelenen kurallar (elle iki kez kurulmuştu)
DROP POLICY IF EXISTS "own insert review" ON public.reviews;
DROP POLICY IF EXISTS "own update review" ON public.reviews;
DROP POLICY IF EXISTS "own delete review" ON public.reviews;
DROP POLICY IF EXISTS "public read reviews" ON public.reviews;
DROP POLICY IF EXISTS "Kullanici ziyaret ekleyebilir" ON public.visits;
DROP POLICY IF EXISTS "Kullanici kendi ziyaretlerini gorebilir" ON public.visits;
DROP POLICY IF EXISTS "Giriş yapan ekleyebilir" ON public.community_posts;
DROP POLICY IF EXISTS "Kendi yazısını silebilir" ON public.community_posts;

-- ─── 6. İndeksler (en sık sorgulanan foreign key'ler) ───────────
CREATE INDEX IF NOT EXISTS places_city_id_idx            ON public.places (city_id);
CREATE INDEX IF NOT EXISTS favorites_place_id_idx        ON public.favorites (place_id);
CREATE INDEX IF NOT EXISTS visits_user_id_idx            ON public.visits (user_id);
CREATE INDEX IF NOT EXISTS visits_place_id_idx           ON public.visits (place_id);
CREATE INDEX IF NOT EXISTS qr_codes_place_id_idx         ON public.qr_codes (place_id);
CREATE INDEX IF NOT EXISTS collection_places_place_id_idx ON public.collection_places (place_id);
CREATE INDEX IF NOT EXISTS diary_entries_diary_id_idx    ON public.diary_entries (diary_id);
CREATE INDEX IF NOT EXISTS notifications_user_created_idx ON public.notifications (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS community_posts_user_id_idx   ON public.community_posts (user_id);

-- ─── 7. Veri düzeltmeleri ────────────────────────────────────────
-- Şehirlerdeki mekan sayısı elle tutuluyordu ve 11 ilde yanlıştı.
UPDATE public.cities c
SET place_count = (SELECT count(*) FROM public.places p WHERE p.city_id = c.id);

CREATE OR REPLACE FUNCTION public.refresh_city_place_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.cities c
  SET place_count = (SELECT count(*) FROM public.places p WHERE p.city_id = c.id)
  WHERE c.id IN (
    CASE WHEN TG_OP <> 'INSERT' THEN OLD.city_id END,
    CASE WHEN TG_OP <> 'DELETE' THEN NEW.city_id END
  );
  RETURN NULL;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.refresh_city_place_count() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS places_refresh_city_count ON public.places;
CREATE TRIGGER places_refresh_city_count
  AFTER INSERT OR DELETE OR UPDATE OF city_id ON public.places
  FOR EACH ROW EXECUTE FUNCTION public.refresh_city_place_count();

-- Demo seed, İstanbul Ayasofya'nın bilgilerini Trabzon Ayasofya'ya da
-- yazmıştı (ILIKE '%ayasofya%'). Trabzon kaydındaki yanlış alanları temizle.
UPDATE public.places p
SET address = NULL, admission_fee = NULL, opening_hours = NULL,
    website = NULL, phone = NULL, images = NULL, is_featured = false
FROM public.cities c
WHERE p.city_id = c.id AND c.name = 'Trabzon' AND p.name ILIKE '%ayasofya%'
  AND p.address ILIKE '%Sultan Ahmet%';

COMMIT;
