-- ═══════════════════════════════════════════════════════════════════
-- Travixx — OpenStreetMap'ten toplu mekan aktarımı için şema
-- ═══════════════════════════════════════════════════════════════════
-- Aktarım script'i: tool/import_osm.dart (GitHub Actions'tan çalışır).
-- OSM'den gelen kayıtlar `osm_ref` ile tekilleşir; elle girilmiş
-- (source = 'travixx') kayıtlara script dokunmaz.
-- Tekrar çalıştırılması güvenlidir.
-- ═══════════════════════════════════════════════════════════════════

BEGIN;

ALTER TABLE public.places ADD COLUMN IF NOT EXISTS source      text NOT NULL DEFAULT 'travixx';
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS osm_ref     text;   -- ör. "node/123", "way/456"
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS subcategory text;   -- ör. "Şelale", "Antik Kent"
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS wikidata    text;   -- ör. "Q12506"
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS wikipedia   text;   -- ör. "tr:Ayasofya"
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS updated_at  timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS places_osm_ref_key ON public.places (osm_ref);
CREATE INDEX IF NOT EXISTS places_lat_lng_idx ON public.places (latitude, longitude);
CREATE INDEX IF NOT EXISTS places_category_idx ON public.places (category);

-- Puanı olmayan (yeni aktarılan) mekanlar sahte 4.5 almasın.
-- Gerçek puan ileride yorumlardan hesaplanacak; 0 = henüz puan yok.
ALTER TABLE public.places ALTER COLUMN rating SET DEFAULT 0;

-- ─── Yakındaki mekanlar ─────────────────────────────────────────
-- Ana sayfa tüm tabloyu indirip istemcide sıralıyordu; binlerce
-- mekanda bu mümkün değil (PostgREST zaten 1000 satırda keser).
CREATE OR REPLACE FUNCTION public.nearby_places(
  p_lat double precision,
  p_lng double precision,
  p_limit integer DEFAULT 20,
  p_categories text[] DEFAULT NULL,
  p_radius_km double precision DEFAULT 300
)
RETURNS SETOF public.places
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT p.*
  FROM public.places p
  WHERE p.latitude  BETWEEN p_lat - p_radius_km / 111.0 AND p_lat + p_radius_km / 111.0
    AND p.longitude BETWEEN p_lng - p_radius_km / (111.0 * cos(radians(p_lat)))
                        AND p_lng + p_radius_km / (111.0 * cos(radians(p_lat)))
    AND (p_categories IS NULL OR p.category = ANY (p_categories))
  ORDER BY
    -- Haversine (km)
    6371 * 2 * asin(sqrt(
      power(sin(radians(p.latitude - p_lat) / 2), 2) +
      cos(radians(p_lat)) * cos(radians(p.latitude)) *
      power(sin(radians(p.longitude - p_lng) / 2), 2)
    ))
  LIMIT least(greatest(p_limit, 1), 200);
$$;
GRANT EXECUTE ON FUNCTION public.nearby_places(double precision, double precision, integer, text[], double precision)
  TO anon, authenticated;

COMMIT;
