# Backend Verification — /prod

## Re-verification, round 2 (2026-10-07, branch `fix/remediation-v1`)

`node scripts/verify-backend.mjs` (the checker's updated script, commit `381876f`) against deployment `t76glk`. Full output: [verify-after-remediation.txt](verify-after-remediation.txt).

**Result: 24 WORKS · 3 BLOCKED · 0 BROKEN · 0 NOT DEPLOYED. Exit code 0 (PASS).**

BLOCKED, missing third-party values only: Stripe payment intent and webhook (`STRIPE_*` = `NOT_SET` → 503 "not configured"), and FCM (no `android/app/google-services.json`).

**Read this before trusting the WORKS count:** AI chat/twins/memory/summary and session recording now count as WORKS because the checker's secret check passes when the SSM parameter *exists*. `GEMINI_API_KEY`, `AGORA_CUSTOMER_ID` and `AGORA_CUSTOMER_SECRET` are still `NOT_SET`, so every call that needs them returns **503 "Gemini not configured" / "Agora cloud recording not configured"** (checked live). Reads such as chat history, memory and stored summaries work.

### Changes in this round
| Item | Result |
|---|---|
| Stray probe row in `torino-earnings` | Backed up to [pre-deploy/torino-earnings-stray-probe-row.json](pre-deploy/torino-earnings-stray-probe-row.json), then deleted (conditional on it having no earnings data). The table is back to 13 rows |
| `/dev` stage | Still on old deployment `wzljzr`. Every route has an authorizer, but `/{proxy+}` → `torino-api` (with its unguarded write handlers) uses AWS_IAM. Only IAM users in the Administrators/Developers groups can sign for it; there is no Cognito identity pool. **Throttled to 0** (rate 0, burst 0) and not deleted: an authenticated call now gets **429** |
| Secrets → SSM | `toriino-ai-chat/-twins/-memory/-summaries`, `toriino-transcribe-processor`, `toriino-agora-recording` and `torino-api` read `GEMINI_API_KEY` / `AGORA_CUSTOMER_ID` / `AGORA_CUSTOMER_SECRET` from `/torino/prod/` at runtime (5-min cache). `NOT_SET` → 503. Plain env copies removed. The 5 AI Lambdas were imported into the SAM stack with their own roles. Agora recording got its own role (`AgoraRecordingRole`) instead of the shared, over-privileged `toriino-lambda-role`. `torino-api` source is now in the repo (`aws-backend/lambda/torino-api/`). These two are deployed by `scripts/deploy-legacy-lambdas.mjs`, because their `AGORA_APP_CERTIFICATE` must stay an env var and must never be written into the template |
| Courses table | `torino-courses` (the 45 live courses) is the only courses table. `COURSES_TABLE` points at it explicitly; no data moved. Documented in `docs/ARCHITECTURE.md` |
| Paid courses | `POST /courses/{id}/enroll` → **402 "payment required"** for any course with price > 0 (checked live). Only the Stripe webhook enrolls in paid courses; free courses enroll directly (201) |
| File viewing | CloudFront distribution `d21264ndaif3rv.cloudfront.net` with Origin Access Control. The bucket policy (imported into the stack, then replaced; the old one is in `pre-deploy/`) lets only that distribution read `profiles/`, `avatars/`, `courses/thumbnails/` and `intro-videos/`, and denies non-TLS access. Checked live: avatar via CloudFront 200, direct S3 403, `lessons/` via CloudFront 403. Lesson videos and materials are served only by `GET /courses/{id}/lessons/{lessonId}/media`: 5-minute pre-signed GET after an owner, free-course or active-enrollment check, else 402 |
| Intro video | New profile field `introVideoUrl` (must be the caller's own CloudFront `intro-videos/` URL; mirrored onto the mentor record). The three upload screens now pick, upload via upload-url and save; the fake success toast is gone |
| Sessions test data | `verify-test-session-teacher-hosted` (test teacher) and `verify-test-session-student-booked` (test student with the test mentor) are kept in `torino-sessions`. Each test user sees exactly 1 session, their own |

Rollback points: Lambda versions published before this round (`toriino-ai-*` v1, `toriino-transcribe-processor` v1, `toriino-agora-recording` v1, `torino-api` v9).

---

## Re-verification after remediation, round 1 (2026-10-07, branch `fix/remediation-v1`)

`node scripts/verify-backend.mjs`, run at 2026-10-07T02:42Z against deployment `l0qw3k`. Full output: [verify-after-remediation.txt](verify-after-remediation.txt).

**Result: 15 WORKS · 7 BLOCKED · 5 BROKEN · 0 NOT DEPLOYED. Exit code 1.** (The 2026-10-06 baseline below was 7 WORKS · 16 BROKEN · 4 NOT DEPLOYED.)

Every remaining BROKEN comes from a checker expectation that no longer matches the agreed design. None of them is a live failure:
- **Table names (features 6, 8, 9, 24, 26).** The checker requires `torino-lessons`, `torino-enrollments`, `torino-notifications` and `torino-reviews`. By owner decision, the backend uses the existing `toriino-enrollments`, `toriino-reviews` and `toriino-notifications` tables (which hold the real data) and a new `toriino-lessons`, so no duplicate `torino-*` tables were created. The checker's table names still need updating to `toriino-*`.
- **Enroll write test (feature 9).** The checker enrolls in `verify-backend-test-course`, which doesn't exist. The courses Lambda now correctly answers **404 "Course not found"**. Before, the monolith answered 201 and saved nothing. The checker needs to create its own test course, or seed a hidden fixture.

Every BLOCKED is a missing third-party secret (all are SSM SecureStrings under `/torino/prod/`, set to `NOT_SET`): Stripe (10, 11), Agora recording customer ID/secret (17), Gemini (18–20) and Firebase `google-services.json` (25).

### What changed

| Area | Before (2026-10-06) | Now |
|---|---|---|
| Deployment | Microservices not deployed. Almost everything went through the `torino-api` monolith via `/{proxy+}` | SAM stack `torino-backend` (`aws-backend/template.yaml`, us-east-1) deploys 14 Lambdas built by `sam build`, plus their IAM roles and 5 new tables. `toriino-users`, `toriino-student-search` and `toriino-admin` were CloudFormation-imported, not re-created |
| Routes | Hand-made; `/auth/{proxy+}` and `/students/search` had no authorizer | `aws-backend/routes.json` is applied by `scripts/deploy-api-routes.mjs` (idempotent; a second run reports 0 changes). Cognito on everything except OPTIONS and `POST /stripe/webhook` |
| Catch-all `/{proxy+}` | → `torino-api`. Any method a resource didn't define fell through to the monolith's unguarded writes, e.g. `POST /earnings` let a user write their own earnings | MOCK **404 "Not found"** (Cognito). `torino-api` now serves only `POST /sessions/token` |
| `/users/profile`, `/students/search` | 502: the zip used backslash paths | 200. `sam build` packages `index.js` at the zip root |
| Sessions | Teacher saw all 49 sessions | Only the caller's sessions, and single-session reads and writes are limited to participants |
| Courses | No pagination, plain delete, enroll returned 201 without saving | `lastKey` pagination. Soft delete with a lesson cascade, blocked (409) while students are enrolled. Owner checks. Idempotent enroll into `toriino-enrollments` |
| Reviews | 201 without saving, no duplicate check | One review per reviewer per target (409). Course reviews require an enrollment |
| Notifications | Always empty, no mark-as-read | Reads `toriino-notifications`. `PATCH /notifications/{sortKey}/read` and `/read-all` |
| FCM token | Wrong field name, failed silently with 200 | Accepts `{token, platform}` (and legacy `fcmToken`), writes `toriino-devices` and mirrors the token onto the profile |
| Earnings | No `totalWithdrawn` / `availableBalance` | Both fields added. `POST /earnings/withdraw` can't exceed the balance (optimistic lock) |
| Uploads | `/upload-url` not deployed | `toriino-upload-url` serves `/upload-url` and the legacy `/courses/upload-url`; keys are scoped to the caller's sub |
| Payments / webhook | Monolith only. The client could set PaymentIntent metadata | Server-authoritative course and session payments. Webhook at `POST /stripe/webhook` (no authorizer): 400 on a bad signature, 503 "not configured" while the secret is `NOT_SET`. Secrets come from SSM with a 5-minute cache |
| Admin | Test admin not in `Admins`; table names hardcoded | `admin@torino.test` is in `Admins`. Table names come from env vars, Admins-group check, and Cognito failures are no longer swallowed |
| No fake success | Several writes returned 2xx after failing | Every rewritten handler returns 4xx/5xx with a message when nothing was saved |

### Verification table (2026-10-07)

| # | Feature | Serving Lambda | Verdict | Notes |
|---|---|---|---|---|
| 1 | Sign-up / login / OTP | Cognito | **WORKS** | |
| 2 | Role selection → set-role | toriino-auth | **WORKS** | Sets Cognito `custom:role` and the profile role. Admins can't be changed. A wrong method gets 405 |
| 3 | User profile | toriino-users | **WORKS** | 200 for student, teacher and mentor |
| 4 | Profile edit / change password / delete account | app + toriino-users | **WORKS** | Delete removes the Cognito user, then the profile |
| 5 | Course list + detail | toriino-courses | **WORKS** | Pagination is live |
| 6 | Lessons list / add lesson | toriino-courses | BROKEN (checker table name only) | `GET /courses/{id}/lessons` → 200 from `toriino-lessons` |
| 7 | Course upload URL | toriino-upload-url | **WORKS** | |
| 8 | Course delete cascade + enrollment guard | toriino-courses | BROKEN (checker table names only) | Guard is deployed |
| 9 | Enroll + My Courses | toriino-courses | BROKEN (checker table name + missing test course) | My Courses → 200 |
| 10 | Stripe payment intent | toriino-payments | **BLOCKED** (Stripe secret) | |
| 11 | Stripe webhook | toriino-stripe-webhook | **BLOCKED** (Stripe secrets) | Public route, bad signature → 503 "not configured" |
| 12 | General uploads / S3Service | toriino-upload-url | **WORKS** | App uploads all go through `S3Service` |
| 13 | Mentor list / detail | toriino-mentors | **WORKS** | |
| 14 | Mentor availability | toriino-mentors | **WORKS** | Screen reachable from the mentor drawer |
| 15 | Sessions list | toriino-sessions | **WORKS** | No foreign sessions for any role |
| 16 | Live-session Agora token | torino-api | **WORKS** | |
| 17 | Session recording | toriino-agora-recording | **BLOCKED** (Agora customer ID/secret) | |
| 18 | Transcript / summary | toriino-ai-* | **BLOCKED** (Gemini) | App records segments from the in-call chat/notes panel |
| 19 | AI Tutor chat | toriino-ai-chat | **BLOCKED** (Gemini) | |
| 20 | AI Twins / Memory | toriino-ai-twins/memory | **BLOCKED** (Gemini) | Note: no screen uses them |
| 21 | Wallet | toriino-wallet | **WORKS** | |
| 22 | Student search | toriino-student-search | **WORKS** | Cognito authorizer; mentors/teachers only |
| 23 | Earnings | toriino-earnings | **WORKS** | Returns `totalWithdrawn` and `availableBalance` |
| 24 | Notifications | toriino-notifications | BROKEN (checker table name only) | Mark-as-read is deployed |
| 25 | FCM token registration | toriino-register-device | **BLOCKED** (Firebase config) | Write test reads the token back |
| 26 | Reviews + one-per-student | toriino-reviews | BROKEN (checker table name only) | Guard is deployed; write test reads the review back |
| 27 | Admin panel | toriino-admin | **WORKS** | All 8 endpoints → 200 as admin; student → 403 |

### Still open
- **Uploaded files aren't publicly readable.** `torino-app-storage` has a public-read bucket policy, but Block Public Access is fully on, so `publicUrl`s won't load in the app. That needs a CloudFront distribution with origin access control (owner decision).
- **Paid courses can still be enrolled without paying** (`POST /courses/{id}/enroll` doesn't check `price`), the same behaviour as before. Once Stripe is configured, paid enrollment should come only from the webhook.
- **Refund access isn't decided:** whether a refunded student keeps course access is still marked `OWNER_DECISION` in the webhook.
- **Probe leftover:** an earnings probe during this work wrote a row `{userId, updatedAt}` for the test student to `torino-earnings`, through the monolith fall-through that is now closed. It's harmless (no `periodKey`, so it's ignored). Delete it if wanted; it was left because deletes were restricted.
- **The `dev` stage and the `torino-api` code** were left untouched, as instructed.

Pre-deploy safety: on-demand backups of all 20 `torino-*`/`toriino-*` tables (`pre-remediation-v1-*`, all AVAILABLE) and redacted Lambda configs are in [pre-deploy/](pre-deploy/). Rollback versions were published for `toriino-users` (v1), `toriino-student-search` (v1) and `toriino-admin` (v2).

---

## Baseline — 2026-10-06 (before remediation)

Read-only verification of every task marked done in `EXECUTION_PLAN.md` and every Lambda the Flutter app calls.

**Method**
- AWS account 888245942659, us-east-1, API Gateway `pq8cu94cfd`, stage `prod` (deployment `c3nssj`). Routes were taken from the deployed stage export, not just the resource tree.
- Deployed Lambda code was downloaded and read. Env vars were listed, with secret values masked.
- Live calls were made with the four `.env.test` users (student, teacher, mentor, admin) using `Authorization: Bearer <idToken>`, as the app does. Re-run them with `node scripts/verify-backend.mjs`.
- Only GETs were sent, plus `POST /sessions/token` (returns an Agora token and writes nothing). Writes such as payments, booking, reviews and chat-send were **not** called. Those verdicts come from the deployed code and env vars.
- Screen wiring was traced from `lib/repository` → viewmodel → `lib/view`.

**Overall:** 27 features checked. 7 work, 16 are broken and 4 are not deployed. None of the microservice Lambdas in `aws-backend/lambda/` (courses, sessions, payments, reviews, notifications, earnings, mentors, stripe-webhook, upload-url, register-device, auth) are deployed. Most traffic still goes through the old `torino-api` Lambda via `/{proxy+}`. That Lambda has `torino-*` table names written into its code, and several of those tables don't exist.

## Verification table

| Feature (task) | Lambda (deployed) | Route on /prod | Tables | Authorizer | Live call result | Verdict |
|---|---|---|---|---|---|---|
| Sign-up / login / OTP (P3-5, P3-6) | none (app talks to Cognito directly) | — | — | — | All 4 test users log in. `custom:role` is set correctly | **WORKS** |
| Role selection → set-role (P3-3) | `auth` not deployed; `/auth/{proxy+}` goes to `torino-api`, which has no auth code | POST /auth/set-role | — | **NONE** | GET → 404 "Route not found" | **NOT DEPLOYED** |
| User profile (all 3 home screens, profile screen) | toriino-users | GET/PUT /users/profile | torino-users ✓ | Cognito ✓ | **502** for student, teacher and mentor. Logs show `Runtime.ImportModuleError`: the zip contains a file literally named `users\index.js`, so `index.handler` can't load | **BROKEN** |
| Profile edit / change password / delete account | — | — | — | — | Save just closes the screen. Change password shows a hardcoded success toast | **BROKEN** (no API call) |
| Course list + detail (P8-6) | torino-api | GET /courses, /courses/{id} | torino-courses ✓ | Cognito ✓ | 200, 45 courses. No `lastKey`, so pagination isn't live | **WORKS** (pagination not deployed) |
| Lessons list / add lesson (P8-2, P6-1) | torino-api | GET/POST /courses/{id}/lessons | torino-lessons ✗ | Cognito ✓ | **500** "Requested resource not found" | **BROKEN** |
| Course upload URL (P6-1) | torino-api | GET /courses/upload-url | S3 | Cognito ✓ | 200, returns a signed upload URL | **WORKS** |
| Course delete cascade + enrollment guard (P6-3) | `courses` not deployed; torino-api does a plain delete | DELETE /courses/{id} | — | Cognito ✓ | Not called (would delete data). Deployed code has no guard and no lesson cascade | **NOT DEPLOYED** |
| Enroll + My Courses (P5-1) | torino-api | POST /courses/{id}/enroll, GET /courses/my-courses | torino-enrollments ✗ | Cognito ✓ | My Courses: 200, always empty. Enroll ignores the failed write and still returns 201 | **BROKEN** (reports success but saves nothing) |
| Stripe payment intent: courses, sessions, subscriptions (P5-1/2/3) | `payments` not deployed; torino-api handles it | POST /payments/create-intent | — | Cognito ✓ | **500** "Stripe not configured" (`STRIPE_SECRET_KEY` is empty) | **BROKEN** |
| Stripe webhook (P1-3) | `stripe-webhook` not deployed | none | toriino-stripe-events ✗ | — | 404 | **NOT DEPLOYED** |
| General uploads / S3Service (P2-2) | `upload-url` not deployed | none | — | — | 404. `S3Service` is never called in the app. Public-access block on the bucket is ON ✓ | **NOT DEPLOYED** |
| Mentor list / detail | torino-api | GET /mentors, /mentors/{id} | torino-mentors ✓ | Cognito ✓ | 200, 9 mentors. The test mentor has no mentor record (404) | **WORKS** |
| Mentor availability (P7-1) | torino-api | GET /mentors/{id}/availability, PUT /mentors/availability | torino-mentors ✓ | Cognito ✓ | GET 200. But `MentorAvailability` is never opened from anywhere in the app | **BROKEN** (screen can't be reached) |
| Sessions list (P7-2) | torino-api | GET /sessions?role= | torino-sessions ✓ | Cognito ✓ | Student 0, mentor 0, **teacher 49 = every session**. The code filters only for mentor and student, so other users' sessions are exposed | **BROKEN** (data leak) |
| Live-session Agora token | torino-api | POST /sessions/token | — | Cognito ✓ | 200, token returned | **WORKS** |
| Session recording | toriino-agora-recording | /sessions/{id}/recording/* | toriino-recordings ✓ | Cognito ✓ | GET 404 (no recording, expected). `AGORA_CUSTOMER_ID` / `AGORA_CUSTOMER_SECRET` are empty, so start will fail | **BROKEN** (config) |
| Transcript / summary | toriino-ai-transcripts, toriino-ai-summaries | /sessions/{id}/transcript, /summary | ✓ ✓ | Cognito ✓ | GET 200 on seeded data. `GEMINI_API_KEY` is empty. The summary screen never opens because nothing ever records a transcript, so `hasTranscript` is never true | **BROKEN** |
| AI Tutor chat (P2-1) | toriino-ai-chat | GET/POST /ai/chat/{userId} | toriino-ai-chat ✓ | Cognito ✓ | GET 200. Reading another user's chat → 403 ✓. `GEMINI_API_KEY` is empty, so sending a message can't get a reply | **BROKEN** (config) |
| AI Twins / Memory | toriino-ai-twins, toriino-ai-memory | /ai/twins/*, /ai/memory/* | ✓ ✓ | Cognito ✓ | 404 / 200. No screen calls them, and the Gemini key is empty | **WORKS** (API only, unused, can't generate) |
| Wallet (P5-3) | toriino-wallet | GET /wallet, POST /wallet/deduct | toriino-wallet ✓, toriino-wallet-events ✓ | Cognito ✓ | 200, balance 70 (student) / 0 (mentor). The app never reads `/wallet`; it uses earnings as the balance | **WORKS** (but the app doesn't read the balance from it) |
| Student search for 1-on-1 sessions (P7-2) | toriino-student-search | GET /students/search | toriino-users ✗ | **NONE** | **502** `ImportModuleError` (same backslash zip problem) | **BROKEN** |
| Earnings (P5-4) | torino-api | GET /earnings, /earnings/history | torino-earnings ✓ | Cognito ✓ | 200, all zeros. No `totalWithdrawn` or `availableBalance` field, so "remaining balance" and the booking wallet check get null | **BROKEN** (fields missing) |
| Notifications (P8-4) | torino-api | GET /notifications, PATCH /notifications/{sk}/read | torino-notifications ✗ | Cognito ✓ | 200 and always empty (the failed read is ignored). There is no handler for mark-as-read | **BROKEN** |
| FCM token registration (P9-1) | `register-device` not deployed; torino-api handles it | POST /notifications/fcm-token | toriino-devices ✗ | Cognito ✓ | Not called. App sends `{token}`, the code reads `body.fcmToken`, the write fails silently and it still returns 200 | **BROKEN** |
| Reviews + one-per-student rule (P2-5) | `reviews` not deployed; torino-api handles it | GET /reviews/{id}, POST /reviews | torino-reviews ✗ | Cognito ✓ | GET 200 and always empty. POST returns 201 without saving anything, and there's no duplicate check | **BROKEN** (reports success but saves nothing) |
| Admin panel (P10-7, P1-2) | toriino-admin | /admin/* | Table names written into the code; the env vars are ignored | Cognito ✓ + `Admins` group check | **403** on all 8 endpoints: `admin@torino.test` isn't in the `Admins` Cognito group | **BROKEN** for the test admin |

## BROKEN / NOT DEPLOYED

### NOT DEPLOYED
1. **`/auth/set-role`**: no auth Lambda. `/auth/{proxy+}` has no authorizer and goes to `torino-api`, which returns 404. Role selection can't save the role in Cognito.
2. **`stripe-webhook` Lambda and the `toriino-stripe-events` table**: P1-3 exists only in the repo.
3. **`upload-url` Lambda**: P2-2. `GET /upload-url` returns 404, and `S3Service` is never called anyway.
4. **The `courses`, `sessions`, `payments`, `reviews`, `notifications`, `earnings`, `mentors` and `register-device` Lambdas in `aws-backend/lambda/`**: none are deployed. So P6-3 (delete guard and cascade), P8-6 (pagination), P2-5 (review guard), the P10-2 structured logs and the P5-4 server-calculated balance aren't live.
5. **Missing tables**: `torino-lessons`, `torino-enrollments`, `torino-notifications`, `torino-reviews`, `torino-withdrawals`, `toriino-devices`, `toriino-stripe-events`. Also missing: the `toriino-users/courses/sessions/mentors/earnings` tables that the env vars on `toriino-admin`, `toriino-student-search` and `torino-api` point to.

### BROKEN
1. **`/users/profile` returns 502 for every role.** The `toriino-users` zip was built on Windows with backslash paths, so Lambda can't find the code. Every home screen and profile screen depends on this call.
2. **`/students/search` returns 502** for the same zip reason. It also has **no authorizer** and points at `toriino-users`, which doesn't exist.
3. **Sessions leak:** `GET /sessions?role=teacher`, or any request without a role, returns all 49 sessions in the table.
4. **Calls that report success but save nothing:** course enroll (201), review submit (201) and FCM token (200). The write fails silently because the table is missing or the field name is wrong, and the call still returns success.
5. **Lessons:** listing (500) and add-lesson after publishing fail because `torino-lessons` doesn't exist.
6. **Notifications** always come back empty, and mark-as-read has no handler.
7. **Payments:** `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` are empty, so every course, session and subscription payment returns 500.
8. **AI:** `GEMINI_API_KEY` is empty on all six AI Lambdas (`toriino-ai-chat`, `toriino-ai-twins`, `toriino-ai-memory`, `toriino-ai-summaries`, `toriino-transcribe-processor`) and on `torino-api`. The tutor can't reply and summaries can't be generated.
9. **Recording:** the Agora customer ID and secret are empty, so recording start/stop will fail.
10. **Earnings** has no `totalWithdrawn` or `availableBalance` field, so the balance and wallet-coverage calculations get null.
11. **Admin:** `admin@torino.test` isn't in the `Admins` group, so all admin calls return 403. `toriino-admin` also ignores its env vars.
12. **Screens that can't be reached or don't do anything:**
    - The mentor availability screen is never opened from anywhere.
    - The session summary screen never opens.
    - Profile edit, change password and delete account don't call any API.
    - `S3Service` and the AI Twin / memory code in the app are never used.
13. **Junk data:** `torino-users` contains a record with `userId = "role"`. The likely cause is that `PUT /users/role` reaches `torino-api`'s generic update-user-by-id code.

### Also noted
- `EXECUTION_PLAN.md` has a duplicate block of unchecked P3-2…P3-6 lines under Phase 3, after the same tasks marked done.
- The `dev` stage still exists (P1-5 owner item).

### Verified OK
- S3 `torino-app-storage`: public-access block fully on (all 4 settings).
- CloudFormation stack `torino-alarms` is `CREATE_COMPLETE` (3 alarms). The payments and webhook alarms watch Lambdas that aren't deployed.
- The `toriino-transcribe-processor` S3 `ObjectCreated` trigger is wired up.
- `/ai/chat/{userId}` refuses to return another user's chat (403).
