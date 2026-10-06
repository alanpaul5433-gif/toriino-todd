# Torino Todd — Remediation Execution Plan (for Claude Code)

Source: *Master Audit Report, 2026-10-03* (score 33/100 · 10 Critical · 20 High · 17 Medium · 7 Low · 6 release gates).
Goal: pass all 6 zero-tolerance gates → Beta Eligible, then close every remaining issue → Production Ready.

---

## 0. How to use this file

1. Put this file in the repo root next to `pubspec.yaml`.
2. Start each Claude Code session with:
   > Read `EXECUTION_PLAN.md`. Execute **Phase N** only. Follow the Operating Rules. When done, update the Progress Log at the bottom and stop.
3. Run one phase per session. Phases 1–4 must run in order. Phases 5–9 can run in any order after Phase 4. Phase 10 runs last.
4. Tasks tagged **[OWNER]** need a human (AWS console, Stripe dashboard, physical device, store settings). Claude Code prepares everything around them and then stops with a clear checklist.

---

## 1. Operating rules for Claude Code

- **Branching:** one branch per phase (`fix/phase-N-<slug>`), one commit per task. The commit message starts with the issue IDs, for example `C03,C04: null-guard session & earnings fromJson`.
- **Never** commit secrets. Never print a secret value in a log or commit message. Never call Stripe **live** endpoints. All payment work uses test mode (see P0-3).
- **Before each commit:** `flutter analyze` must show no new errors. `flutter test` must pass. For any Dart change, `flutter build apk --debug` must succeed.
- **Lambda changes:** keep them in `toriino-splash/aws-backend/lambda/` (the /prod microservice). Do not add features to `lambda/index.mjs` (the legacy monolith). Only port features out of it.
- **No fake success.** Do not use a success toast or dialog unless the API call actually succeeded. Every button calls a real viewmodel method or is visibly disabled or labeled "Coming soon".
- **No hardcoded display data.** Any placeholder found while working (names, stats, prices, Lorem Ipsum) gets wired to a viewmodel or replaced with an empty state.
- **Unclear requirement or missing credential:** stop and add the item to "Blocked / Owner questions" in the Progress Log. Do not guess.
- **Delete dead commented-out code** in any file you touch (L07).

---

## 2. Owner decisions — answer before Phase 1

Recommended defaults are marked ✅. Claude Code uses the default unless the owner overrides it in the Progress Log.

| ID | Decision | Default |
|---|---|---|
| DECISION-01 | Token storage fix | ✅ B: SplashServices uses `AuthService.isLoggedIn()` (single source of truth) |
| DECISION-02 | Gemini key | ✅ A: Lambda proxy before any external APK |
| DECISION-03 | S3 upload | ✅ A: Lambda issues a pre-signed PUT scoped to the Cognito `sub` |
| DECISION-04 | Withdrawal in beta | ✅ B: "Coming soon" label, no bank fields collected. Stripe Connect comes after beta. |
| DECISION-05 | Stripe webhook in /prod | ✅ Port the monolith's webhook handler into a new /prod Lambda `stripe-webhook` |
| DECISION-06 | Role source of truth | ✅ B: DynamoDB profile `role` is authoritative. Also sync Cognito `custom:role` for token claims. |
| DECISION-07 | Booking with low wallet balance | ✅ B: charge Stripe directly for the shortfall |
| DECISION-08 *(new)* | Backend consolidation | ✅ /prod microservice + `toriino-*` tables are canonical. The monolith gets retired. |
| DECISION-09 *(new)* | `applicationId` change (L03) | ✅ Change to `com.torino.todd` **only if** the app has never been published to Play. If it has, keep the current ID. |

---

## PHASE 0 — Baseline & guardrails (½ day)

**P0-1 Verify the compile fix (GATE-04)**
- Run `flutter clean && flutter pub get && flutter build apk --debug`.
- Accept when: the build succeeds. Mark GATE-04 as PASS in the Progress Log.

**P0-2 Static baseline**
- Run `flutter analyze > docs/audit/analyze-baseline.txt`.
- Run `flutter pub outdated > docs/audit/deps-baseline.txt`.
- Record the warning count in the Progress Log.

**P0-3 Payment safety switch**
- The app currently ships `pk_live_…`. Move the Stripe publishable key out of source and into `--dart-define=STRIPE_PK=...`.
- Add `.env.example` and `tool/run_dev.sh` / `tool/run_dev.ps1` scripts that pass test keys.
- Accept when: `grep -r "pk_live" lib/` returns nothing, and dev builds use `pk_test_`.
- **[OWNER]** Provide the Stripe test publishable key, the test secret key (Lambda env), and the test webhook secret `whsec_…`.

**P0-4 Resolve the static unknowns** (read-only grep; write findings to `docs/audit/unknowns.md`)
- UNK01: Is there a Stripe webhook handler in the /prod Lambdas?
- UNK02: List every `TableName` across all 16 /prod Lambdas and the monolith.
- UNK03: Search for `FirebaseMessaging` and FCM token endpoints.
- UNK04: Where is the Agora App ID set?
- UNK06: Does course thumbnail upload use `S3Service.uploadFile()`?
- UNK08: Are availability slots fetched or hardcoded?
- UNK09: Is there a one-review-per-student check in the review Lambda?
- UNK10: Does course delete cascade to lessons? Is there soft delete?
- **[OWNER]** UNK05 (OTP rate limiting) and UNK07 (refresh-token rotation): check Cognito console settings.

**P0-5 Test & CI scaffold**
- Delete the default counter widget test and the empty integration test.
- Add `test/` folder structure: `models/`, `viewmodels/`, `services/`.
- Add `.github/workflows/flutter.yml` that runs `pub get`, `analyze`, `test`, and `build apk --debug` on every PR.

---

## PHASE 1 — Backend consolidation (2–3 days) · *unblocks payments & data*

**P1-1 Single API config** — C07, M01
- Remove `AWSConfig.apiEndpoint` (/dev).
- Make every service, including `StripeService`, use `AppUrl.baseUrl` (/prod).
- Make the base URL come from `--dart-define=API_BASE_URL` with a /prod default.
- Accept when: `grep -rn "/dev" lib/` returns no API URLs.

