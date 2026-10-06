# Phase 13 Implementation Report

## 1. P0 Course-Payment Fix

**What was broken:**
`lib/services/stripe_service.dart` → `purchaseCourse()` sent `teacherId: ''` and no `studentId` in the Stripe PaymentIntent metadata. The webhook's enrollment branch requires both `courseId && studentId`; the teacher earnings branch requires `teacherId`. As a result, payments succeeded in Stripe but students were never enrolled via the webhook and teachers were never credited.

Two call sites passed a `price` from the client that the Lambda trusted without server validation, allowing price manipulation.

**What was changed:**

| File | Change |
|---|---|
| `aws-backend/lambda/payments/index.js` | New `course_purchase` code path that fetches course from DynamoDB and uses server-authoritative price/teacherId |
| `lib/services/stripe_service.dart` | `purchaseCourse()` no longer accepts `price`; sends only `courseId` + display title |
| `lib/view/users/student_view/course_view.dart` | Removed `price` from `purchaseCourse()` call |
| `lib/view/users/student_view/home_view.dart` | Removed `price` from `purchaseCourse()` call |

**Execution path (new):**
1. Flutter calls `/payments/create-intent` with `{ type: 'course_purchase', courseId, description }`
2. Lambda reads `studentId` from `event.requestContext.authorizer.claims.sub` (Cognito — not client-supplied)
3. Lambda fetches course from `toriino-courses` DynamoDB table
4. Lambda creates PaymentIntent with `metadata: { type, courseId, studentId, teacherId, amount }` — all server-authoritative
5. Flutter receives `clientSecret` and shows PaymentSheet (amount is embedded in the secret from Stripe)
6. On payment success, Stripe fires `payment_intent.succeeded` webhook
7. Webhook enrolls student and credits teacher earnings

---

## 2. Student Identity Handling

`studentId` is now obtained exclusively from `event.requestContext.authorizer.claims.sub` (the Cognito-validated JWT claim injected by API Gateway). It is never read from the request body and never falls back to an unverified manual JWT decode for the payments endpoint.

---

## 3. Teacher Attribution

`teacherId` is now read from the DynamoDB course record (`toriino-courses`), fetched server-side by the payments Lambda after the student provides `courseId`. The client cannot supply or override `teacherId`.

---

## 4. Enrollment Processing

The webhook writes enrollments with keys matching the `toriino-enrollments` table schema used by the courses Lambda:
- Partition key: `studentId`
- Sort key: `courseId`

Idempotency: `ConditionExpression: 'attribute_not_exists(courseId)'` on the PutCommand prevents duplicate enrollments. A `ConditionalCheckFailedException` is caught and treated as a no-op (already enrolled).

Fields written: `studentId`, `courseId`, `paymentIntentId`, `status: 'active'`, `enrolledAt`, `progress: 0`.

---

## 5. Earnings Processing

Teacher earnings are now written with a **deterministic** `earningId`:
- Course sale: `earningId = 'course_' + paymentIntent.id`
- Session:     `earningId = 'session_' + paymentIntent.id`

`ConditionExpression: 'attribute_not_exists(earningId)'` prevents double-crediting. A `ConditionalCheckFailedException` is a no-op.

Teacher cut: 80% of payment amount. Mentor cut: 85%.

---

## 6. Webhook Idempotency

Three layers:
1. **Event-level**: `markProcessed(eventId)` writes to `toriino-stripe-events` with `ConditionExpression: 'attribute_not_exists(eventId)'`. A duplicate event returns `{ received: true, duplicate: true }` immediately without any DynamoDB writes.
2. **Enrollment-level**: conditional PutCommand on (studentId, courseId) composite key.
3. **Earnings-level**: conditional PutCommand on deterministic `earningId`.

This covers both replay attacks and Stripe's at-least-once delivery guarantee.

---

## 7. Payment Authorization Fix

**Removed:** The `getUserId()` function in `aws-backend/lambda/payments/index.js` previously fell back to manually decoding an unverified JWT when the API Gateway authorizer context was absent. This allowed callers to claim any Cognito sub by constructing a JWT payload without valid signature.

**Replaced with:**
```javascript
const claims = event.requestContext?.authorizer?.claims;
if (!claims || !claims.sub) {
  return res(401, { error: 'Unauthorized: missing authorizer context' });
}
const userId = claims.sub;
```

**Note on other Lambdas:** The same unverified JWT fallback pattern exists in 7 other Lambda files (notifications/register-device, upload-url, ai-chat, ai-twins, ai-summaries, ai-memory, ai-transcripts). These are outside the scope of Task 2 but should be addressed in a follow-up phase.

---

## 8. Refund Implementation

Added handler for `charge.refunded` in `aws-backend/lambda/stripe-webhook/index.js`.

**Events handled:**
- Retrieves the original PaymentIntent from Stripe API to get metadata (type, courseId/sessionId, studentId/mentorId, teacherId)

**State transitions:**
- `course_purchase` refund: enrollment `status → 'refunded'`, teacher earning `status → 'reversed'`
- `session_booking` refund: session `status → 'refunded'`, mentor earning `status → 'reversed'`

**Idempotency:**
- Outer: `markProcessed(stripeEvent.id)` deduplicates the `charge.refunded` event
- Earnings reversal: `ConditionExpression: '#status <> :reversed'` prevents double-reversal

**OWNER DECISION noted in code:**
```javascript
// OWNER_DECISION: Define whether refunded students retain course access.
// Currently status is set to 'refunded' but course access is NOT revoked.
// To revoke access, add a check in the course content Lambda that rejects
// requests where enrollment.status === 'refunded'.
```

---

## 9. Tests Created

