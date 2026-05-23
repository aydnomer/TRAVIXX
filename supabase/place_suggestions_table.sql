-- ═══════════════════════════════════════════════════════════════════
-- Mekan Öneri Tablosu — place_suggestions
-- ═══════════════════════════════════════════════════════════════════
-- Kullanıcılar yeni mekan önerir, admin onayı bekler.
-- Onaylananlar manuel olarak places tablosuna eklenir.
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS place_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  user_email TEXT,
  city_id UUID REFERENCES cities(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  address TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- Row Level Security
ALTER TABLE place_suggestions ENABLE ROW LEVEL SECURITY;

-- Kullanıcı kendi önerilerini okuyabilir
DROP POLICY IF EXISTS "own suggestions read" ON place_suggestions;
CREATE POLICY "own suggestions read" ON place_suggestions
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcı yeni öneri ekleyebilir (sadece kendi user_id'siyle)
DROP POLICY IF EXISTS "own suggestions insert" ON place_suggestions;
CREATE POLICY "own suggestions insert" ON place_suggestions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kullanıcı kendi pending önerisini silebilir
DROP POLICY IF EXISTS "own pending delete" ON place_suggestions;
CREATE POLICY "own pending delete" ON place_suggestions
  FOR DELETE USING (auth.uid() = user_id AND status = 'pending');

-- Admin paneline gerek olmadan Supabase Studio'dan da onaylayabilirsin:
-- UPDATE place_suggestions SET status='approved', reviewed_at=now() WHERE id='...';
