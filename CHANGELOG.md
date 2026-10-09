# Changelog

## Phase 12 — Autonomous Remediation (2026-10-04)

### P0 Security + Payments
- **P0-1 FIXED**: Added payment metadata (type, courseId/sessionId, teacherId/mentorId) to Stripe PaymentIntent — Stripe webhook earnings crediting now fires correctly
- **P0-3 FIXED**: Replaced direct `GeminiService` SDK calls with `LambdaAiService` HTTP proxy — Gemini API key no longer embedded in Flutter binary; all AI calls route through Lambda
- **P0-2 OWNER**: Gemini key rotation pending (see OWNER_DECISIONS_REQUIRED.md OWN-01)

### P1 Bug Fixes
- **P1-1 FIXED**: Mentor home "Average Rating" ternary bug — both branches returned '--'; now shows actual rating from rxProfile
- **P1-2 FIXED**: Splash screen now reads role from JWT `custom:role` claim and overwrites SharedPreferences before routing — eliminates role/token divergence
- **P1-4 FIXED**: Reviews Lambda duplicate check — removed `Limit: 1` from FilterExpression query; one-review-per-user guard now works correctly at scale
- **P1-6 / P2-2 FIXED**: Sessions Lambda `sendPush()` — replaced broken GetCommand (sentinel key) with QueryCommand by userId; added conditional SNS delivery when `SNS_PLATFORM_APP_ARN` env var is set

### P2 Improvements
- **P2-1**: Payments Lambda now forwards client-provided metadata to Stripe PaymentIntent
- **P2-4 FIXED**: FCM foreground in-app notification banner implemented in `FcmService`
- **Dead code removed**: Deleted `lib/repository/mock/mock_data.dart` and `lib/repository/mock/mock_repo.dart`

### Documentation
- Created `OWNER_DECISIONS_REQUIRED.md` — 15 items requiring owner input documented with exact steps

## [Unreleased] — 2026-10-03

### Phase 10
- Expanded test coverage: mentor, notification, review, user profile, auth JWT, login widget tests
- README, ARCHITECTURE, API reference, RUNBOOK, and CHANGELOG documentation
- CI coverage step added to flutter.yml

### Phase 9
- Firebase Crashlytics error reporting
- FCM push notifications (pending google-services.json)
- GetX named routes for arg-taking screens
- AI Tutor "New Chat" clears full message history

### Phase 8
- All hardcoded placeholder data removed (Michel, Chance Calzoni, Jamie Dunn)
- Teacher/mentor dashboards fully API-driven
- Dynamic lesson list in student course detail
- Cursor pagination on courses list (DynamoDB LastEvaluatedKey)

### Phase 7
- Mentor availability save fix (only navigates on success)
- Start Session button wired to LiveSessionScreen
- Mentor public/private profile fields API-bound
- StarRatingWidget readOnly mode

### Phase 6
- Course language field end-to-end
- Course delete with enrollment guard + lesson cascade
- LessonVideoView with video_player
- Teacher profile setup form validation

### Phase 5
- Payments Lambda (POST /payments/create-intent)
- Stripe webhook Lambda with idempotency
- Wallet balance shown before session booking
- Earnings view data fixes (totalWithdrawn, filter chips)

### Phase 4
- Null-safe list parsing (courses, mentors, reviews, notifications)
- Agora token null-guard
- AiTutor resetChat() replaces onInit()
- TextEditingController/FocusNode memory leak fixes

### Phase 3
- Dead auth code removed (SplashServices, LoginViewmodel)
- Token refresh: single-flight 401 retry on all HTTP verbs
- Real OTP resend with 60s cooldown
- ResetPasswordView (2-step forgot password)
- T&C checkbox on sign-up

### Phase 2
- All secrets moved to --dart-define (Gemini, Agora, Stripe)
- S3 pre-signed upload (no AWS creds in app)
- Bank data collection removed (coming-soon UI)
- One-review-per-student guard in Lambda

### Phase 1
- Single API base URL via --dart-define
- DynamoDB table names via env vars
- Stripe webhook Lambda
- Client-side ID generation removed
- Monolith deprecated

### Phase 0
- Compile fix (3 DropdownButtonFormField extra `)`)
- flutter analyze baseline: 26 info-only warnings
- CI scaffold (.github/workflows/flutter.yml)