File: `aws-backend/tests/payment.test.js`

| # | Test | Description |
|---|---|---|
| 1 | Successful course payment | Student enrolled (correct keys), teacher credited (correct earningId and split) |
| 2 | Successful session payment | Session confirmed, mentor credited (pending status) |
| 3 | Failed/cancelled payment | Session marked payment_failed; no enrollment or earnings |
| 4 | Duplicate webhook delivery | `markProcessed` throws ConditionalCheckFailedException → duplicate skip |
| 4b | Enrollment already exists | ConditionalCheckFailedException on enrollment → continues without error |
| 5 | Missing studentId in metadata | Graceful skip; only markProcessed DynamoDB call |
| 6 | Missing courseId in metadata | Graceful skip; only markProcessed DynamoDB call |
| 7 | Course not found in DB | 404 returned from payments Lambda |
| 8 | Refund processing | Enrollment marked refunded, earnings reversed |
| 9 | Duplicate refund event | Outer dedup catches it; no state changes |
| 10 | Missing authorizer context → 401 | Hard rejection from payments Lambda |
| 10b | No requestContext at all → 401 | Hard rejection from payments Lambda |
| (bonus) | Server-authoritative price | Verifies Stripe called with DB price (5000 cents), not client amount |

---

## 10. Test Results

```
PASS tests/payment.test.js
  stripe-webhook: payment_intent.succeeded — course purchase
    ✓ 1. Successful course payment: student enrolled, teacher credited (38 ms)
  stripe-webhook: payment_intent.succeeded — session booking
    ✓ 2. Successful session payment: session confirmed, mentor credited (3 ms)
  stripe-webhook: payment_intent.payment_failed
    ✓ 3. Failed payment: no enrollment, no earnings, session marked failed (2 ms)
  stripe-webhook: idempotency
    ✓ 4. Duplicate webhook delivery — no double enrollment or earnings (1 ms)
    ✓ 4b. Enrollment already exists — idempotent, no error (2 ms)
  stripe-webhook: missing metadata
    ✓ 5. Missing studentId in metadata — graceful skip, no crash (2 ms)
    ✓ 6. Missing courseId in metadata — graceful skip, no crash (4 ms)
  stripe-webhook: charge.refunded
    ✓ 8. Refund processing: enrollment marked refunded, earnings reversed (4 ms)
    ✓ 9. Duplicate refund event — idempotent, no double reversal (1 ms)
  payments Lambda: authorization
    ✓ 10. Missing API Gateway authorizer context → 401 (6 ms)
    ✓ 10b. No requestContext at all → 401 (3 ms)
  payments Lambda: course purchase — server-authoritative price
    ✓ 7. Course not found in DB → 404 (1 ms)
    ✓ Course found — creates PaymentIntent with server price, not client-supplied amount (2 ms)

Tests:       13 passed, 13 total
Time:        6.115 s
```

---

## 11. flutter analyze Result

28 issues — **all `info` level** (no errors, no warnings that block the build).

Notable infos: `use_build_context_synchronously` in course_view.dart (pre-existing), `deprecated_member_use` for TextFormField `value` in teacher course views (pre-existing), `file_names` naming convention issues (pre-existing).

---

## 12. flutter test Result

```
+50: All tests passed!
```

50 tests, all passing.

---

## 13. APK Build Result

**BLOCKED** by missing `google-services.json`.

```
Execution failed for task ':app:processDebugGoogleServices'.
> File google-services.json is missing.
  Searched: android/app/google-services.json
```

This is a pre-existing owner blocker — the Firebase configuration file must be obtained from the Firebase console for project `torino-todd` (or equivalent) and placed at `android/app/google-services.json`. This is the same blocker noted in prior phases.

---

## 14. Owner Blockers

1. **google-services.json** — Required for APK build. Obtain from Firebase Console → Project Settings → Your apps → Google Services. Place at `android/app/google-services.json`.

2. **Refund access policy** — Code currently marks enrollment `status: 'refunded'` but does NOT revoke course access. Owner must decide: do refunded students retain access? If not, add a status check in the course content Lambda. See `OWNER_DECISION` comment in `aws-backend/lambda/stripe-webhook/index.js` in `handleChargeRefunded`.

3. **STRIPE_WEBHOOK_SECRET, STRIPE_SECRET_KEY** — Must be configured as Lambda environment variables before the webhook endpoint receives live Stripe events.

4. **COURSES_TABLE env var** — Should be set on the payments Lambda (defaults to `toriino-courses` if unset).

---

## 15. Remaining P0 Issues

None introduced in this phase. The course purchase flow is now fully server-authoritative.

---

## 16. Remaining P1 Issues

- **Unverified JWT fallback in 7 other Lambdas** — `notifications/register-device`, `upload-url`, `ai-chat`, `ai-twins`, `ai-summaries`, `ai-memory`, `ai-transcripts` all contain the same `Buffer.from(token.split('.')[1], 'base64url')` fallback that was removed from payments. These should be hardened in a follow-up phase.

---

## 17. Remaining P2/P3 Issues

- `use_build_context_synchronously` lint warnings in `course_view.dart` and `home_view.dart` after async payment calls — low risk but should be addressed by capturing context-dependent state before the `await`.
- Duplicate enrollment path: after a successful payment, `course_view.dart` calls both the Stripe webhook (server-side) and `CourseRepo().enrollCourse()` (client API call). Both will try to create an enrollment. The webhook write uses the correct table schema now; the client call goes through the courses Lambda. They will both succeed on first call (different code paths), which is acceptable, but the double-write could be cleaned up in a future pass.
- Teacher profile images in course cards use a static asset placeholder (`assets/images/mentor.png`) instead of a real teacher profile photo.
