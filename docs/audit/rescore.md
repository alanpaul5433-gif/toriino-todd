# Re-audit Report — 2026-10-03

Original score: 33/100
Re-scored: **72/100**

---

## Release Gates

| Gate | Description | Code Status | Owner Action Required |
|------|-------------|------------|----------------------|
| GATE-01 | Gemini key not hardcoded | ✅ PASS (code) | Revoke old key at aistudio.google.com; set `GEMINI_API_KEY` in ai-chat Lambda env; pass `--dart-define=GEMINI_API_KEY=<newkey>` at build time |
| GATE-02 | No infinite spinner on cold restart | ✅ PASS | — |
| GATE-03 | Teacher role persists after role selection | ✅ PASS | — |
| GATE-04 | App compiles (0 errors) | ✅ PASS | — |
| GATE-05 | S3 upload doesn't expose credentials | ✅ PASS (code) | Block public PUT + public ACLs on `torino-app-storage` bucket; set `S3_BUCKET` env var on upload-url Lambda |
| GATE-06 | No bank data collected | ✅ PASS | — |

**Code-side: 4/6 gates fully resolved (no owner action) · 2/6 require owner action (GATE-01, GATE-05)**

---

## Critical Issues

| ID | Issue | Fix Applied | Status | Notes |
|----|-------|-------------|--------|-------|
| C01 | Gemini key hardcoded | P2-1 | ✅ CLOSED | `geminiApiKey` → `String.fromEnvironment('GEMINI_API_KEY', defaultValue: '')` in `app_config.dart` |
| C02 | Agora token crash (null cast) | P4-2 | ✅ CLOSED | `live_session_screen.dart:97` — `data['token'] as String?` + null/empty guard + descriptive exception |
| C03 | Course list crashes on null | P4-1 | ✅ CLOSED | `(json['x'] as List? ?? [])` null-safe cast in all list-response models |
| C04 | Null list in model fromJson | P4-1 | ✅ CLOSED | Same null-safe cast applied to all 4 affected models |
| C05 | Hardcoded course list (no API) | P8-2 | ✅ CLOSED | `my_taken_cousre_view.dart` — 5 static widgets replaced with `FutureBuilder` → `CourseRepo().getLessons()` |
| C06 | Missing payments Lambda | P5-1 | ✅ CLOSED (code) | `aws-backend/lambda/payments/index.js` created; owner must set `STRIPE_SECRET_KEY` + wire API Gateway route |
| C07 | Hardcoded API URL | P1-1 | ✅ CLOSED | `AppUrl.baseUrl` → `String.fromEnvironment('API_BASE_URL', defaultValue: …)` |
| C08 | Stripe key hardcoded | P2-4 | ✅ CLOSED | `stripePublishableKey` → `String.fromEnvironment('STRIPE_PK', defaultValue: '')` |
| C09 | Language field missing in course | P6-1 | ✅ CLOSED | `selectedLanguage` added to viewmodel and `CourseModel`; wired through create + edit flows |
| C10 | SVG asset crash | P4-3 | ✅ CLOSED | `SvgPicture.asset('assets/icons/plus-sign.svg')` → `const Icon(Icons.add, size: 20)` |

**All 10 Critical items closed.**

---

## Dimension Re-scores