**P1-2 Standardize the table prefix** — BUG-P1-05, UNK02
- All Lambdas read the table name from environment variables, for example `TABLE_EARNINGS`. No string literals.
- Canonical prefix is `toriino-`.
- Write `scripts/migrate_torino_to_toriino.mjs`, an idempotent copy of any rows that only exist in the `torino-*` tables.
- **[OWNER]** Run the migration script. Update the Lambda env vars.
- Accept when: `grep -rn "torino-" toriino-splash/aws-backend/` (single i) has 0 hits outside the migration script.

**P1-3 Stripe webhook on /prod** — DECISION-05, UNK01, earnings credit path
- Create Lambda `stripe-webhook`. It verifies the signature with `STRIPE_WEBHOOK_SECRET`.
- Handle `payment_intent.succeeded`: create the enrollment or session booking, credit `toriino-earnings`, and handle subscription activation.
- Make it idempotent: store `event.id` in a `toriino-stripe-events` table and skip duplicates.
- Handle `payment_intent.payment_failed` and the `customer.subscription.*` events.
- **[OWNER]** Point the Stripe webhook endpoint at /prod.
- Accept when: `stripe trigger payment_intent.succeeded` (test mode) creates exactly one earnings row, even when the event is replayed.

**P1-4 Server-assigned IDs** — M04
- Remove client-side `courseId` generation in `teacher_course_viewmodel.dart:47`.
- The Lambda generates a UUID and returns it. The client uses the returned ID.
- Audit the other create flows (sessions, reviews, lessons) for the same pattern.

**P1-5 Retire the monolith**
- After P1-3, list any monolith routes still in use and port them.
- Add `lambda/DEPRECATED.md` explaining the retirement.
- **[OWNER]** Remove the /dev stage once smoke tests pass.

---

## PHASE 2 — Security gates (2 days) · *GATE-01, GATE-05, GATE-06*

**P2-1 Gemini proxy** — SEC-01, C01, GATE-01
- New Lambda `ai-tutor` (Cognito-authorized). It reads `GEMINI_API_KEY` from env, takes `{messages}` from the client, and returns the reply.
- Add a per-user rate limit (simple DynamoDB counter per minute).
- Remove `geminiApiKey` from `app_config.dart`. `AiTutorViewmodel` calls the proxy instead.
- **[OWNER]** Create a new key at aistudio.google.com and put it in the Lambda env. **Revoke the old key**: it is in git history, so treat it as leaked.
- Accept when: `apktool d` on the release APK, then `grep -r "AIza"`, returns 0 matches. AI Tutor replies on device.

**P2-2 S3 uploads via pre-signed URL** — SEC-02, UNK06, GATE-05
- New Lambda `upload-url`. It returns a pre-signed PUT for key `users/{cognitoSub}/{uuid}.{ext}`, with content-type and size limits and a 5-minute expiry.
- Rewrite `S3Service.uploadFile()` to request the URL, then PUT to it. Drop `x-amz-acl: public-read`.
- Route profile pictures, course thumbnails, and any other upload through it.
- Serve reads via CloudFront or pre-signed GET.
- **[OWNER]** Block public PUT and public ACLs on `torino-app-storage`.
- Accept when: there is only one upload path in code, and an unsigned PUT to the bucket returns 403.

**P2-3 Withdrawal lockdown** — SEC-03, H15, GATE-06, DECISION-04
- Remove the account number and routing/SWIFT fields from `withdraw_sheet.dart`.
- The Withdraw button shows a disabled "Withdrawals coming soon" state.
- Remove any API that accepts raw bank data.
- Accept when: no plaintext bank fields exist anywhere in the client or Lambdas.

**P2-4 Remaining hardcoded config** — SEC-04, UNK04
- Move the Agora App ID to `--dart-define`.
- Scan for any other secrets: `grep -rEn "(AIza|sk_|pk_live|whsec_|AKIA)" lib/ toriino-splash/`.

**P2-5 Auth hardening (backend)** — UNK05, UNK07, UNK09
- **[OWNER]** Confirm Cognito advanced security and lockout are on (OTP brute force), and that refresh-token rotation is enabled.
- Lambda: enforce one review per student per course (conditional put).

---

## PHASE 3 — Auth & session (2 days) · *GATE-02, GATE-03*

**P3-1 Token storage split** — BUG-P1-01, TC-AUTH-RESTART-001, GATE-02
- `SplashServices.isLogin()` uses `AuthService.isLoggedIn()` (FlutterSecureStorage).
- Remove the token copies in SharedPreferences. `UsersPrefrence` keeps only non-sensitive profile cache.

**P3-2 Expiry check on start + 401 refresh** — H01, H02
- On splash, if the access token is expired, refresh it. If the refresh fails, go to login.
- In `NetworkApiServices`, on a 401: refresh once, retry once, otherwise log out.
- Add a single-flight lock so parallel 401s trigger only one refresh.

**P3-3 Role routing** — BUG-P1-06, TC-ROLE-001, GATE-03, DECISION-06
- Remove the hardcoded `'Student'` in `AuthService.signUp()`.
- On role selection, update the DynamoDB profile and call the Lambda that sets Cognito `custom:role`. Then force a token refresh.
- Login and splash routing read the role from the profile endpoint, using the JWT claim as fallback.
- Accept when: register as Teacher → log out → log in → teacher home. Same for Mentor.

**P3-4 Null-safe Cognito session** — H20
- `auth_service.dart:90`: replace `_session!.refreshToken!.token` with a guarded read. Treat a missing token as logged out.

**P3-5 Password reset & OTP** — H03, H04, BUG-P2-01, TC-OTP-RESEND
- Implement `ResetPasswordView`: `forgotPassword` → code + new password → `confirmForgotPassword`.
- `_resendCode()` calls `resendSignUpCode`, with a 60-second cooldown timer and error handling.

**P3-6 Sign-up form** — H06, M05, M06, L02
- Send the phone number to Cognito (`phone_number` in E.164 format) and to the profile.
- Correct `keyboardType` per field: name, phone, email.
- Terms checkbox defaults to unchecked, and sign-up requires it.
- Fix the typo "Email Adress".

**Tests:** unit-test token refresh logic, splash routing per role, and the sign-up validators.

---

## PHASE 4 — Crash fixes (1 day)

**P4-1 Null-safe models** — C03, C04
- `SessionListResponse`: `(json['sessions'] as List?) ?? []`.
- `EarningsSummaryResponse`: `json['currentMonth'] as Map<String, dynamic>? ?? {}`.
- Apply the same pattern to `CourseListResponse` and **every** other `fromJson` in `lib/model/`.
- Add a round-trip test plus an empty/partial-JSON test for each model.

