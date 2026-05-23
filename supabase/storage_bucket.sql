-- ═══════════════════════════════════════════════════════════════════
-- Supabase Storage Bucket — travixx-uploads
-- ═══════════════════════════════════════════════════════════════════
-- Bu SQL'i Supabase SQL Editor'da çalıştır.
-- VEYA Dashboard > Storage > New Bucket > 'travixx-uploads' (public)
-- üzerinden manuel oluşturabilirsin.
-- ═══════════════════════════════════════════════════════════════════

-- Bucket oluştur (public read için)
INSERT INTO storage.buckets (id, name, public)
VALUES ('travixx-uploads', 'travixx-uploads', true)
ON CONFLICT (id) DO NOTHING;

-- Policies:
-- 1. Public read (herkes okuyabilir)
DROP POLICY IF EXISTS "public read travixx-uploads" ON storage.objects;
CREATE POLICY "public read travixx-uploads" ON storage.objects
  FOR SELECT USING (bucket_id = 'travixx-uploads');

-- 2. Kullanıcı kendi klasörüne yükleyebilir (path = user_id/...)
DROP POLICY IF EXISTS "own upload travixx-uploads" ON storage.objects;
CREATE POLICY "own upload travixx-uploads" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'travixx-uploads'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. Kullanıcı kendi yüklediğini silebilir
DROP POLICY IF EXISTS "own delete travixx-uploads" ON storage.objects;
CREATE POLICY "own delete travixx-uploads" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'travixx-uploads'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
