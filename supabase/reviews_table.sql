-- Reviews tablosu
CREATE TABLE IF NOT EXISTS public.reviews (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  place_id    text        NOT NULL,
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating      int         NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment     text        NOT NULL DEFAULT '',
  user_email  text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  UNIQUE (place_id, user_id)  -- bir kullanıcı bir mekana tek yorum
);

-- updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reviews_updated_at ON public.reviews;
CREATE TRIGGER reviews_updated_at
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS aktif
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "reviews_select_all"
  ON public.reviews FOR SELECT
  USING (true);

-- Giriş yapan kullanıcı kendi yorumunu ekleyebilir
CREATE POLICY "reviews_insert_own"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Giriş yapan kullanıcı kendi yorumunu güncelleyebilir
CREATE POLICY "reviews_update_own"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Giriş yapan kullanıcı kendi yorumunu silebilir
CREATE POLICY "reviews_delete_own"
  ON public.reviews FOR DELETE
  USING (auth.uid() = user_id);

-- İndeksler (performans)
CREATE INDEX IF NOT EXISTS reviews_place_id_idx ON public.reviews (place_id);
CREATE INDEX IF NOT EXISTS reviews_user_id_idx  ON public.reviews (user_id);
CREATE INDEX IF NOT EXISTS reviews_created_at_idx ON public.reviews (created_at DESC);
