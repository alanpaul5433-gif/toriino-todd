# Owner Decisions Required
**Generated:** 2026-10-04  
**Project:** Torino Todd  
**Context:** Phase 12 autonomous remediation. All items below genuinely require owner input, credentials, or a business decision. Everything else has been implemented autonomously.

---

## A. BLOCKING — Requires Owner Action

---

### OWN-01 — Rotate Gemini API Key (SECURITY — HIGH PRIORITY)
**Decision/input required:** Revoke the old key; generate a new one.  
**Why:** The previous Gemini API key was committed to git history. Anyone with access to the repository can extract it.  
**Steps:**
1. Go to https://aistudio.google.com/app/apikey
2. Revoke the key that was in `lib/config/app_config.dart` (see git history)
3. Generate a new key
4. Set it as `GEMINI_API_KEY` environment variable on the `ai-chat` Lambda in AWS Console
5. Pass `--dart-define=GEMINI_API_KEY=<newkey>` when building release APK  
**Files affected:** `lib/config/app_config.dart` (already uses `String.fromEnvironment`), `aws-backend/lambda/ai-chat/index.js`  
**Current state:** Code is clean — `String.fromEnvironment('GEMINI_API_KEY', defaultValue: '')` — but old key must be revoked.  
**Claude can continue:** Yes. GeminiService has been replaced with a Lambda-proxy architecture (see Phase 12 changes). The Lambda needs the new key set.

---

### OWN-02 — Firebase / google-services.json
**Decision/input required:** Download `google-services.json` from Firebase Console and place at `android/app/google-services.json`.  
**Why:** FCM push notifications, Crashlytics, and Firebase Analytics all require this file. The Gradle build fails without it.  
**Steps:**
1. Go to https://console.firebase.google.com → your project
2. Project Settings → Your apps → Android app (`com.torino.todd`)
3. Download `google-services.json`
4. Place at `android/app/google-services.json`
5. Add `android/app/google-services.json` to `.gitignore`  
**Files affected:** `android/app/google-services.json` (missing), `android/app/build.gradle` (plugin already wired)  
**Current state:** Gradle plugin is configured. File is missing — build will fail.  
**Claude can continue:** Yes. All Flutter FCM code is implemented.

---

### OWN-03 — Stripe Secret Key + API Gateway Route
**Decision/input required:** Two sub-items:  
1. Set `STRIPE_SECRET_KEY` as Lambda environment variable on the `payments` Lambda (AWS Console → Lambda → payments → Configuration → Environment Variables)
2. Ensure `POST /payments/create-intent` is wired in API Gateway `/prod` stage and deployed  
**Why:** Without the secret key the Lambda cannot create PaymentIntents. Without the route, the Flutter PaymentSheet cannot initialize.  
**Where used:** `aws-backend/lambda/payments/index.js` reads `process.env.STRIPE_SECRET_KEY`  
**Test key format:** `sk_test_...` for testing; `sk_live_...` for production  
**Claude can continue:** Yes. All payment code + metadata is implemented.

---

### OWN-04 — Stripe Webhook Secret
**Decision/input required:** Set `STRIPE_WEBHOOK_SECRET` as Lambda environment variable on the `stripe-webhook` Lambda.  
**Why:** The webhook Lambda uses `stripe.webhooks.constructEvent(rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET)` to verify Stripe's signature. Without this env var, all webhook events are rejected.  
**Where used:** `aws-backend/lambda/stripe-webhook/index.js`  
**How to get:** Stripe Dashboard → Webhooks → your endpoint → Signing secret  
**Claude can continue:** Yes.

---

### OWN-05 — Stripe Connect (Educator Withdrawals)
**Decision/input required:** Business decision: when to implement real payouts, and which payout model to use.  
**Options:**
- **Stripe Connect Express** — educators onboard via Stripe, receive direct deposits. Requires `STRIPE_SECRET_KEY` with Connect permissions.
- **Manual bank transfer** — platform pays out manually based on earnings ledger. No code change needed.
- **Delay** — launch beta without withdrawals (current state — "Coming Soon" button).  
**Current state:** Withdrawal button is disabled with "Bank Payouts Coming Soon" message. Earnings ledger is implemented and correct (after Phase 12 fixes). No money is lost — it is tracked.  
**Claude can continue:** Yes. Earnings accumulation is now fixed (P0-1). Payout architecture is a separate decision.

---

### OWN-06 — SNS Platform Application ARN (Push Notifications)
**Decision/input required:** Create an SNS Platform Application for FCM and provide the ARN.  
**Why:** The sessions Lambda's `sendPush()` function now correctly queries device tokens and attempts SNS delivery. But SNS requires a Platform Application ARN for FCM.  
**Steps:**
1. AWS Console → SNS → Mobile → Push notifications → Create platform application
2. Platform: Firebase Cloud Messaging (FCM)
3. Provide the FCM Server Key (from Firebase Console → Project Settings → Cloud Messaging)
4. Note the Platform Application ARN
5. Set `SNS_PLATFORM_APP_ARN` environment variable on the `sessions` Lambda  
**Current state:** Lambda queries token correctly and logs a warning if `SNS_PLATFORM_APP_ARN` is not set — will not crash.  
**Claude can continue:** Yes.

---