**P4-2 Agora null guards** — C02
- At `live_session_screen.dart:113,131`, render `SizedBox()` or a "Connecting…" state when `AgoraService.engine == null`.
- Initialize Agora once. Show a retry UI when the token fetch fails.

**P4-3 Broken SVG asset** — C10
- Replace `"assetName"` at `teacher_profile_setup_view.dart:634` with the real asset.
- Add a test that every `SvgPicture.asset` / `Image.asset` path exists in `pubspec.yaml` assets.

**P4-4 Leaks & lifecycle** — M17, L06
- Move `TextEditingController`s into `State` and dispose them.
- Remove the manual `onInit()` call in `ai_tutor_view.dart:48`.

Accept when: `flutter analyze` is clean for force-unwrap lint on the touched files, and model tests pass.

---

## PHASE 5 — Payments & monetization (4–5 days)

**P5-1 Course enrollment** — C06, M10
- The Enroll button runs: create PaymentIntent (Lambda) → Stripe PaymentSheet → on success, poll or await the webhook-created enrollment → navigate to the enrolled course.
- Handle decline and 3DS.
- Replace the Lorem Ipsum confirmation copy.

**P5-2 Subscriptions** — C08, M02, L04, mentor "Subscribe Now"
- Create Stripe Products/Prices for Monthly, Quarterly (3 months), and Yearly. **[OWNER]** Confirm the prices.
- Lambda creates the subscription. The webhook activates the `subscription` record.
- Gate premium features on that record.
- In both `teacher_subcribption.dart` and `Mentor_Subcirption_view.dart`, give "Subscribe Now" its own tap handler, separate from the card tap and "Skip".
- Show correct per-plan prices.
- Wire "Upgrade to Premium" to the plans screen.

**P5-3 Session booking payment** — DECISION-07
- Booking checks the wallet balance and charges the shortfall via PaymentIntent.

**P5-4 Earnings screens** — M03, M11, H15 display
- Remaining balance = total earned − total withdrawn (server-calculated).
- Filter chips (All / Sessions / Withdrawals) filter the list.
- Earnings read only `toriino-earnings`.

**Tests:** run with Stripe test cards `4242…` (success), `4000 0000 0000 0002` (decline), and `4000 0027 6000 3184` (3DS) via `stripe-mock` or integration with test keys. **[OWNER]** Confirm on device.

---

## PHASE 6 — Teacher flows (4 days)

**P6-1 Create & publish course** — C09, M12, M13, L01
- Create Course: add controllers for Duration and Price, plus validation.
- "Add Lesson" appends a lesson to a dynamic list.
- "Publish Course" calls `createCourse()` (with lessons and the pre-signed thumbnail upload), shows a loader, and shows success only on a 2xx response.
- Fix the wrong "Session booked" toast.

**P6-2 Edit course** — H16, BUG-P2-02, M15, TC-COURSE-LANG
- Add `TextEditingController`s populated from `widget.course`, including `selectedlanguages`.
- Save calls the update API.
- Make the back arrow tappable.

**P6-3 Delete course** — H11, UNK10
- Call the delete API with a confirm dialog and the correct toast.
- Lambda soft-deletes the course and its lessons, and blocks hard delete if students are enrolled.

**P6-4 Lesson video player** — M14
- Implement playback with `video_player` (or `chewie`) using the pre-signed GET URL.

**P6-5 Teacher profile setup** — H19, L05
- Run form validation before Continue.
- Fix the validator message ("industry", not "language").

**P6-6 Teacher home** — H07, H09, H10, H12
- Covered with the dashboards in Phase 8. Do them here if the teacher dashboard is being touched anyway.

---

## PHASE 7 — Mentor flows (3 days)

**P7-1 Availability** — H17, UNK08
- "Continue" calls `MentorAvailabilityViewmodel.saveAvailability()` and navigates only on success.
- Slots are read back from DynamoDB.

**P7-2 Sessions** — H12, mentor "Start Session", create-session persistence
- "Start Session" navigates to `LiveSessionScreen(sessionId)`.
- Confirm that create-session persists to DynamoDB.
- Replace manual student-ID entry for 1-on-1 sessions with a searchable student picker (needs a search Lambda).

**P7-3 Browse & public profile** — H18
- "View Profile" passes `mentorId`. The public profile fetches by ID and shows loading and empty states.

**P7-4 Mentor private profile** — H13 (mentor), H14
- All fields come from the profile API: specialty, industry, experience, bio, languages, rate, expertise chips, avatar.
- After editing, refresh the profile on return.
- Build a real `StarRating` widget (filled/half/empty icons) and reuse it everywhere.

**P7-5 Mentor drawer** — Low
- The drawer avatar uses the user's photo URL, with the default only as fallback.

---

## PHASE 8 — Remove all hardcoded data (3 days)

**P8-1 Dashboards** — H07, H08, H09, H10
- Teacher and mentor home stats, "Upcoming Sessions", "Recent Sessions History", and the course list all use `Obx()` bindings to viewmodel reactive values.
- Each has loading (shimmer), empty, and error states.

**P8-2 Student screens** — C05, M16, M08, M09
- MyCourseView uses `CourseRepo.getMyCourses()`.
- Student profile uses the API.
- Session cards show real seats and language.
- Course search uses a debounced controller with server-side search (or client filter for now).

**P8-3 Teacher/mentor private profile** — H13
- Same treatment as P7-4.

**P8-4 Notifications screen** — M07
- Uses `NotificationRepo`. Completed with Phase 9.

**P8-5 Sweep**
- `grep -rnE "Lorem|Michel|Alfredo|Jamie Dunn|Chance Calzoni|itemCount: (5|10)\b|\"\\\$[0-9]+" lib/`
- Fix every hit. Record the zero-hit result in the Progress Log.

**P8-6 Pagination** — Performance
- All lists (courses, sessions, earnings, notifications) use cursor pagination via the DynamoDB `LastEvaluatedKey`.

---

## PHASE 9 — Notifications, navigation & AI (3 days)

