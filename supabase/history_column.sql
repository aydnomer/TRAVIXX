-- Mekanlara detaylı tarihçe metni için kolon
ALTER TABLE public.places ADD COLUMN IF NOT EXISTS history text;

-- (images kolonu zaten var; toplu doldurma script'i bunu da günceller)
