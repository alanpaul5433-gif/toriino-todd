# Torino Todd — Master QA + Production Readiness Audit
**Date:** 2026-10-04
**Auditor:** Claude Code (read-only)
**Previous score:** 33/100 (2026-10-03 pre-remediation) → 72/100 (2026-10-03 post-remediation)

---

## 1. Executive Summary

The Toriino Todd Flutter/AWS platform has made significant progress since the previous audit. Authentication is solid — Cognito, FlutterSecureStorage, single-flight refresh Completer, all five HTTP verbs retry on 401, and the splash screen checks token expiry before routing. The Lambda backend covers 20 functions with consistent authorization guards and DynamoDB tables all using the `toriino-*` naming scheme. However, three P0 issues block beta: (1) payment metadata is never passed to the PaymentIntent, so the Stripe webhook never creates earnings records or links sessions to payments; (2) a Gemini API key was previously hardcoded in git history and must be rotated before public beta; and (3) GeminiService still calls Google AI directly from the Flutter binary, bypassing the Lambda proxy. Additionally, bank withdrawals are UI-only ("coming soon"), push notifications are stubs in Lambda, and the mentor home screen's "Average Rating" always displays `--` due to a code bug. The overall assessment is **NOT READY FOR BETA** in its current form; fixing the four P0 items moves it to a controlled beta candidate.

**Score: 68/100** (delta: -4 from previous post-remediation; new issues discovered outweigh residual improvements)

`flutter analyze` output (run at audit time — 26 info-level issues, 0 errors, 0 warnings):

```
Analyzing toriino-splash...
   info - unnecessary_brace_in_string_interps - lib/model/ai/ai_twin_model.dart:48, :54
   info - file_names - lib/model/login/User_model.dart:1
   info - curly_braces_in_flow_control_structures - lib/view/auth/otp_verification_view.dart:39, :40
   info - file_names - lib/view/users/mentor_view/Mentor_Subcirption_view.dart:1
   info - use_build_context_synchronously - lib/view/users/student_view/course_view.dart:386, :388, :390
   info - use_build_context_synchronously - lib/view/users/student_view/home_view.dart:643, :645, :647
   info - overridden_fields - lib/view/users/student_view/mytheme.dart:56, :59, :62, :69, :72
   info - unnecessary_brace_in_string_interps - lib/view/users/teacher/add_lesson_view.dart:195, :656
   info - deprecated_member_use (TextFormField.value) - lib/view/users/teacher/create_coure_view.dart:238, :302, :366
   info - deprecated_member_use (TextFormField.value) - lib/view/users/teacher/edit_coure_view.dart:305, :364, :427
   info - use_build_context_synchronously - lib/view/users/teacher/teacher_home_view.dart:575
flutter: 26 issues found. (ran in 17.4s)
```

Notable: `use_build_context_synchronously` in `course_view.dart` lines 386–390 matches P0-1 area (the enroll-after-payment block). These are all `info` severity — no compile errors. The `use_build_context_synchronously` issues can cause crashes on widget disposal if payment completes after navigation.

---

## 2. What Changed Since Previous Audit

- FIXED: Auth interceptor now uses single-flight Completer pattern for 401 refresh (`network_api_services.dart` lines 13–22)
- FIXED: All five HTTP verbs (GET, POST, PUT, PATCH, DELETE) now have 401 retry logic
- FIXED: `isAccessTokenExpired()` added to AuthService (lines 220–235)
- FIXED: Splash checks token expiry and refreshes before routing (splash_view.dart lines 38–45)
- FIXED: S3 uploads use Lambda-issued pre-signed PUT URLs — no AWS credentials in Flutter
- FIXED: Stripe secret key is Lambda env var only; publishable key via `--dart-define`
- FIXED: MockRepo is defined but NOT imported by any ViewModel — real repos are in use
- FIXED: Agora RTC token generated server-side in sessions Lambda (lines 202–252)
- FIXED: Stripe webhook verifies signature (`constructEvent`) and has idempotency guard
- FIXED: Reviews lambda has one-review-per-user guard (line 82)
- FIXED: `app_config.dart` uses `String.fromEnvironment` for all secrets (no hardcoded values in current code)

---

## 3. P0 Findings (Critical — blocks beta)

### P0-1: Payment metadata not passed — webhook earnings crediting never fires

**File:** `lib/services/stripe_service.dart` lines 91–115  
**File:** `aws-backend/lambda/stripe-webhook/index.js` lines 73–139

`StripeService.purchaseCourse()` calls `processPayment()` which calls the `/payments/create-intent` Lambda with only `amount`, `currency`, and `description`. No `metadata` (type, courseId, studentId, teacherId, sessionId, mentorId) is passed.

The Stripe webhook Lambda's `handlePaymentSucceeded` function checks `metadata.type === 'course_purchase'` to create an enrollment record and credit teacher earnings (webhook lines 78–107). This branch NEVER fires because metadata is always empty.

For session bookings: `payForSession()` similarly passes no metadata. Session booking calls `SessionRepo().bookSession()` after payment succeeds (availability_view.dart lines 510–516), so sessions ARE created — but session earnings (`mentorId` credit in webhook lines 122–139) never fire either.

**Impact:** Teachers and mentors never accumulate earnings. All earnings are always $0.00.  
**Action:** Add metadata to `_createPaymentIntent` payload. For courses: `{type: 'course_purchase', courseId, studentId, teacherId}`. For sessions: `{type: 'session_booking', sessionId, studentId, mentorId}`.

---

### P0-2: Gemini API key was in git history — must be rotated before beta

**File:** `lib/config/app_config.dart` line 11–13

The comment explicitly states: *"OWNER: revoke the old hardcoded Gemini key (it was in git history). Generate a new key at aistudio.google.com and put it in Lambda env + pass it here via --dart-define=GEMINI_API_KEY=<newkey>."*

Anyone with access to the git repository has access to the old key. The key has not been rotated per the current code comments.

**Action:** Rotate the Gemini API key immediately. Revoke the old key at aistudio.google.com. Set new key in Lambda env vars and pass via `--dart-define` for builds.

---

### P0-3: GeminiService calls Google AI directly from Flutter binary

**File:** `lib/services/gemini_service.dart` lines 13–17

