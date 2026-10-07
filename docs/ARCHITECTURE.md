# Architecture

## Overview

Torino Todd is a Flutter Android app (GetX, FlutterSecureStorage) backed by a serverless AWS microservice.

## Flutter app layers

| Layer | Path | Responsibility |
|-------|------|----------------|
| Views | `lib/view/` | UI widgets, no business logic |
| ViewModels | `lib/viewmodel/` | GetX controllers, state management |
| Repositories | `lib/repository/` | API call wrappers |
| Services | `lib/services/` | Auth, S3, FCM, Stripe, Analytics |
| Models | `lib/model/` | JSON serialization / deserialization |
| Network | `lib/data/network/` | HTTP client, 401 refresh interceptor |

## AWS backend

Region `us-east-1`, account 888245942659. Deployed with `npm run deploy:backend` (from `aws-backend/`):
SSM placeholders → Lambda import → `sam build` / `sam deploy` (stack `torino-backend`, `aws-backend/template.yaml`)
→ `scripts/deploy-legacy-lambdas.mjs` → `scripts/deploy-api-routes.mjs` (routes from `aws-backend/routes.json`).

- **API Gateway** `pq8cu94cfd`, stage `prod`. Every route has the Cognito authorizer except CORS
  preflights and `POST /stripe/webhook` (Stripe-Signature verified instead). The `/{proxy+}`
  catch-all is a MOCK 404, so undefined paths/methods never reach the old monolith.
  The `dev` stage is throttled to 0 requests (kept, not deleted).
- **Lambdas** — one per service (users, auth, student-search, courses, sessions, mentors, reviews,
  notifications, register-device, earnings, upload-url, payments, stripe-webhook, admin, wallet,
  ai-*, transcribe-processor, agora-recording). `torino-api` (the old monolith, source in
  `aws-backend/lambda/torino-api/`) only serves `POST /sessions/token` (Agora RTC token).