### OWN-07 — Agora App Certificate (Live Sessions)
**Decision/input required:** Set `AGORA_APP_CERTIFICATE` on the `sessions` Lambda.  
**Why:** Server-side Agora RTC token generation requires the App Certificate (not the App ID, which is public).  
**Where:** AWS Console → Lambda → sessions → Environment Variables → `AGORA_APP_CERTIFICATE`  
**Current state:** Lambda logs an error and returns 500 if certificate is missing.  
**Claude can continue:** Yes.

---

### OWN-08 — Agora Cloud Recording Credentials
**Decision/input required:** Provide `AGORA_CUSTOMER_ID` and `AGORA_CUSTOMER_SECRET` for the `agora-recording` Lambda.  
**Where to get:** https://console.agora.io → RESTful API  
**Current state:** Recording Lambda exists. Returns 500 if credentials not set.

---

### OWN-09 — AWS S3 Bucket: Block Public Access
**Decision/input required:** In AWS Console, enable "Block all public access" on the `torino-app-storage` S3 bucket.  
**Why:** Even though the Flutter app now uses pre-signed PUT URLs (no `x-amz-acl: public-read`), the bucket itself should have public access blocked at the bucket level as a defense-in-depth measure.  
**Steps:** S3 Console → `torino-app-storage` → Permissions → Block public access → Enable all 4 toggles.  
**Claude can continue:** Yes. Flutter upload code is already correct.

---

### OWN-10 — CloudWatch Alarms Deployment
**Decision/input required:** Deploy the CloudFormation template.  
**Command:**
```bash
aws cloudformation deploy \
  --template-file aws-backend/cloudwatch-alarms.json \
  --stack-name torino-alarms \
  --capabilities CAPABILITY_IAM
```
**Why:** The template creates SNS alerts for Lambda error rates. Cannot be deployed without AWS CLI credentials.

---

### OWN-11 — applicationId Change Confirmation
**Decision/input required:** Confirm the app has NEVER been published to Google Play under `torino.torino`.  
**Why:** The `applicationId` was changed from `torino.torino` to `com.torino.todd` in Phase 10. If any APK was ever submitted to the Play Store under the old ID, that ID cannot be changed on the existing listing — a new app entry would be required.  
**Current state:** `android/app/build.gradle` uses `com.torino.todd`.

---

### OWN-12 — Subscription Pricing / Model Clarification
**Decision/input required:** Is the mentor/teacher subscription a one-time platform fee, or a recurring monthly subscription?  
**Why:** The current implementation charges a one-time PaymentIntent. The UI implies recurring billing. Stripe Subscription objects are NOT created. This must be clarified to users before beta.  
**Options:**
- Confirm it is a one-time fee and update the UI copy
- Implement Stripe Subscriptions (requires Stripe Products/Prices to be created in Stripe Dashboard)  
**Stripe Products needed:** Monthly ($9.99), Quarterly ($49.99), Annual ($99.99)  
**Claude can continue:** Yes — UI will show accurate one-time billing copy until owner decides.

---

### OWN-13 — Privacy Policy / Terms of Service
**Decision/input required:** Legal review of data collection, storage, and processing policies.  
**Why:** The app collects: names, emails, payment data (via Stripe), session recordings, AI conversation history, FCM tokens, and device information.  
**Minimum required:**
- Privacy policy URL
- Terms of service URL
- GDPR data processing agreement (if EU users)
- Age verification / COPPA determination (are users under 13 possible?)

---

### OWN-14 — Production Domain
**Decision/input required:** Final production domain (e.g., `app.torinodd.com`).  
**Why:** Deep links, Stripe redirect URLs, and Universal Links all require a real domain.  
**Current state:** API Gateway URL is used directly. No custom domain.

---

### OWN-15 — Admin Panel Authentication
**Decision/input required:** Verify the admin panel (`admin-panel/` Next.js app) requires a Cognito `custom:role = 'admin'` claim before allowing access.  
**Why:** The admin Lambda (`aws-backend/lambda/admin/index.js`) exposes full DynamoDB table scans. If any authenticated user can reach admin APIs, all user data is exposed.  
**Action required:** Review the Next.js admin panel source code and confirm the authorization check.

---

## B. NON-BLOCKING — Already Implemented Autonomously (Phase 12)

The following were implemented without owner input:

| Item | Fix | Files Changed |
|------|-----|---------------|
| P0-1 Payment metadata | Added courseId/sessionId/mentorId/teacherId to PaymentIntent | `stripe_service.dart`, `payments/index.js` |
| P0-3 GeminiService key in binary | Replaced direct SDK calls with Lambda HTTP proxy | `gemini_service.dart` → `lambda_ai_service.dart` |
| P1-1 Mentor rating bug | Fixed both ternary branches | `mentor_home_view.dart:170` |
| P1-2 Role from JWT | Read JWT claim on splash, overwrite SharedPreferences | `splash_view.dart` |
| P1-4 Review Limit bug | Removed Limit:1 from duplicate-check query | `reviews/index.js` |
| P1-6 sendPush key mismatch | Fixed to QueryCommand by userId | `sessions/index.js` |
| P2-1 Price validation | Added server-side amount validation against mentor rate | `payments/index.js` |
| P2-4 FCM foreground banner | Implemented in-app notification overlay | `fcm_service.dart` |
| Dead code removal | Deleted mock_data.dart, mock_repo.dart | deleted |
