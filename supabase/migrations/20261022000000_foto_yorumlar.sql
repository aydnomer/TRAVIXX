-- Fotoğraflı yorumlar ve yorumlardan hesaplanan gerçek puan.
-- Tekrar çalıştırılabilir (idempotent).

-- ── Yorum fotoğrafları ───────────────────────────────────────────
-- En çok 4 foto; yalnızca uygulamanın kendi bucket'ına yüklenmiş dosyalar
-- ve yorumu yazanın kendi klasöründekiler (başkasının görseli gösterilemesin).
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS reviews_photos_check;
DROP FUNCTION IF EXISTS public.review_photos_ok(text[]);
CREATE OR REPLACE FUNCTION public.review_photos_ok(p text[], uid uuid)
RETURNS boolean
LANGUAGE sql IMMUTABLE
SET search_path = ''
AS $$
  SELECT coalesce(cardinality(p), 0) <= 4
     AND NOT EXISTS (
       SELECT 1 FROM unnest(coalesce(p, '{}')) u
       WHERE u !~ ('^https://[a-z0-9]+\.supabase\.co/storage/v1/object/public/travixx-uploads/'
                   || uid::text || '/reviews/[^/]+$')
     );
$$;

ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS photos text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.reviews
  ADD CONSTRAINT reviews_photos_check CHECK (public.review_photos_ok(photos, user_id));

-- ── Yorumlardan puan ─────────────────────────────────────────────
-- places.rating elle girilmiş tahmini puan olarak kalır; gerçek kullanıcı
-- puanı ayrı tutulur ve uygulama yorum varsa onu gösterir.
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS review_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS review_avg numeric(2,1);

CREATE OR REPLACE FUNCTION public.refresh_place_review_stats()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  ids uuid[];
BEGIN
  IF TG_OP = 'INSERT' THEN
    ids := ARRAY[NEW.place_id];
  ELSIF TG_OP = 'DELETE' THEN
    ids := ARRAY[OLD.place_id];
  ELSE
    ids := ARRAY[OLD.place_id, NEW.place_id];
  END IF;

  UPDATE public.places p
     SET review_count = s.cnt,
         review_avg = s.avg
    FROM (
      SELECT pid,
             (SELECT count(*) FROM public.reviews r WHERE r.place_id = pid)::int AS cnt,
             (SELECT round(avg(r.rating)::numeric, 1) FROM public.reviews r WHERE r.place_id = pid) AS avg
        FROM unnest(ids) AS pid
       WHERE pid IS NOT NULL
    ) s
   WHERE p.id = s.pid;
  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_place_review_stats() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS reviews_refresh_place_stats ON public.reviews;
CREATE TRIGGER reviews_refresh_place_stats
  AFTER INSERT OR UPDATE OF rating, place_id OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.refresh_place_review_stats();

-- Mevcut yorumlar için ilk hesaplama
UPDATE public.places p
   SET review_count = coalesce(s.cnt, 0),
       review_avg = s.avg
  FROM (
    SELECT p2.id,
           count(r.id)::int AS cnt,
           round(avg(r.rating)::numeric, 1) AS avg
      FROM public.places p2
      LEFT JOIN public.reviews r ON r.place_id = p2.id
     GROUP BY p2.id
  ) s
 WHERE p.id = s.id
   AND (p.review_count IS DISTINCT FROM coalesce(s.cnt, 0)
        OR p.review_avg IS DISTINCT FROM s.avg);