| # | Dimension | Original | Re-scored | Delta | Rationale |
|---|-----------|:-------:|:---------:|:-----:|-----------|
| 1 | Auth & session security | 2 | 7.5 | +5.5 | All three gates resolved in code: Gemini/Agora/Stripe keys moved to dart-define; token refresh + null-safety; role routing fixed. Owner must revoke old key. |
| 2 | Backend API design | 4 | 8 | +4 | Single `String.fromEnvironment` base URL; dead DynamoDB service deleted; prod/dev mismatch eliminated; clean URL catalogue in `app_url.dart`. |
| 3 | State management | 5 | 7 | +2 | Dead `SplashServices`/`LoginViewmodel` deleted; `UsersPrefrence` stripped to role-only; 16 controllers + FocusNodes moved to State and disposed; Obx bindings audited. Minor: some controllers still use fire-and-forget Futures. |
| 4 | Error handling & resilience | 3 | 7 | +4 | 401 single-flight retry on all verbs; splash token-refresh fallback; null-safe list casts; Agora/S3 descriptive errors; `flutter analyze`: 0 errors. |
| 5 | Payment processing | 2 | 6.5 | +4.5 | Payments Lambda created; Stripe key removed from binary; webhook Lambda with idempotency + sig verify; subscription flow unblocked. Owner must wire API Gateway route + set secret key. |
| 6 | Data security | 2 | 8 | +6 | Gemini/Stripe/Agora keys all dart-define; S3 pre-signed URL (no creds in app, no `x-amz-acl: public-read`); bank fields removed. Owner must block S3 public ACLs + revoke old Gemini key. |
| 7 | Teacher flows | 3 | 7 | +4 | Language field end-to-end; delete cascade + enrollment guard; profile-setup validation enforced; edit-course language dropdown. |
| 8 | Mentor flows | 3 | 6.5 | +3.5 | Availability save success-only nav; Start Session wired; public/private profile null-guarded + Obx-bound. Experience/hourlyRate/language still show `'--'` (owner must add Lambda fields). |
| 9 | Student flows | 3 | 6.5 | +3.5 | Dynamic lesson list via FutureBuilder; course list API-driven; no hardcoded names. Rating still `'--'` (no rating field in models — owner-blocked). |
| 10 | Real-time sessions | 5 | 7.5 | +2.5 | Agora token null-guard; wallet balance check before booking; session recording endpoints added. 2-device smoke test still owner responsibility (P11-3). |
| 11 | Notifications | 2 | 6 | +4 | FCM fully wired (`firebase_messaging`); `FcmService` init + background handler + token refresh; register-device Lambda created; named-route deep-link stub. Owner must supply `google-services.json`; Gradle build blocked until then. |
| 12 | Navigation | 4 | 7 | +3 | 5 named-route constants + 5 `GetPage` entries + 2 call sites converted to `Get.toNamed()`; `NotificationRouter.handleTap()` stub. Remaining direct `Get.to()` calls not yet converted. |
| 13 | Testing | 1 | 5.5 | +4.5 | 60 tests passing (was 9): models, JWT expiry logic, login widget smoke. CI runs `flutter test --coverage`. No integration tests; no widget tests for teacher/mentor flows. |
| 14 | CI/CD | 2 | 6 | +4 | `.github/workflows/flutter.yml` created; `flutter test --coverage` + coverage reporting; linting step. No deployment step; no branch protection rules (owner must configure). |
| 15 | Documentation | 1 | 7 | +6 | `README.md`, `ARCHITECTURE.md`, `API.md`, `CHANGELOG.md`, `RUNBOOK.md` all created; `docs/audit/unknowns.md` with full findings. |
| 16 | Performance | 3 | 5.5 | +2.5 | Cursor pagination on courses Lambda + Flutter client; no hardcoded lists. Memory leak (controllers/FocusNodes) fixed for profile setup. No image caching strategy; no debounce on search. |
| 17 | i18n | 1 | 4 | +3 | `flutter_localizations` + `intl` added; `app_en.arb` (8 keys); `l10n.yaml`; delegates wired in `GetMaterialApp`. Only 8 keys — far from complete coverage. |
| 18 | Observability | 1 | 6 | +5 | Crashlytics + `FlutterError.onError` + `PlatformDispatcher.onError` wired; `AnalyticsService` (4 events); structured JSON logs in 4 Lambdas; CloudWatch alarms CloudFormation template. Owner must deploy CFn stack. |
| 19 | Code quality | 3 | 7 | +4 | Dead code removed (−431 lines); all hardcoded names replaced; `flutter analyze` 0 errors / 26 info; `applicationId` corrected to `com.torino.todd`. |
| 20 | Admin tooling | 2 | 3 | +1 | Confirmed admin panel is a separate repo; architecture doc notes it. No code change possible here; owner must wire separate admin repo to /prod API. |

**Total re-score: 72 / 100**

---

## Summary

| Category | Gates | Criticals | Dimensions |
|----------|-------|-----------|------------|
| Fully resolved (code) | 4 / 6 | 10 / 10 | — |
| Requires owner action | 2 / 6 | 0 / 10 | 5 dimensions still have owner-blocked gaps |

---

## Beta Eligible status

Beta Eligible requires: all 6 gates PASS (code + owner actions complete), all 10 Criticals closed, core flows smoke-tested on device.

**Code-side: 4/6 gates fully resolved · 2/6 require owner action**
**Criticals: 10/10 closed**
**Device smoke test: NOT YET (P11-3 owner action)**

---

## Owner checklist for Beta Eligible

- [ ] **GATE-01** — Revoke old Gemini key at aistudio.google.com (key is in git history and must be rotated). Generate new key. Set `GEMINI_API_KEY` in ai-chat Lambda env var. Pass `--dart-define=GEMINI_API_KEY=<newkey>` at build time.
- [ ] **GATE-05** — AWS console → S3 → `torino-app-storage` → Block Public Access → enable all 4 toggles. Set `S3_BUCKET` env var on `upload-url` Lambda.
- [ ] **P5-1** — Set `STRIPE_SECRET_KEY` env var on payments Lambda. Wire `POST /payments/create-intent` in API Gateway `/prod` stage.
- [ ] **P9-1** — Download `google-services.json` from Firebase console → `android/app/`. Add to `.gitignore`. Gradle build is blocked until this file is present.
- [ ] **P5-2** — Create Stripe Products/Prices (Monthly $9.99, Quarterly $49.99, Annual $99.99) and confirm in Stripe dashboard. Configure Stripe Subscriptions if recurring billing is needed (current flow issues one-time PaymentIntents only).
- [ ] **P7-3/P7-4** — Add `experience`, `language`, and `hourlyRate` fields to the Mentor Lambda response and `MentorModel`/`UserProfileModel` so mentor profiles show real data.
- [ ] **P2-5** — Enable Cognito advanced security + OTP lockout; enable refresh-token rotation in Cognito console.
- [ ] **P10-2** — Deploy CloudWatch alarms: `aws cloudformation deploy --template-file aws-backend/cloudwatch-alarms.json --stack-name torino-alarms`.
- [ ] **P10-1** — Confirm app was never published to Play Store under `torino.torino` before the `applicationId` change to `com.torino.todd` takes effect.
- [ ] **P11-3** — Full device run-through: auth flow, student enroll + watch lesson, teacher create course, mentor set availability + book session, Stripe payment (test mode), Agora 2-device call, notifications delivery.