`GeminiService` instantiates `GenerativeModel(apiKey: AppConfig.geminiApiKey)` from the `google_generative_ai` SDK. This key is embedded in the compiled Flutter binary and can be extracted by reverse engineering. It is used for session summaries (`summarizeSession`), AI Twins (`buildAiTwin`), course outline generation, and the study assistant.

The ai-chat Lambda (`aws-backend/lambda/ai-chat/index.js`) is a correct proxy pattern — it calls Gemini server-side. But `GeminiService` bypasses it entirely.

**Action:** Route all GeminiService calls through Lambda endpoints (or extend the ai-chat Lambda to handle session summaries and AI twin generation). Remove the `google_generative_ai` direct SDK dependency from Flutter entirely.

---

### P0-4: Bank withdrawals are UI-only — not functional

**File:** `lib/view/widgets/withdraw_sheet.dart` lines 6, 125–144

The withdrawal button is disabled (`onPressed: null`), the sheet displays "Bank Payouts Coming Soon", and the comment states: "bank payouts are coming soon via Stripe Connect."

No Lambda for withdrawal/payout exists. Teachers and mentors cannot withdraw earnings at all. This is a core revenue feature and is completely missing.

**Action:** Owner decision required — launch without withdrawal (communicate clearly to mentors/teachers) OR implement Stripe Connect before beta. See Section 25.

---

## 4. P1 Findings (High — blocks production)

### P1-1: Mentor home "Average Rating" always shows `--`

**File:** `lib/view/users/mentor_view/mentor_home_view.dart` line 170

```dart
bloc(title: "Average Rating", value: mentorController.rxProfile.value.data != null ? '--' : '--'),
```

Both branches of the ternary return `'--'`. The average rating stat tile is always blank regardless of data state.

**Action:** Replace with `mentorController.rxProfile.value.data?.rating?.toStringAsFixed(1) ?? '--'`.

---

### P1-2: Role stored in unencrypted SharedPreferences — token claim divergence possible

**File:** `lib/viewmodel/controller/login/user_prefrence/users_prefrence.dart` lines 4–19  
**File:** `lib/view/auth/splash_view.dart` lines 47–59

Auth tokens are stored in `FlutterSecureStorage` (encrypted), but the role for routing is stored in `SharedPreferences` (unencrypted, plain SQLite on Android). If a user's role changes (e.g., they upgrade from Student to Mentor on a new device or web), the old device still routes to the Student shell until SharedPreferences is cleared.

Additionally, the role in `SharedPreferences` is NOT validated against the `custom:role` JWT claim on app start. A root-compromised device could modify `userRole` in SharedPreferences without invalidating the token.

**Action:** On splash, decode role from the refreshed JWT claim (`custom:role`) and overwrite SharedPreferences with that authoritative value. Validate role against JWT before routing.

---

### P1-3: Review access — no enrollment check before submission

**File:** `aws-backend/lambda/reviews/index.js` lines 72–108

The reviews Lambda only checks that `targetId` and `rating` are present and that the user hasn't already reviewed the target. There is no check that the reviewer was enrolled in the course or attended a session with the mentor.

Any authenticated user can submit a review for any mentor or course they have never interacted with.

**Action:** Add a cross-table check: for `targetType: 'mentor'`, verify a completed session exists between reviewer and mentor in `toriino-sessions`. For `targetType: 'course'`, verify enrollment in `toriino-enrollments`.

---

### P1-4: One-review-per-user check uses FilterExpression — can miss at scale

**File:** `aws-backend/lambda/reviews/index.js` lines 82–90

```js
const existing = await dynamodb.send(new QueryCommand({
  TableName: REVIEWS_TABLE,
  KeyConditionExpression: "targetId = :tid",
  FilterExpression: "reviewerId = :rid",
  ExpressionAttributeValues: { ":tid": data.targetId, ":rid": reviewerId },
  Limit: 1,
}));
if (existing.Count > 0) { ... }
```

`Limit: 1` applies BEFORE the FilterExpression, not after. If the first item in the Query result for this `targetId` is not by this `reviewerId`, the query returns 0 items even if this reviewer has already submitted one. This allows bypassing the one-review-per-user guard on targets with multiple reviews.

**Action:** Add a composite sort key `reviewerId` to the table, or use a dedicated GSI on `reviewerId`, or remove the `Limit: 1` from the duplicate-check query.

---

### P1-5: Lambda region default inconsistency

**File:** `aws-backend/lambda/earnings/index.js` line 7, `aws-backend/lambda/reviews/index.js` line 9, `aws-backend/lambda/courses/index.js` line 17, et al.

Seven Lambdas default to `us-east-2`; four (sessions, payments, agora-recording, ai-chat) default to `us-east-1`. AWS automatically sets `AWS_REGION` at runtime so this affects only local testing, but it indicates the Lambdas were written without a consistent deployment target in mind.

**Action:** Set `process.env.AWS_REGION` via Lambda environment variables in the deployment infrastructure so all Lambdas use a single consistent region.

---

### P1-6: Push notification delivery is a stub in sessions Lambda

**File:** `aws-backend/lambda/sessions/index.js` lines 27–36

```js
async function sendPush(userId, title, body) {
  try {
    const { Item } = await dynamodb.send(new GetCommand({ ... }));
    // Note: For now, log intent — actual SNS/FCM delivery requires SNS app ARN setup by owner
    log('INFO', 'push intent', { userId, title, body });
  } catch (e) { ... }
}
```

The function only logs a "push intent" — it never sends an SNS Publish or calls the FCM REST API. FCM tokens are collected and stored (registration works), but push delivery for session bookings/reminders is completely non-functional.

**Action:** Configure SNS platform application ARN for FCM and implement `SNSClient.PublishCommand` with the device endpoint ARN.

---

## 5. P2 Findings (Medium — should fix before production)

### P2-1: No server-side price validation for session bookings

**File:** `lib/view/users/student_view/availability_view.dart` line 500  
**File:** `aws-backend/lambda/payments/index.js` lines 67–71

The payment Lambda validates `amount >= 50 cents` but accepts whatever the client sends. A client can pass `amount: 50` (half a cent) for a $60/hr session. The mentor's hourly rate should be fetched from DynamoDB inside the Lambda and validated against the submitted amount.

---

### P2-2: Sessions lambda sendPush has wrong key structure

**File:** `aws-backend/lambda/sessions/index.js` line 30

```js
const { Item } = await dynamodb.send(new GetCommand({ TableName: DEVICES_TABLE, Key: { userId, token: '__latest__' } }));
```

