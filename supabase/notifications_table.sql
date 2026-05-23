-- ═══════════════════════════════════════════════════════════════════
-- Bildirimler Tablosu — notifications
-- ═══════════════════════════════════════════════════════════════════
-- In-app bildirim sistemi. Realtime stream ile UI'a anlık akar.
-- Bildirimler:
--   - badge_earned: kullanıcı rozet kazandı
--   - new_review: kullanıcının mekanına yorum geldi (gelecek özellik)
--   - nearby_place: kullanıcı bir mekana yakın (gelecek özellik)
--   - welcome: kayıt sonrası karşılama
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'general',
  title TEXT NOT NULL,
  body TEXT,
  link TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON notifications(user_id, is_read);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi bildirimlerini okuyabilir
DROP POLICY IF EXISTS "own notifications read" ON notifications;
CREATE POLICY "own notifications read" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcı kendi bildirimlerini okundu işaretleyebilir
DROP POLICY IF EXISTS "own notifications update" ON notifications;
CREATE POLICY "own notifications update" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Auth.users insert sonrası 'welcome' bildirimi otomatik oluşturulur (trigger)
CREATE OR REPLACE FUNCTION send_welcome_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (user_id, type, title, body, link)
  VALUES (
    NEW.id,
    'welcome',
    'Travixx''e Hoş Geldin! 🎉',
    'Hadi ilk mekanını keşfet — şehirler listesine göz at!',
    '/cities'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_signup_welcome ON auth.users;
CREATE TRIGGER on_user_signup_welcome
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION send_welcome_notification();

-- Realtime aktif et (Dashboard > Database > Replication > notifications)
-- Veya:
-- ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
