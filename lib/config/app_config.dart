// ── Compile-time config (injected via --dart-define at build time) ──────────
//
// Production builds MUST supply all three via --dart-define.
// Dev builds use the defaults from tool/run_dev.ps1 which loads .env.local.
//
// Security constraints:
//   - GEMINI_API_KEY   → also required by Lambda; treat as semi-sensitive
//   - AGORA_APP_ID     → public by design (Agora App Certificate is server-only)
//   - STRIPE_PK        → publishable key, safe to embed; secret key is Lambda-only
//
// OWNER: revoke the old hardcoded Gemini key (it was in git history).
//        Generate a new key at aistudio.google.com and put it in Lambda env +
//        pass it here via --dart-define=GEMINI_API_KEY=<newkey>.

class AppConfig {
  // ── Agora (Live Video/Audio) ─────────────────────────
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );

  // ── Gemini / Google AI ───────────────────────────────
  // AiTutorViewmodel routes through the Lambda proxy (ai-chat) and does NOT
  // use this key.  GeminiService (session summaries, AI twins) still reads it
  // directly — supply it via --dart-define for those features to work.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ── Stripe Payments ──────────────────────────────────
  // Publishable key: safe to embed in the Flutter app.
  // Secret key is NEVER stored here — Lambda env var STRIPE_SECRET_KEY only.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PK',
    defaultValue: '',
  );
}
