-- Mekan içeriğinin 6 dildeki karşılıkları (Wikipedia dil sürümlerinden).
-- Tekrar çalıştırılabilir (idempotent).

CREATE TABLE IF NOT EXISTS public.place_translations (
  place_id    uuid NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  lang        text NOT NULL CHECK (lang IN ('tr', 'en', 'de', 'ar', 'fr', 'ru')),
  name        text,
  description text,
  history     text,
  source      text NOT NULL DEFAULT 'wikipedia',
  source_url  text,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (place_id, lang)
);

ALTER TABLE public.place_translations ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir; yazma yalnızca service_role (aktarım betiği) ile.
DROP POLICY IF EXISTS "public read place_translations" ON public.place_translations;
CREATE POLICY "public read place_translations" ON public.place_translations
  FOR SELECT TO anon, authenticated USING (true);

GRANT SELECT ON public.place_translations TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.place_translations FROM anon, authenticated;
