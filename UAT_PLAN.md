# Torino Todd — UAT Plan
**Branch:** fix/remediation-v1  
**Updated:** 2026-10-06

Test users (credentials in `.env.test`, gitignored):

| Role    | Email                  |
|---------|------------------------|
| Student | student@torino.test    |
| Teacher | teacher@torino.test    |
| Mentor  | mentor@torino.test     |
| Admin   | admin@torino.test      |

---

## Status legend
- `PASS` — verified on device
- `FAIL` — broken, needs fix
- `BLOCKED` — dependency missing, not a code defect
- `SKIP` — out of scope for this UAT round

---

## 1. Authentication

| # | Test | Status | Notes |
|---|------|--------|-------|
| 1.1 | Student login → routed to student home | | |
| 1.2 | Teacher login → routed to teacher home | | |
| 1.3 | Mentor login → routed to mentor home | | |
| 1.4 | Admin login → routed to admin panel | | |
| 1.5 | Wrong password → error shown | | |
| 1.6 | App restart → correct role preserved | | |
| 1.7 | Logout → tokens cleared, returns to login | | |

---

## 2. Mentor Profile

| # | Test | Status | Notes |
|---|------|--------|-------|
| 2.1 | Mentor home shows name, bio | | |
| 2.2 | Experience field shows value (not `--`) | | |
| 2.3 | Language field shows value (not `--`) | | |
| 2.4 | Hourly rate shows value (not `--`) | | |
| 2.5 | Average rating shows value (not `--`) | | |

---

## 3. Student Search (1-on-1 sessions)

| # | Test | Status | Notes |
|---|------|--------|-------|
| 3.1 | Search field appears in session creation | | |
| 3.2 | Typing ≥2 chars returns student results | | |
| 3.3 | Tapping a result selects the student | | |
| 3.4 | Query <2 chars shows no results / prompt | | |

---

## 4. Session Booking & Payment

| # | Test | Status | Notes |
|---|------|--------|-------|
| 4.1 | Student selects mentor + time slot | | |
| 4.2 | Session created in backend before Stripe sheet | | |
| 4.3 | Stripe PaymentSheet appears | BLOCKED | Stripe keys not yet set |
| 4.4 | Successful payment → session confirmed | BLOCKED | Stripe keys not yet set |
| 4.5 | Cancelled payment → session marked cancelled | BLOCKED | Stripe keys not yet set |
| 4.6 | Mentor earnings credited after payment | BLOCKED | Stripe keys not yet set |

---

## 5. Course Purchase

| # | Test | Status | Notes |
|---|------|--------|-------|
| 5.1 | Student browses courses | | |
| 5.2 | Tap purchase → Stripe PaymentSheet | BLOCKED | Stripe keys not yet set |
| 5.3 | Successful payment → student enrolled | BLOCKED | Stripe keys not yet set |
| 5.4 | Teacher earnings credited | BLOCKED | Stripe keys not yet set |
| 5.5 | Duplicate purchase blocked | BLOCKED | Stripe keys not yet set |

---

## 6. Live Sessions (Agora)

| # | Test | Status | Notes |
|---|------|--------|-------|
| 6.1 | Mentor starts session → Agora channel joins | | |
| 6.2 | Student joins session → sees/hears mentor | | |
| 6.3 | Camera / mic permissions requested | | |
| 6.4 | Session ends → both users exit cleanly | | |

---

## 7. Push Notifications

| # | Test | Status | Notes |
|---|------|--------|-------|
| 7.1 | In-app notification banner appears (foreground) | BLOCKED | Firebase / google-services.json not yet set up |
| 7.2 | Background notification received | BLOCKED | Firebase / google-services.json not yet set up |
| 7.3 | Tapping notification navigates to correct screen | BLOCKED | Firebase / google-services.json not yet set up |
| 7.4 | Session booking triggers push to mentor | BLOCKED | Firebase + SNS_PLATFORM_APP_ARN not set |

---

## 8. AI Features

| # | Test | Status | Notes |
|---|------|--------|-------|
| 8.1 | AI Tutor / chat responds | BLOCKED | Gemini key not yet provided |
| 8.2 | AI Twins responds | BLOCKED | Gemini key not yet provided |
| 8.3 | Session summary generated | BLOCKED | Gemini key not yet provided |
| 8.4 | AI Memory / knowledge graph | BLOCKED | Gemini key not yet provided |
| 8.5 | Session transcription | BLOCKED | Gemini key not yet provided |

---

## 9. Admin Panel

| # | Test | Status | Notes |
|---|------|--------|-------|
| 9.1 | Admin login rejected for non-admin role | | |
| 9.2 | Admin can list users | | |
| 9.3 | Admin can list sessions | | |
| 9.4 | Non-admin cannot access admin endpoints | | |

---

## 10. Wallet

| # | Test | Status | Notes |
|---|------|--------|-------|
| 10.1 | Wallet balance displays | | |
| 10.2 | Deduction with sufficient balance succeeds | | |
| 10.3 | Deduction with insufficient balance returns 402 | | |
| 10.4 | Duplicate deduction (same idempotencyKey) is no-op | | |

---

## Blocked features summary

| Feature | Blocked by |
|---------|-----------|
| Stripe PaymentSheet, payments, webhooks | Stripe keys not set |
| Push notifications (FCM) | `google-services.json` + Firebase project |
| Push delivery (SNS) | `SNS_PLATFORM_APP_ARN` not set |
| AI Tutor, AI Twins, summaries, transcription, memory | Gemini API key not set |
| APK release build | `google-services.json` missing |

---

## Owner actions to unblock

1. **Firebase** — create project at console.firebase.google.com → download `google-services.json` → place at `android/app/google-services.json`
2. **Stripe** — provide `STRIPE_SECRET_KEY` + `STRIPE_WEBHOOK_SECRET` → set on `torino-api` Lambda
3. **Gemini** — provide new `GEMINI_API_KEY` → set on: `toriino-ai-chat`, `toriino-ai-twins`, `toriino-ai-memory`, `toriino-ai-summaries`, `toriino-transcribe-processor`
4. **SNS** — after Firebase: create FCM platform app in SNS → set `SNS_PLATFORM_APP_ARN` on `torino-api`