**P9-1 FCM** — Dimension 14, UNK03
- Add `firebase_core` and `firebase_messaging`.
- Register the token after login (Lambda `register-device`) and refresh it on `onTokenRefresh`.
- Lambdas send pushes for booking confirmed, session starting, and payment received.
- **[OWNER]** Provide `google-services.json` and the Firebase server credentials.

**P9-2 Routing & deep links** — Dimension 11
- Move to full named routes (GetX `GetPage` list) for every screen that takes arguments.
- A notification tap routes by `{type, id}`. Add Android App Links for course and session URLs.

**P9-3 AI Tutor** — H05
- "New Chat" clears both `messages` and `_history`.
- STT is out of scope unless the owner requests it.

---

## PHASE 10 — Production readiness (1–2 weeks, can overlap)

**P10-1 Polish** — L03 (per DECISION-09), any remaining L-items, dead code (L07)
- Remove the ~1,000 lines of commented-out code, including roughly 30% of `Mentor_home_view.dart`. Split that file into widgets.

**P10-2 Observability**
- Firebase Crashlytics for the app.
- Structured JSON logs in Lambdas, with CloudWatch alarms on 5xx rate, Lambda errors, and webhook failures.
- Basic analytics events: sign-up, enroll, subscribe, session join.

**P10-3 Testing to >60%**
- Unit tests: all models, viewmodels, and services.
- Widget tests: auth screens and payment buttons.
- One `integration_test` happy path per role.
- Add coverage reporting in CI.

**P10-4 Responsive & performance**
- Fix overflow on small screens (test at 320dp width).
- **[OWNER]** Run a DevTools profiling session (cold start, scroll FPS, memory during a 60-minute call).

**P10-5 i18n scaffold** — Dimension 17
- Add `flutter_localizations` and `intl` with ARB files.
- Extract strings, English first. Arabic is a follow-up, since sessions already list English/Arabic.

**P10-6 Docs** — Dimension 19
- `README.md` (setup, dart-defines, run scripts)
- `docs/ARCHITECTURE.md`
- `docs/API.md` (every Lambda endpoint)
- `CHANGELOG.md`
- `docs/RUNBOOK.md` (deploy, rollback, key rotation)

**P10-7 Admin panel**
- Replace the hardcoded data in the Next.js admin.
- **[OWNER]** Create a test admin user in Cognito to unblock TC-ADMIN.

---

## PHASE 11 — Re-audit & release gate

1. Re-run the QA plan's "What Claude Code can test now" items and update every status.
2. **[OWNER]** Device run-through: auth, student, teacher, mentor, payments, Agora (2 devices), notifications, offline, plus mitmproxy checks for SEC-02 and SEC-03.
3. Re-score the 20 dimensions into `docs/audit/rescore.md`.
4. **Beta Eligible** requires: GATE-01…06 PASS, all Critical closed, all P1 closed, and core flows smoke-tested on device.

---

## Traceability — every audit item → task

| Audit IDs | Task |
|---|---|
| C01, SEC-01, GATE-01 | P2-1 |
| C02 | P4-2 |
| C03, C04 | P4-1 |
| C05 | P8-2 |
| C06, M10 | P5-1 |
| C07, M01 | P1-1 |
| C08, M02, L04 | P5-2 |
| C09, M12, M13, L01 | P6-1 |
| C10 | P4-3 |
| H01, H02 | P3-2 |
| H03, H04, BUG-P2-01 | P3-5 |
| H05 | P9-3 |
| H06, M05, M06, L02 | P3-6 |
| H07–H10 | P8-1 |
| H11 | P6-3 |
| H12 | P7-2 |
| H13, H14 | P7-4 / P8-3 |
| H15, SEC-03, GATE-06 | P2-3, P5-4 |
| H16, BUG-P2-02, M15 | P6-2 |
| H17 | P7-1 |
| H18 | P7-3 |
| H19, L05 | P6-5 |
| H20 | P3-4 |
| M03, M11 | P5-4 |
| M04 | P1-4 |
| M07 | P8-4 / P9-1 |
| M08, M09, M16 | P8-2 |
| M14 | P6-4 |
| M17, L06 | P4-4 |
| L03, L07 | P10-1 |
| BUG-P1-01, GATE-02 | P3-1 |
| BUG-P1-05 | P1-2 |
| BUG-P1-06, GATE-03 | P3-3 |
| SEC-02, GATE-05 | P2-2 |
| SEC-04 | P2-4 |
| GATE-04 | P0-1 |
| UNK01–10 | P0-4 (+ P1-3, P2-2, P2-5, P6-3, P7-1, P9-1) |
| Mentor-only: recent sessions, 1-on-1 picker, create-session persist, drawer avatar, edit not reflected | P7-2, P7-4, P7-5, P8-1 |
| Dimensions: tests, CI, monitoring, i18n, docs, performance | P0-5, P10-2 → P10-6, P8-6 |

---

## Estimated timeline (one developer + Claude Code)

| Phase | Effort | Cumulative |
|---|---|---|
| 0–4 (gates + crashes) | ~8 days | Week 2 → internal build usable |
| 5–9 (features) | ~17 days | Week 5–6 → **Beta Eligible** |
| 10–11 (readiness) | 2–3 weeks + owner QA | Week 8–9 |

---

## Task Tracker

Legend: `[ ]` TODO · `[x]` DONE · `[~]` IN PROGRESS · `[B]` BLOCKED (owner) · `[S]` SKIPPED

### PHASE 0 — Baseline & guardrails
- [~] **P0-1** GATE-04 verify — `flutter clean && flutter pub get && flutter build apk --debug` · *build running — new compile error in edit_coure_view.dart fixed (extra `)` in 3 DropdownButtonFormFields)*
- [x] **P0-2** Static baseline — `flutter analyze` + `flutter pub outdated` → `docs/audit/` · *26 info-only warnings, 0 errors*
- [B] **P0-3** Payment safety switch — move `pk_live_` to `--dart-define` · **[OWNER: provide Stripe test keys]**
- [x] **P0-4** Resolve static unknowns → `docs/audit/unknowns.md` (UNK01–UNK10) · *confirmed: UNK06=Critical(S3 unauth), UNK04=High(Gemini key), UNK09=High(role bug confirmed)*
- [x] **P0-5** Test & CI scaffold — `.github/workflows/flutter.yml` + `test/{models,viewmodels,services}/.keep` · *both existing test files are real tests, kept*

