// Travixx — Gemini proxy (Supabase Edge Function)
//
// API anahtarı istemciye (web build'e) hiç gitmez; burada secret olarak durur.
//
// Kurulum (bir kere):
//   supabase secrets set GEMINI_API_KEY=<yeni anahtar>
//   supabase functions deploy gemini-chat
// İsteğe bağlı: supabase secrets set GEMINI_MODEL=<model adı>
//
// İstek gövdesi:
//   { "mode": "chat",  "message": "...", "lang": "tr", "history": [{ "role": "user"|"model", "text": "..." }] }
//   { "mode": "intro", "cityName": "...", "days": 2, "placeNames": ["..."], "lang": "tr" }
// Yanıt: { "text": "..." }  veya  { "error": "..." }

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const LANG_NAMES: Record<string, string> = {
  tr: "Türkçe",
  en: "English",
  de: "Deutsch",
  ar: "العربية",
  fr: "Français",
  ru: "Русский",
};

const MAX_MESSAGE = 1000;
const MAX_HISTORY = 10;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

type Turn = { role: "user" | "model"; text: string };

async function callGemini(
  contents: { role: string; parts: { text: string }[] }[],
  systemText: string,
  temperature: number,
  maxOutputTokens: number,
): Promise<string | null> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemText }] },
        contents,
        generationConfig: { temperature, maxOutputTokens },
      }),
    },
  );
  if (!res.ok) {
    console.error("Gemini error", res.status, await res.text());
    return null;
  }
  const data = await res.json();
  const parts = data?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return null;
  const text = parts.map((p: { text?: string }) => p.text ?? "").join("").trim();
  return text.length > 0 ? text : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!GEMINI_API_KEY) return json({ error: "not_configured" }, 500);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_json" }, 400);
  }

  const lang = typeof body.lang === "string" && LANG_NAMES[body.lang] ? body.lang : "tr";
  const langName = LANG_NAMES[lang];

  if (body.mode === "intro") {
    const cityName = String(body.cityName ?? "").slice(0, 80);
    const days = Math.min(Math.max(Number(body.days) || 1, 1), 7);
    const placeNames = Array.isArray(body.placeNames)
      ? body.placeNames.slice(0, 6).map((p) => String(p).slice(0, 80))
      : [];
    if (!cityName) return json({ error: "missing_city" }, 400);

    const system =
      `Sen Travixx adlı Türkiye turizm uygulamasının asistanısın. Yanıtı yalnızca ${langName} dilinde yaz.`;
    const prompt =
      `Kullanıcı ${cityName} için ${days} günlük bir gezi planı istedi. ` +
      `Önerilen mekanlar: ${placeNames.join(", ")}. ` +
      `Kısa, samimi ve heyecanlı bir giriş metni yaz (2-3 cümle). ` +
      `Şehrin en önemli özelliğinden bahset. Emoji kullan. Rota listesini tekrar yazma.`;
    const text = await callGemini(
      [{ role: "user", parts: [{ text: prompt }] }],
      system,
      0.8,
      300,
    );
    return text ? json({ text }) : json({ error: "upstream_failed" }, 502);
  }

  if (body.mode === "chat") {
    const message = String(body.message ?? "").trim().slice(0, MAX_MESSAGE);
    if (!message) return json({ error: "missing_message" }, 400);

    const history: Turn[] = Array.isArray(body.history)
      ? (body.history as Turn[])
        .filter((t) => (t?.role === "user" || t?.role === "model") && typeof t?.text === "string")
        .slice(-MAX_HISTORY)
      : [];
    // Konuşma kullanıcı mesajıyla başlamalı (karşılama mesajı vb. at)
    while (history.length > 0 && history[0].role === "model") history.shift();

    const system =
      "Sen Travixx adlı Türkiye turizm uygulamasının yapay zeka asistanısın. " +
      "Türkiye'deki şehirler, tarihi mekanlar, müzeler, doğal güzellikler ve gezilecek yerler hakkında yardımcı olursun. " +
      "Emin olmadığın bilgileri (fiyat, saat) kesinmiş gibi söyleme. " +
      `Kısa, samimi ve yardımsever cevaplar ver. Yanıtı yalnızca ${langName} dilinde yaz.`;
    const contents = [
      ...history.map((t) => ({ role: t.role, parts: [{ text: t.text.slice(0, MAX_MESSAGE) }] })),
      { role: "user", parts: [{ text: message }] },
    ];
    const text = await callGemini(contents, system, 0.9, 600);
    return text ? json({ text }) : json({ error: "upstream_failed" }, 502);
  }

  return json({ error: "unknown_mode" }, 400);
});
