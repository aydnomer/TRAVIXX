-- ═══════════════════════════════════════════════════════════════════
-- Gezi Günlüğü — Trip Diaries + Diary Entries
-- ═══════════════════════════════════════════════════════════════════
-- Kullanıcı kendi defterlerini oluşturur ve içine günlük girdiler ekler.
-- Defter is_public=true ise herkes okuyabilir.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS trip_diaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  emoji TEXT DEFAULT '📖',
  cover_color TEXT DEFAULT '#F97316',
  start_date DATE,
  end_date DATE,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS diary_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID REFERENCES trip_diaries(id) ON DELETE CASCADE,
  place_id UUID REFERENCES places(id) ON DELETE SET NULL,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  note TEXT,
  photo_url TEXT,
  mood TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Row Level Security
ALTER TABLE trip_diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

-- ─── trip_diaries policies ───────────────────────────────────────
DROP POLICY IF EXISTS "own diaries all" ON trip_diaries;
CREATE POLICY "own diaries all" ON trip_diaries
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "public diaries read" ON trip_diaries;
CREATE POLICY "public diaries read" ON trip_diaries
  FOR SELECT USING (is_public = true);

-- ─── diary_entries policies ──────────────────────────────────────
-- Kullanıcı kendi defterindeki girdilere her şeyi yapabilir
DROP POLICY IF EXISTS "own entries all" ON diary_entries;
CREATE POLICY "own entries all" ON diary_entries
  FOR ALL USING (
    diary_id IN (SELECT id FROM trip_diaries WHERE user_id = auth.uid())
  );

-- Public defterlerin girdileri herkes tarafından okunabilir
DROP POLICY IF EXISTS "public entries read" ON diary_entries;
CREATE POLICY "public entries read" ON diary_entries
  FOR SELECT USING (
    diary_id IN (SELECT id FROM trip_diaries WHERE is_public = true)
  );