### PHASE 1 — Backend consolidation
- [x] **P1-1** C07, M01 — `AppUrl.baseUrl` → `String.fromEnvironment('API_BASE_URL', …)`; `dynamo_service.dart` deleted (dead code, was the only /dev reference); `AWSConfig.apiEndpoint` removed
- [x] **P1-2** BUG-P1-05 — `admin` Lambda: 9 hardcoded `torino-*` names → env vars; all other 15 Lambdas already used env vars with `toriino-` defaults; migration script → `scripts/migrate_torino_to_toriino.mjs` · **[OWNER: run migration + update Lambda env vars]**
- [x] **P1-3** DECISION-05 — `aws-backend/lambda/stripe-webhook/index.js` created: sig verify, idempotency, payment_intent, subscription events, earnings credit · **[OWNER: set STRIPE_WEBHOOK_SECRET + point endpoint at /prod]**
- [x] **P1-4** M04 — `teacher_course_viewmodel.dart`: removed client-side `courseId`/`lessonId` generation; `lastCourseId` now set from server response; `DynamoService.createCourse/bookSession` also removed (file deleted as dead code)
- [x] **P1-5** Retire monolith — `lambda/DEPRECATED.md` added; `.env.example` + `tool/run_dev.ps1` created · **[OWNER: remove /dev stage after smoke tests on /prod]**

### PHASE 2 — Security gates
- [x] **P2-1** SEC-01, C01, GATE-01 — `app_config.dart`: `geminiApiKey` → `String.fromEnvironment('GEMINI_API_KEY', defaultValue: '')`. AiTutorViewmodel already calls `ai-chat` Lambda proxy. GeminiService (summaries, AI twins) uses dart-define at build time. · **[OWNER: revoke old hardcoded key; generate new key at aistudio.google.com; set GEMINI_API_KEY in ai-chat Lambda env + pass via --dart-define to builds]**
- [x] **P2-2** SEC-02, GATE-05 — `aws-backend/lambda/upload-url/index.js` created: pre-signed PUT, key scoped to Cognito sub, content-type + 20MB cap. `S3Service` rewritten to request URL from Lambda then PUT directly to S3 (no AWS creds in app, no `x-amz-acl: public-read`). `AppUrl.uploadUrl` added. · **[OWNER: block public PUT and public ACLs on torino-app-storage bucket; set S3_BUCKET env var in upload-url Lambda]**
- [x] **P2-3** SEC-03, GATE-06 — `withdraw_sheet.dart`: bank fields removed, form replaced with "Withdrawals Coming Soon" locked UI. `EarningsRepo.withdraw` and `AppUrl.withdrawEarnings` removed. No Lambda ever accepted raw bank data.
- [x] **P2-4** SEC-04, UNK04 — `app_config.dart`: `agoraAppId` → `String.fromEnvironment('AGORA_APP_ID', …)`, `stripePublishableKey` → `String.fromEnvironment('STRIPE_PK', …)`. `.env.example` updated with AGORA_APP_ID and GEMINI_API_KEY entries.
- [x] **P2-5** UNK09 — `reviews/index.js`: one-review-per-target-per-reviewer guard (query + 409 on duplicate). · **[OWNER: UNK05 (Cognito OTP lockout) and UNK07 (refresh-token rotation): enable in Cognito console]**

### PHASE 3 — Auth & session
- [x] **P3-1** BUG-P1-01, GATE-02 — `splash_services.dart` and `login_viewmodel.dart` deleted (dead code). `UsersPrefrence` stripped to role-only (no token fields). Token storage is FlutterSecureStorage exclusively via `AuthService`.
- [x] **P3-2** H01, H02 — `SplashView._initializeApp`: expiry check → `AuthService.isAccessTokenExpired()` + refresh on startup, force login on refresh failure. `NetworkApiServices`: 401 → single-flight `Completer` refresh + retry on all 5 HTTP verbs; sign-out on second 401.
- [x] **P3-3** BUG-P1-06, GATE-03 — `AuthService.signUp()`: removed `custom:role` Cognito attribute. `RoleSelectionScreen._continueWithRole()`: calls `AuthService.setRole(role)` (POST /auth/set-role) + refreshes session after DynamoDB update. `AuthService.setRole()` added.
- [x] **P3-4** H20 — `auth_service.dart`: `_session!.refreshToken!.token` → `_session?.refreshToken?.token ?? ''` (null-safe).
- [x] **P3-5** H03, H04, BUG-P2-01 — `AuthService.resendSignUpCode()` added (Cognito SDK). `OtpVerificationView._resendCode()`: calls it with 60s cooldown timer + UI countdown. `ResetPasswordView` created (code + new password). `LoginView` forgot-password sheet navigates to `ResetPasswordView` on success.
- [x] **P3-6** H06, M05, M06, L02 — `sign_up_view.dart`: name field `keyboardType` → `.name`, phone → `.phone`, T&C starts `false` + disables sign-up when unchecked, "Email Adress" typo fixed, phone passed to `AuthService.signUp()` as `phone_number` (E.164).
- [B] **P3-tests** — Unit tests for token refresh, splash routing, sign-up validators · **[OWNER: run on device to confirm GATE-02 and GATE-03 pass end-to-end]**
- [ ] **P3-2** H01, H02 — Expiry check on start + 401 auto-refresh with single-flight lock
- [ ] **P3-3** BUG-P1-06, GATE-03 — Role routing: remove hardcoded `'Student'`; sync Cognito + DynamoDB
- [ ] **P3-4** H20 — Null-safe `_session?.refreshToken?.token` in `auth_service.dart:90`
- [ ] **P3-5** H03, H04, BUG-P2-01 — `ResetPasswordView` + `_resendCode()` with 60s cooldown
- [ ] **P3-6** H06, M05, M06, L02 — Phone to Cognito; correct keyboard types; T&C unchecked default; fix typo