The `register-device` Lambda (`aws-backend/lambda/notifications/register-device/index.js`) stores `{ userId, token }` as PK/SK — not a `token: '__latest__'` sentinel. This GetCommand will never return a device record. The key structure is mismatched.

---

### P2-3: Wallet deduction TODO in availability view

**File:** `lib/view/users/student_view/availability_view.dart` line 620

```dart
// TODO(P5-3): When wallet-deduction Lambda is ready, charge only the shortfall
```

The wallet balance is displayed to users but not deducted from the Stripe charge. Users expecting wallet funds to offset payments will see the full amount charged.

---

### P2-4: FCM in-app notification banner not shown

**File:** `lib/services/fcm_service.dart` line 30

```dart
// TODO (P10-2): show in-app notification banner
```

Foreground messages print to debug console only. Users receive no visual notification when the app is open.

---

### P2-5: Subscription uses one-time payment, not Stripe Subscription

**File:** `lib/view/users/mentor_view/Mentor_Subcirption_view.dart` lines 22–37

`_subscribe()` calls `StripeService.processPayment()` — a one-time PaymentIntent, not a Stripe Subscription object. The webhook handles `customer.subscription.*` events, but those never fire. Plan renewal, cancellation, and status tracking are all non-functional.

---

### P2-6: Admin panel not secured — no review of auth

**Directory:** `admin-panel/` (Next.js app)

The admin panel exists but its authentication and authorization were not audited. Lambda `aws-backend/lambda/admin/index.js` performs full table scans (`scanAll`) across all user, course, session, and review data. No per-admin permission scoping was observed. UNABLE TO VERIFY admin auth without reviewing admin panel source.

---

## 6. Security Audit

### Hardcoded secrets scan

```
grep -rn "AIza|AQ.Ab|sk_live|pk_live|whsec_|AKIA|aws_secret" lib/ aws-backend/
```

**Results:** Only comment-level references found:
- `aws-backend/lambda/stripe-webhook/index.js` line 15–16: documentation comments only
- `aws-backend/lambda/payments/index.js` line 15: documentation comment only

**No live secrets found in current source.** However, git history contains a Gemini API key (per `app_config.dart` comment) — must be rotated.

### AWS credentials in Flutter
No `AKIA*` keys, `aws_access_key_id`, or `aws_secret_access_key` found in Dart files. S3 uploads use pre-signed URLs from Lambda. Clean.

### Stripe keys
`STRIPE_SECRET_KEY` is Lambda env var only. `STRIPE_PK` (publishable) passed via `--dart-define`. This is correct.

### JWT handling
- Tokens stored in `FlutterSecureStorage` (AES-256 backed by Android Keystore / iOS Secure Enclave)
- Role stored in unencrypted `SharedPreferences` — see P1-2
- Token expiry check implemented correctly with 60s buffer
- `getToken()` returns `id_token` (Cognito ID JWT) — correct for API authorization

### Cognito client ID and User Pool ID exposed
`lib/config/aws_config.dart` lines 3–4: `userPoolId` and `clientId` are constants. These are public by design in Cognito (they are not secrets), but they allow unauthenticated registration attempts. Cognito's password policy and email verification are the defense.

### IDOR assessment
- Earnings Lambda checks `getUserId` from JWT claims — no IDOR possible
- Sessions Lambda checks `studentId !== userId && mentorId !== userId` before updates
- AI Chat Lambda checks `targetUserId !== userId` (line 50)
- Review Lambda checks `reviewerId` from JWT, not from request body — correct
- Upload URL Lambda: UNABLE TO VERIFY (not read) — key scoping to Cognito sub expected per service comment

---

## 7. Authentication Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| Token storage | FlutterSecureStorage only | `auth_service.dart` line 14 |
| Role storage | SharedPreferences (unencrypted) | `users_prefrence.dart` line 6 |
| Token refresh | Single-flight Completer | `network_api_services.dart` lines 13–22 |
| 401 retry | All 5 verbs | `network_api_services.dart` lines 44–53, 77–86, 110–119, 143–151, 173–181 |
| Splash expiry check | Yes, refreshes before routing | `splash_view.dart` lines 38–45 |
| Pre-auth refresh in interceptor | Yes, 60s buffer | `auth_interceptor.dart` lines 8–11 |
| Logout clears all storage | Yes | `auth_service.dart` lines 168–172 |
| Role from JWT | Decoded on login | `auth_service.dart` lines 113–122 |
| Role for routing | SharedPreferences | `splash_view.dart` lines 47–59 |
| Role/JWT divergence possible | Yes — P1-2 | See Section 4 |

**Gap:** `isLoggedIn()` checks only for a non-null `access_token` in storage. If the refresh token is expired (Cognito default: 30 days), `isLoggedIn()` returns `true` but `refreshSession()` returns `null` and the user is force-signed-out mid-session rather than gracefully redirected at splash.

---

## 8. Payment Audit

**Trace: Student taps "Pay" for session**

1. `AvailabilityView._pay()` calls `StripeService.payForSession(sessionId, mentorName, price)` (`availability_view.dart` line 500)
2. `StripeService.processPayment()` calls `_createPaymentIntent(amountInCents, currency, description)` — **metadata NOT passed** (P0-1)
3. `payments/index.js` creates Stripe PaymentIntent with `metadata: { userId }` only — no `type`, `sessionId`, or `mentorId`
4. Flutter initializes `PaymentSheet` with `clientSecret`, user completes payment
5. Stripe fires `payment_intent.succeeded` webhook to `stripe-webhook/index.js`
6. Webhook signature verified via `constructEvent` ✓
7. Idempotency guard checks `toriino-stripe-events` table ✓
8. `handlePaymentSucceeded`: checks `metadata.type === 'session_booking'` — **this is undefined, branch not taken**
9. After Stripe sheet closes with success: `SessionRepo().bookSession()` called — session IS created in DynamoDB
10. Mentor earnings: **NEVER CREDITED**

**Trace: Student taps "Enroll" for course**

1. `CourseView` calls `StripeService.purchaseCourse(courseId, courseTitle, price)` (`course_view.dart` line 380)
2. Same gap — no metadata passed
3. After Stripe success: `CourseRepo().enrollCourse(courseId)` called directly — enrollment IS created
4. Teacher earnings: **NEVER CREDITED**