- **Cognito** — user pool `us-east-1_CAiea51iC`, `custom:role` claim; admins = `Admins` group.
- **Secrets** — SSM SecureStrings under `/torino/prod/` (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`,
  `GEMINI_API_KEY`, `AGORA_CUSTOMER_ID`, `AGORA_CUSTOMER_SECRET`, `AGORA_APP_CERTIFICATE`), read at runtime with a 5-minute
  cache by only the Lambdas that need them. The value `NOT_SET` means "not configured" → HTTP 503.

### DynamoDB tables

Table names reach Lambdas only through env vars set in `template.yaml`. Live data predates the
`toriino-` naming, so names are mixed:

| Data | Table | Notes |
|---|---|---|
| Users | `torino-users` | PK `userId` |
| **Courses** | **`torino-courses`** | PK `courseId` — see below |
| Lessons | `toriino-lessons` | PK `courseId`, SK `lessonId` (created by the stack) |
| Enrollments | `toriino-enrollments` | PK `enrollmentId` = `enr_<courseId>_<studentId>` for new rows |
| Sessions | `torino-sessions` | PK `sessionId` |
| Mentors | `torino-mentors` | PK `mentorId` |
| Earnings (monthly aggregate) | `torino-earnings` | PK `userId` |
| Earnings ledger (Stripe) | `toriino-earning-entries` | PK `earningId`, GSI `userId-index` |
| Withdrawals | `toriino-withdrawals` | PK `userId`, SK `withdrawalId` |
| Reviews | `toriino-reviews` | PK `targetId`, SK `reviewId` |
| Notifications | `toriino-notifications` | PK `userId`, SK `sortKey` |
| Devices (FCM) | `toriino-devices` | PK `userId`, SK `token` |
| Stripe events (idempotency) | `toriino-stripe-events` | PK `eventId`, TTL `ttl` |

**Courses table decision (2026-10-07).** `torino-courses` is the only courses table that exists and
holds the 45 live courses (5 free, 40 paid). There is no `toriino-courses` table, and none is created:
no data is moved. `COURSES_TABLE` is set explicitly to `torino-courses` (template parameter
`CoursesTable`) for every Lambda that reads courses — courses, payments, admin. If the data is ever
migrated, change that one parameter and redeploy.

### Payments and enrollment

- **Catalog**: `GET /courses` hides `deleted` and `draft` courses; owners see their drafts in `GET /courses/my-created`.
- **Free course** (`price` 0): `POST /courses/{id}/enroll` enrolls directly (201).
- **Paid course**: `POST /courses/{id}/enroll` returns **402 "payment required"**. The app creates a
  PaymentIntent (`POST /payments/create-intent`, price read server-side) and only the Stripe webhook
  (`payment_intent.succeeded`) writes the enrollment. A refund marks it `refunded`.
- **Completion**: `POST /courses/{id}/complete` marks the caller's active enrollment `completed` (no certificates).
- **Test fixture**: draft course `verify-test-course-paid` + lesson `verify-test-lesson`
  (`scripts/seed-verify-test-lesson.mjs`) for the paid lesson-media check. Delete before beta.

### Money (server-only; the app never calculates money)

- **One fee value:** SSM String `/torino/prod/PLATFORM_FEE_PERCENT` (default **25** until the client
  confirms). Every Lambda that prices anything reads it, with a 5-minute cache. If it is missing or invalid,
  payments return **503 "Platform fee not configured"**. Course and session responses then omit `pricing`
  rather than guess.
- **Split:** the student pays the listed `price`. In integer cents, `platformFee = round(price × % / 100)` and
  `teacherShare = price − platformFee`, so the parts always add up.
- **Where the numbers come from:**
  - Course and session responses carry `pricing { currency, price, platformFeePercent, platformFee, teacherShare }`.
  - `GET /payments/quote?courseId= | sessionId= | mentorId=&duration=` adds `walletBalance`, `walletApplied`
    and `amountDue`.
- **Fixed at purchase:** fee and share are written into the PaymentIntent metadata (`platformFeeCents`,
  `teacherShareCents`). The Stripe webhook credits exactly that share, so a later fee change never alters a
  payment already made.
- **Session price:** a student booking is priced by the server as mentor `hourlyRate × duration / 60`; any
  client price is ignored. Only the host can change a price, and never after payment.
- **Wallet:** all or nothing. If the wallet covers the full session price, `POST /payments/create-intent`
  (`session_booking`) pays from it in **one DynamoDB transaction**:
  - wallet debit (conditional on the balance)
  - wallet event
  - session confirmed and paid
  - pending mentor earning

  Otherwise the full price goes to Stripe and the wallet is untouched. There are no partial splits, so
  nothing is ever reserved for an abandoned card payment.

### Subscriptions and premium

- **Plans** live in SSM String `/torino/prod/SUBSCRIPTION_PLANS` (JSON). Each plan has `planId`, `name`,
  `audience` (student / teacher / mentor), `months`, `price`, `currency`, `stripePriceId`, `active`.
- **Offered plans:** a plan is offered only if `active` is true, `stripePriceId` is a real Price ID (not `NOT_SET`)
  and the price is valid. `GET /subscriptions/plans` returns only offered plans for the caller's role (or `comingSoon`).
  It includes `savings`, computed from real prices against the same audience's monthly plan, and only when there is
  a real saving. The seeded plans are all inactive ($9.99 / $49.99 / $99.99 per audience, unconfirmed).
- **Checkout:** `POST /subscriptions { planId }` creates the Stripe subscription server-side (`default_incomplete`)
  and returns the payment client secret. The app never sends an amount.
- **Activation is webhook-only:** `customer.subscription.created/updated` and `invoice.paid` (re-read from Stripe)
  write `toriino-subscriptions` (PK `userId`). `customer.subscription.deleted` and `invoice.payment_failed`
  deactivate it.
  - Stale events are ignored (`lastEventAt`).
  - An event about another, inactive subscription can't turn off a live plan.
  - `premium` = status active or trialing and the period has not ended.
- **Gating:** SSM String `/torino/prod/PREMIUM_FEATURES` is a JSON list of feature keys (`ai_chat`, `ai_twins`,
  `ai_recommendations`, `ai_summary`). It is empty for now. When a key is listed, that action returns
  **402 "premium required"** without an active record. Changes take effect within 5 minutes, with no redeploy.

### Files (S3 `torino-app-storage`, private, Block Public Access on)

- Uploads: `GET /upload-url` returns a pre-signed PUT scoped to `<folder>/<cognito sub>/…`.
- **Public media** — `profiles/`, `avatars/` (legacy), `courses/thumbnails/`, `intro-videos/`: served by the
  CloudFront distribution `MediaDistribution` through Origin Access Control. The bucket policy lets
  only that distribution read only those prefixes; `publicUrl` returned by uploads is a CloudFront URL.
- **Private media** — `lessons/` (videos) and `course-materials/`: never public, never behind CloudFront.
  `GET /courses/{id}/lessons/{lessonId}/media` returns 5-minute pre-signed GET URLs after checking the
  caller owns the course, or it is free, or they have an active (not refunded) enrollment; otherwise 402.

### Viewing other users (`GET /users/{id}`)

- **Teacher / mentor**: public profile for any signed-in user. Fields: name, avatar, bio, title, expertise,
  specialties, language, intro video, rating, hourly rate, plus published courses. Drafts and deleted courses are hidden.
- **Student**: only a teacher or mentor who **shares a session** with the student, or whose course the student is
  **actively enrolled** in (refunded and cancelled enrollments don't count), can view them. They get name, avatar,
  bio and only the courses and sessions they share. Anyone else gets 403.
- Responses are built from explicit field whitelists. Email, phone, wallet, earnings and tokens are never returned.
- Course responses include `teacherName`, the owner's display name only.

## Auth flow

1. Sign up / OTP / login / password reset → straight from the app to Cognito (no API call).
2. Role selection → `POST /auth/set-role` (sets `custom:role` and the profile role), then token refresh.
3. Every request → `AuthInterceptor.getAuthHeaders()` → auto-refresh 60s before expiry.
4. 401 → single-flight refresh → retry; second 401 → sign out.

## Security model

- App-side keys (Agora app ID, Stripe publishable key) via `--dart-define`; server secrets only in SSM.
- Every write returns 4xx/5xx with a message when nothing was saved (no fake 2xx).
- Users only ever see their own sessions, enrollments, earnings and notifications.
- Bank data: not collected; withdrawals are requests (`POST /earnings/withdraw`), capped at the available balance.

## Admin panel

The admin panel is a **separate repository** — it does not live inside this Flutter project.
To unblock admin workflows, the owner must:

1. Create a test admin Cognito user (e.g. via the AWS Console or `aws cognito-idp admin-create-user`).
2. Set `custom:role` to `admin` on that user and add it to the `Admins` Cognito group (the admin
   Lambda checks the group).
3. Point the admin panel at the same API Gateway base URL
   (`https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod`).