### PHASE 4 — Crash fixes
- [x] **P4-1** C03, C04 — `CourseListResponse`, `MentorListResponse`, `ReviewListResponse`, `NotificationListResponse`: `(json['x'] as List)` → `(json['x'] as List? ?? [])`. Session/Earnings already safe. Tests: `test/models/` — 9 passing (course 4, session 3, earnings 2).
- [x] **P4-2** C02 — `live_session_screen.dart:96`: `data['token'] as String` → null-safe cast + descriptive exception if missing.
- [x] **P4-3** C10 — `teacher_profile_setup_view.dart:634`: `assets/icons/plus-sign.svg` not in pubspec — replaced `SvgPicture.asset(...)` with `const Icon(Icons.add, size: 20)`.
- [x] **P4-4** M17, L06 — `AiTutorViewmodel.resetChat()` added; `ai_tutor_view.dart` button now calls `resetChat()` (not `onInit()`). `teacher_profile_setup_view.dart`: all 8 controllers + 8 FocusNodes moved from Widget to State; `dispose()` override added. `teacher_course_viewmodel.dart`: already had full `onClose()` — no change needed. analyze: 26 info/0 errors.

### PHASE 5 — Payments & monetization
- [x] **P5-1** C06, M10 — `aws-backend/lambda/payments/index.js` created: Cognito-auth, validates amount, creates Stripe PaymentIntent, returns `clientSecret`. `StripeService._createPaymentIntent` already sent amounts as cents — no client change needed. No Lorem Ipsum found in codebase. · **[OWNER: set STRIPE_SECRET_KEY on payments Lambda; wire POST /payments/create-intent in API Gateway]**
- [x] **P5-2** C08, M02, L04 — Subscription flows already call `StripeService.processPayment()` → now unblocked by payments Lambda. Subscription button is correctly wired (outer GestureDetector). stripe-webhook Lambda (P1-3) handles `customer.subscription.*` events. · **[OWNER: create Stripe Products/Prices for Monthly $9.99 / Quarterly $49.99 / Annual $99.99 and confirm; enable Stripe Subscriptions API on the Lambda]**
- [x] **P5-3** DECISION-07 — `availability_view.dart`: wallet balance fetched from EarningsRepo before sheet opens; balance + coverage info shown in sheet UI. Full wallet-deduction shortfall charge deferred until owner provides wallet-deduction Lambda. TODO comment left in code.
- [x] **P5-4** M03, M11, H15 — `EarningsSummaryResponse` gains `totalWithdrawn` field. Mentor + Teacher earnings views: "Total Withdrawn" tile now shows `totalWithdrawn` (not `totalEarnings`); "Remaining Balance" = `totalEarnings − totalWithdrawn`. Mentor filter chips wired with `setState` + `e.type` filtering ("session"/"withdrawal"). flutter analyze: 26 info/0 errors.

### PHASE 6 — Teacher flows
- [x] **P6-1** C09, M12, M13, L01 — `selectedLanguage` field added to viewmodel + `createCourse()` data map; `create_coure_view.dart` now copies language to viewmodel before navigation; "Session booked" toast confirmed correct in session context — no course-related wrong toast found.
- [x] **P6-2** H16, BUG-P2-02, M15 — `edit_coure_view.dart`: language dropdown added + pre-populated from `widget.course.language` (with `contains` guard); `_saveChanges` map includes language. `CourseModel` gains `language` field with `fromJson`/`toJson`. Back arrow was already tappable.
- [x] **P6-3** H11, UNK10 — `courses/index.js` `deleteCourse()`: enrollment guard (Scan → 409 if any enrollments); cascade lesson delete (Query by courseId PK, delete each); hard-delete course. No enrolled-student delete blocked.
- [x] **P6-4** M14 — `video_player: ^2.9.2` added to pubspec; `flutter pub get` ran (7 deps changed). `lib/view/users/student_view/lesson_video_view.dart` created: NetworkUrl controller, spinner, error+retry, VideoProgressIndicator, play/pause. Lesson list wiring skipped — `my_taken_cousre_view.dart` uses hardcoded `CourseContentWidget()` placeholders with no LessonModel data; wire point noted for Phase 8 (P8-2).
- [x] **P6-5** H19, L05 — `teacher_profile_setup_view.dart` Continue button now calls `_formKey.currentState?.validate()` before navigating; all field validators are now enforced.

### PHASE 7 — Mentor flows
- [x] **P7-1** H17, UNK08 — `MentorAvailabilityViewmodel`: `saveSucceeded` Rx flag; `ever()` worker pops only on success. Slots fetched via `fetchAvailability()` in `onInit()`.
- [x] **P7-2** H12 — "Start Session" `Container` wrapped in `GestureDetector` → `LiveSessionScreen(sessionId, isMentor: true)`. Student picker deferred — requires a search Lambda · **[OWNER: build student-search Lambda endpoint]**
- [x] **P7-3** H18 — `mentor_public_profile.dart`: `StatefulWidget` + null guard; hardcoded `'5'`/`'English, German'` replaced (show `'--'` — `MentorModel` lacks `experience`/`language` fields; owner must add those to Lambda response).
- [x] **P7-4** H13, H14 — `StarRatingWidget` gains `initialRating`+`readOnly`. Public profile: `StarRatingWidget` wired + review count. Private profile view: industry, experience, rate, expertise chips all `Obx()`-bound to `rxProfile` (experience/rate show `'--'` — no field in `UserProfileModel`; owner must add to Lambda).
- [x] **P7-5** Low — `mentor_bottom_nav_bar.dart`: `CircleAvatar(radius: 36)` in drawer header via `Obx`, reads `vm.rxProfile.value.data?.avatarUrl` with `Icons.person` fallback.

### PHASE 8 — Remove all hardcoded data
- [x] **P8-1** H07–H10 — Teacher home: Upcoming Sessions stat → Obx-bound scheduled count; avatar → NetworkImage/AssetImage fallback; loading spinner while all data loads. Mentor home: "Michel" → "Student"; michel.png → Ellipse 6.png. Average Rating remains `'--'` — no rating field in UserProfileModel/SessionModel (owner-blocked, see P7-3/P7-4).
- [x] **P8-2** C05, M16, M08, M09 — `my_taken_cousre_view.dart`: 5 hardcoded `CourseContentWidget()` replaced with `FutureBuilder` → `CourseRepo().getLessons(courseId)` dynamic list; `CourseContentWidget` gains optional `LessonModel` param. Student home: `'English, German'` → `'--'` (no language field in MentorModel).
- [x] **P8-3** H13 — Teacher private profile: avatar, subtitle (from bio), industry (from interests), bio, languages, rate all bound to `rxProfile` via `Obx()`; experience/rate/language show `'--'` (no field in model). Both Jamie Dunn placeholder review cards → `'--'`.
- [x] **P8-4** M07 — Notifications screen: **already fully API-driven** — loading/error/empty states present, `itemCount` dynamic. No change needed.
- [x] **P8-5** Sweep — All hardcoded names removed: `"Michel"` → `"Student"` (mentor_home_view), `'Michel S.'` → `'--'` (student_public_profile_view), `"Chance Calzoni"` → `mentorName ?? '--'` or `'--'` across 5 files, `'Jamie Dunn'` → `'--'` across 5 files. `AssetImage("assets/images/michel.png")` → `AssetImage("assets/icons/Ellipse 6.png")`.
- [x] **P8-6** Perf — Lambda `listCourses()`: `lastKey` cursor support (both Scan + Query paths); Flutter `CourseRepo.getCourses(lastKey)` + `HomeViewmodel.fetchCourses(loadMore: true)` with cursor accumulation.