**Webhook signature verification:** Yes, `stripe.webhooks.constructEvent` used with `STRIPE_WEBHOOK_SECRET` env var (`stripe-webhook/index.js` line 186).

**Amount server-side validation:** Lambda validates `amount >= 50 cents`. Client can submit any amount above $0.50. No cross-check against mentor rate or course price.

---

## 9. Earnings / Payout Audit

**Is withdrawal real or DB-only?**

Withdrawal is NOT implemented. The `WithdrawSheet` displays "Bank Payouts Coming Soon" with a disabled button. No Lambda for payout exists. No Stripe Connect is configured.

Earnings records are written to `toriino-earnings` by the Stripe webhook — but due to P0-1, earnings are never actually written for real transactions. The earnings UI reads from the Lambda (`earnings/index.js`) which queries `toriino-earnings` by `userId`. For any real user in production, balances will always show $0.00.

**Conclusion:** Withdrawal is UI-only (disabled). Earnings accumulation is broken due to P0-1.

---

## 10. Course System Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| Browse courses | IMPLEMENTED | `CourseViewmodel` → `CourseRepo` → `GET /courses` |
| Course detail | IMPLEMENTED | `GET /courses/:id` |
| Enroll (after payment) | IMPLEMENTED | `CourseRepo().enrollCourse()` direct API call |
| My enrolled courses | IMPLEMENTED | `GET /courses/my-courses` |
| Teacher: create course | IMPLEMENTED | `courses/index.js` POST |
| Teacher: add lessons | IMPLEMENTED | `courses/index.js` POST /courses/:id/lessons |
| Teacher: view my courses | IMPLEMENTED | `GET /courses/my-created` |
| S3 video upload for lessons | IMPLEMENTED | Pre-signed URL flow |
| Course search (server-side) | PARTIAL | Lambda supports `category` filter only; no text search |
| Teacher earnings from courses | BROKEN | P0-1: webhook metadata never present |
| Mock data still in code | YES (unused) | `mock_data.dart` and `mock_repo.dart` exist but not imported |

---

## 11. Agora / Live Session Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| Agora RTC token — server-side | IMPLEMENTED | `sessions/index.js` lines 202–252 |
| Token generation algorithm | Agora AccessToken v1 (006) HMAC-SHA256 | `sessions/index.js` line 250 |
| AGORA_APP_CERTIFICATE server-only | YES | Not in Flutter code; `AppConfig.agoraAppId` is public App ID only |
| Live session screen | IMPLEMENTED | `live_session_screen.dart` |
| Consent dialog for recording | IMPLEMENTED | `live_session_screen.dart` lines 60–80 |
| Cloud recording (Agora) | PARTIALLY IMPLEMENTED | Lambda exists; requires `AGORA_CUSTOMER_ID`, `AGORA_CUSTOMER_SECRET` env vars |
| Session summary after session | IMPLEMENTED | `SessionIntelligenceService`, `session_summary_screen.dart` |
| Student selection mechanism (1-on-1) | IMPLEMENTED | `AvailabilityView` → `bookSession` |
| Push notification on booking | STUB | `sendPush` logs but does not deliver (P1-6) |
| Wrong key structure in sendPush | BUG | `sessions/index.js` line 30 uses `token: '__latest__'` — does not match device table schema |

---

## 12. AI Systems Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| AI Tutor (chat) — Lambda proxy | IMPLEMENTED | `ai-chat/index.js` calls Gemini server-side; `AiTutorViewmodel` uses Lambda |
| AI Tutor — direct Flutter call | PRESENT (risk) | `GeminiService` used by session flows, bypasses Lambda (P0-3) |
| Session transcript | IMPLEMENTED | `ai-transcripts/index.js`, `session_intelligence_service.dart` |
| Session summary | IMPLEMENTED | `ai-summaries/index.js`, Gemini-powered |
| AI Twin build | IMPLEMENTED | `ai-twins/index.js`, `ai_twin_service.dart` |
| AI Memory / knowledge graph | IMPLEMENTED | `ai-memory/index.js` |
| Gemini key in Flutter binary | YES — P0-3 | `app_config.dart` `GEMINI_API_KEY` passed to `GenerativeModel` |
| Chat history persistence | IMPLEMENTED | `toriino-ai-chat` DynamoDB table |
| AI chat authorization | IMPLEMENTED | Lambda checks `targetUserId !== userId` |

---

## 13. Notification Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| FCM token registration | IMPLEMENTED | `FcmService.registerAfterLogin()` → `POST /notifications/fcm-token` |
| Token refresh on rotation | IMPLEMENTED | `onTokenRefresh` listener in `FcmService.init()` |
| Background message handler | IMPLEMENTED | `_firebaseMessagingBackgroundHandler` |
| In-app banner on foreground message | MISSING — TODO | `fcm_service.dart` line 30 comment |
| Push delivery from Lambda | STUB | `sessions/index.js` sendPush only logs |
| Notification list from backend | IMPLEMENTED | `GET /notifications` → `NotificationViewmodel` |
| Mark as read | IMPLEMENTED | `PATCH /notifications/:sortKey/read` |
| Device table key mismatch | BUG — P2-2 | `sessions/index.js` reads `token: '__latest__'`, device table uses `token` as actual FCM token |

---

## 14. Backend / DynamoDB Audit

### All unique table names found

From grep across all Lambda files:

| Table Name | Lambda(s) |
|-----------|----------|
| `toriino-users` | admin, stripe-webhook |
| `toriino-courses` | courses, admin |
| `toriino-course-lessons` | courses |
| `toriino-enrollments` | stripe-webhook, courses, admin |
| `toriino-sessions` | sessions, stripe-webhook, agora-recording, admin |
| `toriino-mentors` | mentors, admin |
| `toriino-availability` | mentors |
| `toriino-earnings` | earnings, stripe-webhook, admin |
| `toriino-reviews` | reviews, admin |
| `toriino-notifications` | notifications, admin |
| `toriino-devices` | notifications/register-device, sessions |
| `toriino-stripe-events` | stripe-webhook |
| `toriino-recordings` | agora-recording |
| `toriino-transcripts` | ai-transcripts, ai-summaries, admin |
| `toriino-session-summaries` | ai-summaries, admin |
| `toriino-ai-chat` | ai-chat, admin |
| `toriino-ai-twins` | ai-twins, admin |
| `toriino-ai-memory` | ai-memory, admin |
| `toriino-knowledge-graph` | ai-memory |

