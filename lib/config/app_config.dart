// ⚠️  SECURITY RULE
// - agoraAppCertificate  → SERVER ONLY  (never ship in the app binary)
// - stripePublishableKey → Flutter app  (safe to expose)
// - stripeSecretKey      → Lambda env var ONLY (never in Flutter)
// - geminiApiKey         → Flutter app or Lambda (treat as semi-sensitive)

class AppConfig {
  // ── Agora (Live Video/Audio) ─────────────────────────
  static const String agoraAppId = '82cc37a56aad47eea0cb717dc33b9ccd';

  // App Certificate stays on the server — used only by Lambda when
  // generating short-lived RTC tokens for each session.
  // DO NOT call this from Flutter UI code.
  // ignore: unused_field
  static const String _agoraAppCertificate = 'd60f8e3cb2ff4ad1ad379b8d8f08ceac';

  // ── Gemini / Google AI ───────────────────────────────
  static const String geminiApiKey =
      'AQ.Ab8RN6IssmO0dUGsc9mzTFYoXA3cJA4YyZSExhuLRQjwiXHTDQ';

  // ── Stripe Payments ──────────────────────────────────
  // publishableKey: safe to embed in the Flutter app.
  static const String stripePublishableKey =
      'pk_live_51Tk9KTDmusg9yOi4wpo9nGm2xvqUHJOReOx4bEgpDusnKVJzRsztS0QbX7dZitjttnuz87vVlYAnlXKwmLjWvP5Q00KGZppckt';

  // Secret key is NEVER stored here. It lives in Lambda as the
  // environment variable STRIPE_SECRET_KEY.
  // Account ID: acct_1Tk9kTDmusg9y0i4
}