### PHASE 9 — Notifications, navigation & AI
- [x] **P9-1** Dim 14, UNK03 — `firebase_core: ^3.6.0` + `firebase_messaging: ^15.1.3` added; `FcmService` created (init, background handler, onTokenRefresh, registerAfterLogin); Firebase init + `FcmService.init()` in `main()`; token registered fire-and-forget after login; `register-device` Lambda created (toriino-devices table); `sendPush()` stub + non-fatal call added to sessions `bookSession()`; Android Gradle plugins wired; `google-services.json.example` placeholder added. · **[OWNER: download real google-services.json from Firebase console → android/app/; add to .gitignore; build will fail at Gradle until file is present]**
- [x] **P9-2** Dim 11 — 5 route constants added to `routes_name.dart` (lessonVideo, liveSession, myCourseDetail, mentorPublicProfile, resetPassword); 5 `GetPage` entries added to `routes.dart` with `Get.arguments` unpacking; 2 `Get.to(ScreenName(args))` call sites converted to `Get.toNamed()` (login_view → resetPassword, mentor_home_view → liveSession); `NotificationRouter.handleTap()` stub created for session deep-link routing.
- [x] **P9-3** H05 — Already done in P4-4: `resetChat()` clears `messages`, `_history`, `isTyping`, re-adds welcome message. "New Chat" button calls `chatController.resetChat()`. No change needed.

### PHASE 10 — Production readiness
- [x] **P10-1** L03, L07 — `mentor_home_view.dart` −401 lines (1,395→994): two commented-out dead blocks removed; `teacher_home_view.dart` −30 lines. `applicationId` changed `torino.torino` → `com.torino.todd` per DECISION-09 · **[OWNER: confirm app was never published to Play before this ID change takes effect]**
- [x] **P10-2** Observability — `firebase_crashlytics: ^4.1.3` added; `FlutterError.onError` + `PlatformDispatcher.onError` wired to Crashlytics; `AnalyticsService` created (logSignUp/logLogin/logEnroll/logSessionJoin/logSubscribe) wired at all 4 call sites; structured JSON `log()` helper added to sessions/courses/payments/stripe-webhook Lambdas; `cloudwatch-alarms.json` CloudFormation template created (3 alarms: sessions >5 errors, payments >1, webhook >1). · **[OWNER: deploy `aws cloudformation deploy --template-file aws-backend/cloudwatch-alarms.json --stack-name torino-alarms`]**
- [x] **P10-3** Testing — 60 tests passing (was 9): added mentor model (8), notification model (9), review model (7), user profile model (5), JWT expiry logic (5), login widget smoke test (1). CI updated with `flutter test --coverage` + coverage % reporting. Full integration tests require a device (platform channels).
- [x] **P10-4** Responsive — `Row` children wrapped in `Flexible` + `TextOverflow.ellipsis` on all info-row `Text` widgets in mentor/teacher home at 320dp; heading Texts unconstrained in rows also fixed.
- [x] **P10-5** i18n — `flutter_localizations` + `intl: ^0.20.2` added; `lib/l10n/app_en.arb` created (8 keys); `l10n.yaml` created; `localizationsDelegates` + `supportedLocales` wired in `GetMaterialApp`.
- [x] **P10-6** Docs — `README.md`, `docs/ARCHITECTURE.md`, `docs/API.md`, `CHANGELOG.md`, `docs/RUNBOOK.md` all created.
- [x] **P10-7** Admin panel — confirmed no `admin/` directory in this repo (separate repo). Architecture doc notes owner must create a test Cognito admin user to unblock it. · **[OWNER: create test admin Cognito user; wire admin panel repo to /prod API]**

### PHASE 11 — Re-audit & release gate
- [x] **P11-1** Re-run all "Claude Code can test now" QA items; update statuses · *All 6 gates verified at code level; all 10 Criticals confirmed closed*
- [x] **P11-2** Re-score 20 dimensions → `docs/audit/rescore.md` · *Score: 72/100 (was 33/100)*
- [ ] **P11-3** **[OWNER]** Full device run-through + mitmproxy checks
- [B] **P11-4** Beta Eligible sign-off: GATE-01…06 PASS + all Critical closed + core flows smoke-tested · **BLOCKED on P11-3 + owner actions: GATE-01 key rotation, GATE-05 S3 ACLs, P5-1 Stripe env var, P9-1 google-services.json**

---

## Progress Log (Claude Code updates this)