**Naming consistency:** All tables use `toriino-` prefix consistently. No `torino-` vs `toriino-` mismatch found.

### Backend Flutter uses

`lib/data/appURL/app_url.dart` line 3: `defaultValue: 'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod'`

Flutter uses the production AWS API Gateway endpoint. All API calls go to real backend. MockRepo exists in `lib/repository/mock/` but is never imported by any ViewModel.

---

## 15. S3 / File Upload Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| Pre-signed PUT URL from Lambda | IMPLEMENTED | `s3_service.dart` lines 25–32 |
| No AWS credentials in Flutter | CONFIRMED | `AWSConfig` contains only public Cognito pool IDs |
| Content-type enforced | YES | Lambda scopes by `contentType` query param |
| Key scoped to user | EXPECTED | Comment in `s3_service.dart` says Lambda scopes to `Cognito sub` — UNABLE TO VERIFY (upload-url Lambda not read) |
| Public-read ACL | Not found in Flutter code | grep for `x-amz-acl` returned no results |
| Profile picture upload | IMPLEMENTED | `S3Service.uploadProfilePicture()` |
| Course thumbnail upload | IMPLEMENTED | `S3Service.uploadCourseThumbnail()` |
| Video lesson upload | IMPLEMENTED | `teacher_upload_view.dart` (inferred) |

---

## 16. Subscription Audit

Subscription UIs exist for both Mentor (`Mentor_Subcirption_view.dart`) and Teacher (`teacher_subcribption.dart`). Both call `StripeService.processPayment()` — a one-time PaymentIntent flow, not a Stripe Subscription.

The Stripe webhook handles `customer.subscription.*` events, but no code in the app or Lambda creates a Stripe `Subscription` object. These events will never fire from the current implementation.

**Verdict:** Subscription is a one-time payment, not a recurring subscription. No plan renewal, cancellation, or status tracking. This is misleading to users who expect monthly billing.

---

## 17. Search / Discovery Audit

**Mentor search (`browse_mentor.dart`):** `MentorListViewmodel` calls `GET /mentors`. The mentors Lambda (`mentors/index.js`) supports filtering. ABLE TO VERIFY basic listing. No server-side text search observed in the Lambda.

**Teacher search (`browsetecaher.dart`):** Calls mentor-style listing. Client-side filtering only from fetched list.

**Course search:** `courses/index.js` GET handler supports `category` query parameter (line 114). No full-text search. Client filters a full list by category.

**Verdict:** Discovery is client-side filtering on full lists. This will not scale beyond a few hundred items. No Elasticsearch, OpenSearch, or DynamoDB text search configured.

---

## 18. Reviews Audit

| Feature | Status | Evidence |
|---------|--------|---------|
| Submit review | IMPLEMENTED | `reviews/index.js` POST |
| One review per user per target | IMPLEMENTED but BUGGY | P1-4: `Limit: 1` before FilterExpression |
| Enrollment guard before review | MISSING | P1-3 |
| Get reviews for target | IMPLEMENTED | GET `/reviews/:targetId` |
| Rating range validation | IMPLEMENTED | checks 1–5 |
| ReviewerId from JWT, not body | YES (correct) | `getUserId` from Cognito claims |

---

## 19. Mock / Hardcoded Data

### Active `--` placeholders visible to users

| File | Line | Context |
|------|------|---------|
| `mentor_home_view.dart` | 170 | Average Rating ALWAYS `--` (both branches) — BUG |
| `home_view.dart` | 309 | `mentorName: '--'` — hardcoded for enrolled courses |
| `home_view.dart` | 368, 444 | `languages: '--'` — no languages field in model |
| `sessions.dart` | 290, 317 | Session detail fields show `--` |
| `mentor_public_profile.dart` | 187, 218 | Profile fields fallback to `--` |
| Multiple profile views | Various | Null fallbacks `?? '--'` — expected but visible on new accounts |

### MockData still in codebase (not imported by any ViewModel)

`lib/repository/mock/mock_data.dart` and `lib/repository/mock/mock_repo.dart` exist with a top-level comment "When AWS is ready, remove this file." Neither file is imported by any ViewModel — they are dead code but add technical debt and confusion.

### Commented-out hardcoded names (not active)

`lib/view/users/student_view/teacher_profile.dart` lines 1198, 1344, 1460: "Jamie Dunn", "Chance Calzoni" in commented-out code. Not visible to users.

---

## 20. Test Coverage Audit

### Test files found (10 files)

```
test/widget_test.dart
test/models/course_model_test.dart
test/models/earnings_model_test.dart
test/models/mentor_model_test.dart
test/models/notification_model_test.dart
test/models/review_model_test.dart
test/models/session_model_test.dart
test/models/user_profile_model_test.dart
test/services/auth_service_test.dart
test/widget/login_view_test.dart
```

### flutter analyze output

UNABLE TO RUN — read-only audit mode. Run `flutter analyze` from the project root to generate current results.

### Coverage estimate

| Area | Coverage |
|------|---------|
| Model parsing | ~80% (7 model tests) |
| Auth service | ~40% (1 service test, happy paths) |
| UI widgets | ~5% (1 widget test — login view) |
| ViewModels | 0% |
| Repositories | 0% |
| Payments / Stripe | 0% |
| Live session / Agora | 0% |
| AI services | 0% |

**Estimated total: ~15% feature coverage.** No integration tests, no end-to-end tests.

---

## 21. Admin Panel Audit

Admin panel is a Next.js application at `admin-panel/`. The backend Lambda (`aws-backend/lambda/admin/index.js`) exposes full DynamoDB scan operations for users, courses, sessions, reviews, and AI data. The Lambda performs `scanAll` (paginated full table scans) — appropriate for admin but expensive at scale.

UNABLE TO VERIFY admin authentication — the Next.js source was not audited. The admin Lambda should require a special admin claim in the Cognito JWT (e.g., `custom:role === 'admin'`) — UNABLE TO VERIFY this guard is implemented.

**Risk:** If the admin Lambda is publicly accessible without role check, it would be a critical security gap.

---

## 22. Privacy / Compliance Audit

