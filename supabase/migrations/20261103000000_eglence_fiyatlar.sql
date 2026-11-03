-- Beach club / gece hayatı alanları ve kullanıcıların bildirdiği fiyatlar.
-- Tekrar çalıştırılabilir (idempotent).

-- ── Mekan alanları (OSM aktarımı doldurur, elle de girilebilir) ───
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS instagram text;
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS reservation_url text;
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS min_age smallint;
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS music text;

-- ── Fiyat bildirimleri ──────────────────────────────────────────
-- Ücretsiz ve yasal bir fiyat kaynağı olmadığı için fiyatlar ziyaretçilerden
-- toplanır: "şezlong 750 TL, 2 gün önce" gibi. Uygulama son 180 günün
-- ortancasını gösterir; tek bir aşırı değer sonucu bozmaz.
CREATE TABLE IF NOT EXISTS public.place_prices (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  place_id    uuid NOT NULL REFERENCES public.places(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  item        text NOT NULL CHECK (item IN (
                'entry', 'sunbed', 'cocktail', 'beer', 'soft_drink',
                'water', 'coffee', 'main_dish', 'other')),
  label       text CHECK (label IS NULL OR char_length(label) <= 60),
  amount      numeric(10, 2) NOT NULL CHECK (amount > 0 AND amount < 1000000),
  currency    text NOT NULL DEFAULT 'TRY' CHECK (currency IN ('TRY', 'EUR', 'USD', 'GBP')),
  note        text CHECK (note IS NULL OR char_length(note) <= 200),
  observed_on date NOT NULL DEFAULT current_date
                CHECK (observed_on <= current_date AND observed_on > current_date - 366),
  created_at  timestamptz NOT NULL DEFAULT now(),
  -- Aynı kişi aynı gün aynı kalem için tek bildirim (spam önlemi)
  UNIQUE (place_id, user_id, item, observed_on)
);

CREATE INDEX IF NOT EXISTS place_prices_place_idx
  ON public.place_prices (place_id, observed_on DESC);
CREATE INDEX IF NOT EXISTS place_prices_user_idx ON public.place_prices (user_id);

ALTER TABLE public.place_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public read place_prices" ON public.place_prices;
CREATE POLICY "public read place_prices" ON public.place_prices
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "own insert place_prices" ON public.place_prices;
CREATE POLICY "own insert place_prices" ON public.place_prices
  FOR INSERT TO authenticated WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "own delete place_prices" ON public.place_prices;
CREATE POLICY "own delete place_prices" ON public.place_prices
  FOR DELETE TO authenticated USING (user_id = (select auth.uid()));

GRANT SELECT ON public.place_prices TO anon, authenticated;
GRANT INSERT, DELETE ON public.place_prices TO authenticated;

-- Mekan + kalem + para birimi başına son 180 günün ortanca fiyatı.
CREATE OR REPLACE VIEW public.place_price_summary
WITH (security_invoker = true) AS
SELECT place_id,
       item,
       currency,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY amount)::numeric(10, 2) AS median,
       min(amount) AS low,
       max(amount) AS high,
       count(*)::int AS reports,
       max(observed_on) AS last_seen
  FROM public.place_prices
 WHERE observed_on > current_date - 180
 GROUP BY place_id, item, currency;

GRANT SELECT ON public.place_price_summary TO anon, authenticated;