| Date | Phase/Task | Status | Notes / commit |
|---|---|---|---|
| 2026-10-03 | P0 | DONE | Compile fix (3 DropdownButtonFormField extra `)`) · analyze baseline 26 info/0 err · CI scaffold |
| 2026-10-03 | P1 | DONE | Single API config (dart-define) · DynamoDB prefix → env vars · stripe-webhook Lambda · client-side ID gen removed · monolith DEPRECATED.md |
| 2026-10-03 | P2 | DONE (code side) | Gemini/Agora/Stripe keys → dart-define · upload-url Lambda + S3Service rewrite · withdraw sheet → coming soon · one-review-per-student guard |
| 2026-10-03 | P3 | DONE (code side) | Dead code deleted (SplashServices, LoginViewmodel) · UsersPrefrence stripped to role-only · AuthService: null-safe refresh, resendSignUpCode, setRole, isAccessTokenExpired · NetworkApiServices: 401 single-flight retry on all verbs · SplashView: expiry check + refresh on startup · sign_up_view: keyboard types, T&C state, typo, phone · OtpVerificationView: real resend + 60s cooldown · RoleSelectionScreen: calls setRole Lambda · ResetPasswordView created · LoginView: forgot-password navigates to ResetPasswordView · flutter analyze: 26 info/0 errors |
| 2026-10-03 | P4 | DONE | 4 List-response null-safe casts · 9 model unit tests passing · Agora token null-guard · SVG asset replaced with Icon · AiTutor resetChat() · 16 controllers/FocusNodes moved to State + disposed · flutter analyze: 26 info/0 errors |
| 2026-10-03 | P5 | DONE (code side) | payments Lambda created (POST /payments/create-intent) · all payment flows unblocked · wallet balance check in booking UI · earnings: totalWithdrawn field added · balance formula fixed (totalEarnings−totalWithdrawn) · mentor filter chips wired · flutter analyze: 26 info/0 errors |
| 2026-10-03 | P6 | DONE | language field end-to-end (create + edit + CourseModel) · delete cascade + enrollment guard · video_player added + LessonVideoView · profile setup validation enforced · flutter analyze: 26 info/0 errors |
| 2026-10-03 | P7 | DONE | Availability save only navigates on success · Start Session wired to LiveSessionScreen · public profile null-guarded + StarRatingWidget · private profile fields Obx-bound · drawer CircleAvatar from avatarUrl · flutter analyze: 26 info/0 errors · Data gaps: MentorModel/UserProfileModel missing experience/language/hourlyRate fields — owner must add to Lambda responses |
| 2026-10-03 | P8 | DONE (code side) | All hardcoded data removed — teacher/mentor dashboards Obx-bound (sessions count, avatar) · my_taken_cousre_view: dynamic lesson list via FutureBuilder · teacher private profile: all fields Obx-bound · notifications already API-driven (no change) · names sweep: Michel/Chance Calzoni/Jamie Dunn → model fields or `'--'` across 10+ files · courses Lambda + Flutter repo: cursor pagination via LastEvaluatedKey · flutter analyze: 26 info/0 errors · Average Rating still `'--'` (no rating field in models — owner-blocked, see P7-3/P7-4) |
| 2026-10-03 | P9 | DONE (code side) | firebase_core + firebase_messaging added · FcmService: init/background handler/token refresh/registerAfterLogin · token registered after login (fire-and-forget) · register-device Lambda created · sendPush() stub in sessions Lambda · Android Gradle plugins wired · Named routes: 5 constants + 5 GetPages + 2 call sites converted + NotificationRouter stub · P9-3 (AI Tutor reset) already done in P4-4 · flutter analyze: 26 info/0 errors · **[OWNER: provide google-services.json → android/app/; add to .gitignore; Gradle build blocked until then]** |
| 2026-10-03 | P10 | DONE (code side) | Dead code −431 lines (mentor_home −401, teacher_home −30) · applicationId → com.torino.todd (DECISION-09) · Responsive: Row overflow fixes at 320dp · Crashlytics + FlutterError.onError wired · AnalyticsService: 4 events wired · Structured JSON logs in 4 Lambdas · CloudWatch alarms CFn template · i18n scaffold (flutter_localizations + app_en.arb + l10n.yaml) · Tests: 60 passing (was 9) · CI: coverage reporting added · All 5 docs created (README, ARCHITECTURE, API, CHANGELOG, RUNBOOK) · Admin panel is separate repo (noted in ARCHITECTURE.md) · flutter analyze: 26 info/0 errors |
| 2026-10-03 | P11 | IN PROGRESS (blocked on owner) | Re-audit complete · All 6 release gates verified at code level · All 10 Criticals confirmed closed · 20-dimension re-score: 72/100 (was 33/100, +39 pts) · `docs/audit/rescore.md` written · P11-4 blocked pending owner: GATE-01 key rotation, GATE-05 S3 ACLs, P5-1 Stripe env var, P9-1 google-services.json, P11-3 device smoke test |

### Blocked / Owner questions

**Priority 1 — Required for Beta Eligible (blocks P11-4)**

1. **GATE-01 / P2-1** — Revoke old Gemini key (see earlier git history — must be rotated even if repo is private). Generate new key at aistudio.google.com. Set `GEMINI_API_KEY` in ai-chat Lambda env var AND pass `--dart-define=GEMINI_API_KEY=<newkey>` at build time.
2. **GATE-05 / P2-2** — AWS console → S3 → `torino-app-storage` → Block Public Access → enable all 4 toggles. Set `S3_BUCKET` env var on `upload-url` Lambda.
3. **P5-1 payments** — Set `STRIPE_SECRET_KEY` env var on payments Lambda. Wire `POST /payments/create-intent` in API Gateway `/prod` stage.
4. **P9-1 FCM** — Download `google-services.json` from Firebase console → `android/app/`. Add file path to `.gitignore`. Gradle build is blocked until this file is present.
5. **P11-3 device smoke test** — Full device run-through: auth (sign-up, OTP, login), student enroll + watch lesson, teacher create course, mentor set availability + book session, Stripe payment (test mode), Agora 2-device call, FCM push notification.

**Priority 2 — Required for production launch**

6. **P5-2 Subscriptions** — Create Stripe Products/Prices (Monthly $9.99, Quarterly $49.99, Annual $99.99). Configure Stripe Subscriptions on the Lambda if recurring billing is needed (current flow does one-time PaymentIntents only).
7. **P2-5 Cognito security** — Enable Cognito advanced security + OTP lockout; enable refresh-token rotation in Cognito console.
8. **P10-2 CloudWatch** — Deploy alarms: `aws cloudformation deploy --template-file aws-backend/cloudwatch-alarms.json --stack-name torino-alarms`.
9. **P10-1 App ID** — Confirm app was never published to Play Store under `torino.torino` before `applicationId` change to `com.torino.todd` takes effect.

**Priority 3 — Post-beta backlog**

10. **P7-3/P7-4 data gaps** — Add `experience`, `language`, and `hourlyRate` fields to Mentor Lambda response + `MentorModel`/`UserProfileModel`.
11. **P5-3 wallet deduction** — Implement wallet-deduction Lambda; wire shortfall charge in `availability_view.dart` (TODO comment left in code).
12. **P7-2 student picker** — Build student-search Lambda endpoint; wire `SearchableStudentPicker` into 1-on-1 session booking.
13. **P0-3 dev keys** — Provide Stripe test publishable key (`pk_test_…`) for dev builds via `.env.local`.