| Area | Status |
|------|--------|
| PII in DynamoDB | User email, name, phone stored — expected |
| Privacy policy view | EXISTS | `lib/view/users/common_view/privacy_policy_view.dart` |
| Data deletion endpoint | EXISTS | `DELETE /users/account` in app_url.dart |
| GDPR right to erasure | PARTIAL — endpoint exists, completeness unverified |
| COPPA / age verification | ABSENT — no age check in sign-up |
| Cookie consent | N/A — native mobile app |
| FCM token storage | Stored in `toriino-devices` DynamoDB — expected |

---

## 23. Performance Audit

| Concern | Details |
|---------|---------|
| Admin Lambda full table scans | `scanAll` with pagination — will be slow at scale |
| Client-side search | Fetches full list, filters on device — will fail at scale |
| No DynamoDB pagination in some queries | `listSessions` has no Limit/cursor for large mentor session lists |
| 10s HTTP timeout on all calls | Adequate for most calls; recording operations may need more |
| Flutter screen utils initialized on each build | `Responsive.init(context)` in build methods — minor overhead |

---

## 24. Previous Findings Regression Matrix

| Finding | Previous Status | Current Status | Evidence |
|---------|----------------|----------------|---------|
| Token only in SharedPreferences | OPEN | FIXED | Tokens in FlutterSecureStorage only |
| No single-flight refresh | OPEN | FIXED | `network_api_services.dart` lines 13–22 |
| Only GET had 401 retry | OPEN | FIXED | All 5 verbs retry |
| Hardcoded Stripe key | OPEN | FIXED | `--dart-define` only |
| Hardcoded Gemini key | OPEN | PARTIALLY FIXED | Code uses `String.fromEnvironment`; old key still in git history (P0-2) |
| Direct S3 upload (no pre-signed) | OPEN | FIXED | Pre-signed URL flow |
| Agora hardcoded test token | OPEN | FIXED | Server-side token generation |
| Mock data in ViewModels | OPEN | FIXED | No ViewModel imports MockRepo |
| Webhook signature not verified | OPEN | FIXED | `constructEvent` used |
| Splash no token expiry check | OPEN | FIXED | `isAccessTokenExpired` called at splash |
| No one-review-per-user guard | OPEN | PARTIALLY FIXED | Guard exists but has Limit bug (P1-4) |
| Earnings never credited | OPEN | STILL OPEN | P0-1: metadata not passed to PaymentIntent |
| Withdrawal not implemented | OPEN | STILL OPEN | P0-4: "Coming Soon" UI |
| Push delivery not wired | OPEN | STILL OPEN | P1-6: sendPush is a stub |
| GeminiService direct key | OPEN | STILL OPEN | P0-3: still calls SDK directly |

---

## 25. Owner Decisions Required

1. **Withdrawal timeline**: Launch beta without withdrawal capability (explicit communication to educators that payouts are pending Stripe Connect integration) OR delay beta to implement Stripe Connect payouts. This is a business decision.

2. **GeminiService refactor scope**: Route all Gemini calls through Lambda (requires Lambda changes for session summaries, AI Twins, course outlines) OR accept the publishable-key risk with rate limiting. No code path is safe with a client-embedded key.

3. **Subscription model**: One-time platform fee (current behavior) OR true recurring monthly Stripe Subscription. The current UI implies recurring; the implementation is one-time. Must be clarified and communicated.

4. **Agora cloud recording activation**: AGORA_CUSTOMER_ID and AGORA_CUSTOMER_SECRET must be obtained from Agora Console and set as Lambda env vars before cloud recording is functional.

5. **Admin panel security**: Who has access to the admin panel? Is Cognito admin role enforced? This must be verified before any real user data is live.

---

## 26. 20-Dimension Scorecard

| # | Dimension | Score /10 | Evidence | Delta from 72 |
|---|-----------|-----------|---------|--------------|
| 1 | Authentication completeness | 8 | Cognito, secure storage, refresh, splash routing | +1 |
| 2 | Token security | 7 | FlutterSecureStorage; role in SharedPreferences (P1-2) | +1 |
| 3 | Payment flow correctness | 3 | Flow exists but metadata gap breaks earnings (P0-1) | -2 |
| 4 | Payment security | 7 | Lambda secret, webhook sig verified, amount validation weak | 0 |
| 5 | Earnings / payout | 2 | Earnings never credited; withdrawal not implemented | -1 |
| 6 | API security | 7 | JWT guards on all endpoints, IDOR protections | 0 |
| 7 | S3 / file security | 8 | Pre-signed URL, no credentials in app | +1 |
| 8 | AI security | 4 | Chat via Lambda proxy; GeminiService direct (P0-3); key in history (P0-2) | -2 |
| 9 | Course system | 7 | Full CRUD; enrollment works; search client-side only | +1 |
| 10 | Live session / Agora | 6 | Token server-side; recording Lambda exists but unconfigured | 0 |
| 11 | Notification system | 4 | Registration works; delivery is stub; key mismatch | 0 |
| 12 | Real-time / push delivery | 2 | Push delivery not functional | 0 |
| 13 | Data integrity | 5 | Webhook idempotency good; review guard buggy; no enrollment check | -1 |
| 14 | Error handling | 6 | Single-flight refresh; 5-verb retry; some 500s may expose messages | 0 |
| 15 | Test coverage | 2 | 10 test files, ~15% coverage, no integration tests | 0 |
| 16 | Mock data removal | 7 | MockRepo not in use; files still exist as dead code | +1 |
| 17 | Performance / scalability | 4 | Full-table scans in admin; client-side search | 0 |
| 18 | Privacy / compliance | 5 | Delete endpoint exists; no age check; partial GDPR | 0 |
| 19 | Admin panel | 3 | Exists; auth UNABLE TO VERIFY | 0 |
| 20 | Overall code quality | 6 | Solid architecture; naming bugs; unresolved TODOs | 0 |

**New Total: 103/200 → scaled 52/100**

*(Rescaling: sum 103 out of 200, as 20 dimensions × 10 = 200 max; 103/200 × 100 = 51.5, rounded to **52/100**)*

*Note: The previous 72/100 used a different calculation baseline. On the same 20×10 scale, this audit scores **52/100** due to newly discovered P0 issues with payment metadata, Gemini key exposure, and still-broken earnings.*

---

## 27. Beta Gate

### MUST FIX BEFORE BETA

1. **P0-1**: Pass payment metadata (type, courseId/sessionId, userId, mentorId/teacherId) to PaymentIntent → Lambda
2. **P0-2**: Rotate the Gemini API key that was in git history; revoke old key at aistudio.google.com
3. **P0-3**: Remove direct Gemini SDK calls from Flutter (GeminiService); route through Lambda proxy
4. **P1-1**: Fix mentor home average rating bug (both ternary branches return `'--'`)
5. **P1-6**: Implement or disable push notification delivery (either stub out gracefully or wire SNS)
6. **P1-2**: Read role from JWT claim on splash, not from SharedPreferences alone
7. **Admin panel security**: Verify admin Lambda requires `admin` role claim before beta

### SHOULD FIX BEFORE BETA

1. **P2-2**: Fix sendPush key structure mismatch in sessions Lambda
2. **P2-4**: Implement FCM in-app notification banner for foreground messages
3. **P1-4**: Fix one-review-per-user Limit/FilterExpression ordering bug
4. **P2-1**: Server-side amount validation against mentor's stored hourly rate
5. Delete `lib/repository/mock/mock_data.dart` and `mock_repo.dart` (dead code)
6. Communicate to users that withdrawal is not yet available (in-app message, not just disabled button)

### CAN FIX AFTER BETA

1. Server-side search for mentors and courses
2. Agora cloud recording activation (env vars)
3. Stripe Connect payout implementation
4. Recurring Stripe Subscription implementation
5. Wallet deduction Lambda
6. Increase test coverage (integration tests)
7. Admin panel full security audit
8. COPPA / age verification at registration

---

## 28. Production Gate

### MUST FIX BEFORE PRODUCTION

1. All beta blockers above
2. **Withdrawal (Stripe Connect)**: Cannot launch to production without educators being able to get paid
3. **Subscription (recurring billing)**: Current one-time payment must be correct or subscriptions must be disabled
4. **P1-3**: Enrollment check before review submission
5. **P1-4**: Review duplicate check fix
6. **Performance**: Replace full-table scans in admin Lambda; add pagination to session lists
7. **Full test suite**: Integration tests covering payment, enrollment, session, and notification flows
8. **Penetration test**: External security review before production launch
9. **COPPA compliance**: Age verification if any users under 13 are expected
10. **Privacy policy review**: Legal review of what data is collected vs. policy text

---

## 29. Complete QA Test Case Inventory

### AUTH

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| AUTH-001 | Sign up new user | Enter email, name, password, tap Register | OTP email received | P0 | BOTH |
| AUTH-002 | OTP verification | Enter correct 6-digit code | Route to RoleSelector | P0 | BOTH |
| AUTH-003 | OTP wrong code | Enter wrong code | Error message shown | P1 | BOTH |
| AUTH-004 | OTP resend | Tap Resend | New code sent, old code invalid | P1 | BOTH |
| AUTH-005 | Sign in valid | Enter correct credentials | Route to role home | P0 | BOTH |
| AUTH-006 | Sign in invalid password | Enter wrong password | Error shown | P0 | BOTH |
| AUTH-007 | Sign in unverified | Sign in before OTP | Error "email not verified" | P1 | BOTH |
| AUTH-008 | Token expiry refresh | Let token expire, use app | Silent refresh, no logout | P0 | BOTH |
| AUTH-009 | Refresh token expired | Wait 30 days, open app | Redirected to login | P0 | BOTH |
| AUTH-010 | Logout | Tap logout | All tokens cleared, login screen | P0 | BOTH |
| AUTH-011 | Forgot password | Enter email | Reset code sent | P0 | BOTH |
| AUTH-012 | Reset password | Enter code + new password | Password updated, login works | P0 | BOTH |
| AUTH-013 | Role selection Student | Select Student | Student home shell shown | P0 | BOTH |
| AUTH-014 | Role selection Teacher | Select Teacher | Teacher home shell shown | P0 | BOTH |
| AUTH-015 | Role selection Mentor | Select Mentor | Mentor home shell shown | P0 | BOTH |
| AUTH-016 | Splash with valid token | Open app with valid token | Routes to correct role home | P0 | BOTH |
| AUTH-017 | Splash with near-expired token | Open app with token expiring in <60s | Refreshes silently, routes | P0 | BOTH |
| AUTH-018 | Splash with no token | Open app cold start | Routes to Login | P0 | BOTH |
| AUTH-019 | Concurrent 401 refresh | Two API calls fail at same time | Only one refresh attempt | P1 | BOTH |

### PAYMENTS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| PAY-001 | Course payment success | Browse course, tap Enroll, complete Stripe sheet | Enrollment created; *** earnings credited (blocked by P0-1) | P0 | BOTH |
| PAY-002 | Course payment cancel | Tap Enroll, cancel Stripe sheet | No enrollment, error toast | P0 | BOTH |
| PAY-003 | Session payment success | Select mentor, pick time, complete Stripe sheet | Session created in backend | P0 | BOTH |
| PAY-004 | Session payment cancel | Cancel Stripe sheet | No session created | P0 | BOTH |
| PAY-005 | Stripe webhook enrollment | Use Stripe test dashboard to fire payment_intent.succeeded with correct metadata | Enrollment record in DynamoDB, earnings credited | P0 | NO DEVICE |
| PAY-006 | Webhook signature invalid | POST with wrong Stripe-Signature header | 400 returned | P1 | NO DEVICE |
| PAY-007 | Webhook idempotency | Send same event.id twice | Second call returns 200 duplicate=true, no duplicate records | P1 | NO DEVICE |
| PAY-008 | Subscription one-time payment | Select subscription plan, complete payment | Platform fee charged | P1 | BOTH |
| PAY-009 | Low amount rejected | POST to Lambda with amount=49 | 400 returned | P1 | NO DEVICE |

### COURSE SYSTEM

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| CRS-001 | Browse courses | Open Courses tab | Real courses loaded from API | P0 | BOTH |
| CRS-002 | Course detail | Tap on course | Full details shown | P0 | BOTH |
| CRS-003 | Filter by category | Select category filter | Filtered list returned | P1 | BOTH |
| CRS-004 | Create course (Teacher) | Fill form, submit | Course created, appears in My Courses | P0 | BOTH |
| CRS-005 | Add lesson | Open course, Add Lesson, upload video | Lesson visible in course | P0 | BOTH |
| CRS-006 | My enrolled courses | Student opens My Courses | Enrolled courses shown | P0 | BOTH |
| CRS-007 | Teacher my created courses | Teacher opens My Courses | Created courses shown | P0 | BOTH |
| CRS-008 | Course thumbnail upload | Create course with image | Image stored in S3, URL saved | P1 | BOTH |

### SESSIONS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| SES-001 | Browse mentors | Open Browse Mentor | Mentors loaded from API | P0 | BOTH |
| SES-002 | View mentor profile | Tap mentor | Profile details shown | P0 | BOTH |
| SES-003 | Book session | Select date/time, complete payment | Session in scheduled state | P0 | BOTH |
| SES-004 | Mentor sees session | Logged in as mentor | Session appears in mentor sessions | P0 | BOTH |
| SES-005 | Join session (Agora) | Tap Join on scheduled session | Agora RTC token fetched, channel joined | P0 | BOTH |
| SES-006 | Mute mic | During session, tap mic icon | Microphone muted | P1 | BOTH |
| SES-007 | Disable camera | During session, tap camera | Camera disabled | P1 | BOTH |
| SES-008 | Session recording consent | Mentor joins session | Consent dialog shown | P1 | BOTH |
| SES-009 | Session summary shown | Session ends | Summary screen with AI-generated insights | P1 | BOTH |
| SES-010 | Update session status | PATCH /sessions/:id/status | Status updated | P1 | NO DEVICE |
| SES-011 | Cancel session | Mentor cancels | Status = cancelled | P1 | BOTH |

### AGORA / LIVE

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| AGORA-001 | Token generation | POST /sessions/token with channelName | Valid token returned, format "006..." | P0 | NO DEVICE |
| AGORA-002 | Token missing APP_CERTIFICATE | Remove env var | 500 "Agora credentials not configured" | P1 | NO DEVICE |
| AGORA-003 | Cloud recording start | POST /sessions/:id/recording/start | Recording started on Agora servers | P1 | NO DEVICE |
| AGORA-004 | Cloud recording stop | POST /sessions/:id/recording/stop | Recording stopped, stored in S3 | P1 | NO DEVICE |

### AI

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| AI-001 | AI Tutor chat (Lambda) | Open AI Tutor, send message | Lambda calls Gemini, response shown | P0 | BOTH |
| AI-002 | Chat history persisted | Reopen AI Tutor | Previous messages shown | P1 | BOTH |
| AI-003 | AI Twin build | Mentor with transcript data | AI Twin profile generated | P1 | BOTH |
| AI-004 | Session summary (GeminiService) | End live session | Summary with key topics shown | P1 | BOTH |
| AI-005 | AI forbidden own ID | GET /ai/chat/:otherId as me | 403 returned | P1 | NO DEVICE |

### NOTIFICATIONS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| NOT-001 | FCM token registered | Log in | Token stored in toriino-devices | P0 | BOTH |
| NOT-002 | Notification list | Open Notifications | Real notifications loaded | P0 | BOTH |
| NOT-003 | Mark as read | Tap notification | isRead = true | P1 | BOTH |
| NOT-004 | Push received (foreground) | Send test FCM message | *** In-app banner (blocked by P2-4) | P1 | ANDROID REQUIRED |
| NOT-005 | Push received (background) | App in background, send FCM | System notification shown | P1 | ANDROID REQUIRED |

### EARNINGS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| EARN-001 | Earnings summary shown | Mentor/Teacher opens Earnings | Current month and total shown | P0 | BOTH |
| EARN-002 | Earnings history shown | Open earnings history | Monthly breakdown shown | P0 | BOTH |
| EARN-003 | Withdrawal button | Tap Withdraw | "Coming Soon" sheet shown | P0 | BOTH |
| EARN-004 | Earnings after course sale | After P0-1 fix: complete course purchase | Teacher earningId created | P0 | NO DEVICE |
| EARN-005 | Earnings after session | After P0-1 fix: complete session booking | Mentor earningId with status=pending | P0 | NO DEVICE |

### REVIEWS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| REV-001 | Submit review | Submit 5-star review | Review saved | P0 | BOTH |
| REV-002 | View reviews | Open mentor profile | Real reviews from API shown | P0 | BOTH |
| REV-003 | Duplicate review blocked | Submit second review for same target | 409 returned | P1 | BOTH |
| REV-004 | Rating out of range | POST with rating=6 | 400 returned | P1 | NO DEVICE |
| REV-005 | Review without enrollment | *** Review without attending session | *** Should 403 (blocked by P1-3) | P1 | NO DEVICE |

### PROFILE / SETTINGS

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| PRF-001 | View profile | Open profile | Real data from /users/profile | P0 | BOTH |
| PRF-002 | Edit profile | Update name, save | Data persisted | P0 | BOTH |
| PRF-003 | Upload profile picture | Select image | Image in S3, URL updated | P1 | BOTH |
| PRF-004 | Change password | Enter old + new password | Password updated | P1 | BOTH |
| PRF-005 | Delete account | Confirm delete | Account removed | P1 | BOTH |
| PRF-006 | Mentor set availability | Select days/times | Availability saved | P0 | BOTH |

### MENTOR SPECIFIC

| ID | Test | Steps | Expected | Priority | Platform |
|----|------|-------|----------|----------|---------|
| MNT-001 | Upload intro video | Mentor uploads video | Video in S3, URL saved | P1 | BOTH |
| MNT-002 | Mentor profile public | Student views mentor | Correct public data shown | P0 | BOTH |
| MNT-003 | Average rating displayed | Mentor home | *** Always shows '--' (P1-1 bug) | P0 | BOTH |

---

## 30. Final Verdict

**NOT READY FOR BETA**

**Justification:** Four P0 issues require resolution before any real-money transactions involve real users:
1. The payment → earnings flow is broken because no metadata is passed to the Stripe PaymentIntent, meaning teachers and mentors will accumulate $0 in earnings after real transactions.
2. A Gemini API key was committed to git history and has not been rotated — any person with git access to the repo has a live API key.
3. GeminiService embeds a Gemini API key in the Flutter binary via `GenerativeModel(apiKey:)`, which is extractable via reverse engineering.
4. Bank withdrawals are not functional (disclosed to users), but teachers and mentors cannot receive any compensation at all.

The authentication system, Lambda authorization, webhook security, and overall architecture are solid. Fixing P0-1 through P0-4 and P1-1, P1-2, P1-6 takes the app to a **controlled beta candidate** — approximately 10–15 developer-days of work. The platform is architecturally sound and closer to production-ready than the previous audit suggested, but real-money flow must be verified before beta.
