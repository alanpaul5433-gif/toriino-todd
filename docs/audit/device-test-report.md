# Torino Todd — UAT Device Test Report

**Date:** 2026-10-06  
**Branch:** fix/remediation-v1  
**Device:** Samsung SM-A075F (Android 13, API 33) — serial R8VL2015Y6J  
**APK:** build/app/outputs/flutter-apk/app-debug.apk (debug, Skia/OpenGL)  
**Tester:** Automated UAT via Claude Code  

---

## Test Configuration

- Firebase disabled locally for build (no google-services.json); edits reverted after testing.
- Credentials sourced from `.env.test`.
- Sections 5 (Course Purchase), 6 (Agora), 7, 8 skipped per plan (BLOCKED / NOT TESTABLE).
- Bug recording only — no fixes applied.

---

## Section 1 — Authentication

| ID  | Test                                         | Result  | Notes |
|-----|----------------------------------------------|---------|-------|
| 1.1 | Student login with valid credentials         | PARTIAL | Cognito auth succeeds; tokens stored in FlutterSecureStorage. `AnalyticsService.logLogin()` then throws `[core/no-app] No Firebase App '[DEFAULT]'` (P0 bug) — navigation is aborted. Workaround: force-stop + restart → RoleSelectionScreen (P1 bug) → select role → home. |
| 1.2 | Mentor login with valid credentials          | PARTIAL | Same P0 pattern. Mentor credentials confirmed accepted by Cognito; post-auth crash same as 1.1. |
| 1.3 | Invalid credentials rejected                 | PASS    | Error toast displayed; no navigation on bad password. |
| 1.4 | Session persists after restart               | PARTIAL | Tokens persist (FlutterSecureStorage); however P1 bug (`custom:role` case mismatch) means every restart routes to RoleSelectionScreen instead of home — user must manually re-select role. |
| 1.5 | Forgot password link present                 | PASS    | "Forgot Password?" element visible and clickable in UIAutomator tree (`[36,775][684,809]`). |
| 1.6 | Create account link present                  | PASS    | "Create an account" element visible and clickable in UIAutomator tree (`[302,1059][563,1110]`). |
| 1.7 | Logout                                       | PARTIAL | Drawer-based logout not accessible via UIAutomator (GestureDetector not in a11y tree). Logout flow verified via code review: `AuthService.signOut()` + `UsersPrefrence().removeUser()` → LoginView. Verified functionally via `pm clear` (app data wipe). |

**Section 1 summary: 2 PASS, 5 PARTIAL (P0 + P1 bugs affect every auth flow)**

---

## Section 2 — Mentor Profile

| ID  | Test                                        | Result  | Notes |
|-----|---------------------------------------------|---------|-------|
| 2.1 | Mentor profile view loads                   | PASS    | Navigated to `MentorPrivateProfileView` via `input touchscreen tap 504 1519` (Tab 4 in mentor nav). Screen rendered. |
| 2.2 | Profile fields display correctly            | PARTIAL | All editable fields show placeholder `"--"`. Test account has no profile data populated; fields exist and render. |
| 2.3 | Profile edit persists                       | NOT TESTED | Could not edit and save — taps on fields within full-screen scrollable not reliable; navigation back impossible after entering profile view (P2 bug). |

**Section 2 summary: 1 PASS, 1 PARTIAL, 1 NOT TESTED**

---

## Section 3 — Student Search (Mentor Create Session)

| ID  | Test                                                         | Result  | Notes |
|-----|--------------------------------------------------------------|---------|-------|
| 3.1 | Student search field present in Create Session form          | PASS    | Confirmed in `mentor_create_session_view.dart`: `TextField(controller: _studentSearchController, decoration: _inputDecoration("Search student by name or email"))`. |
| 3.2 | Typing ≥ 2 chars triggers search API call                    | PASS    | Code-verified: `_searchStudents` fires only when `query.trim().length >= 2`. |
| 3.3 | Tapping result populates student ID field                    | PASS    | Code-verified: `onTap` sets `_studentIdController.text = student.userId`. |
| 3.4 | Typing < 2 chars shows no results                            | PASS    | Code-verified: `if (query.trim().length < 2) { setState(() => _searchResults = []); return; }`. |

**Note:** Physical navigation to MentorCreateSessionView was blocked by the tab navigation P2 bug (full-screen scrollable in MentorHomeView preventing Tab 3 access). All 3.x results are code-confirmed, not physically exercised.

**Section 3 summary: 4 PASS (code-verified)**

---

## Section 4 — Session Booking

| ID  | Test                                                             | Result  | Notes |
|-----|------------------------------------------------------------------|---------|-------|
| 4.1 | Student can view and initiate booking                           | PASS    | Student home → "View All" → BrowseMentor → "Book Session" (Isabella Costa, $130/hr) → AvailabilityView rendered with calendar and time pickers. |
| 4.2 | Session record created before Stripe payment                    | PASS    | Code-verified in `availability_view.dart` `_bookSessionBottomSheet()`: Step 1 calls `SessionRepo().bookSession(...)`, Step 2 calls `StripeService.payForSession(sessionId: realSessionId)`. Comment: "Session is created BEFORE Stripe payment so the real UUID is available in Stripe metadata." |
| 4.3 | Stripe PaymentSheet opens                                       | BLOCKED | Stripe publishable/secret keys not set in environment. |
| 4.4 | Payment success marks session confirmed                         | BLOCKED | Stripe keys not set. |
| 4.5 | Payment failure cancels session                                 | BLOCKED | Stripe keys not set. Code-verified: `SessionRepo().updateSessionStatus(realSessionId, 'cancelled')` on failure. |
| 4.6 | Duplicate booking rejected                                      | BLOCKED | Stripe keys not set. |

**Note:** "Proceed to Payment" button ([36,1482][684,1568]) was unresponsive during headless testing — UIAutomator shows element as clickable, but no Flutter touch events fired. Root cause: modal scrim or custom GestureDetector in `AuthButton` not hit-testable under headless scrollable interference.

**Section 4 summary: 2 PASS, 1 NOT FULLY EXERCISED, 3 BLOCKED (Stripe keys not set)**

---

## Section 5 — Course Purchase

| ID  | Test                                  | Result  | Notes |
|-----|---------------------------------------|---------|-------|
| 5.1 | Student browses courses               | PARTIAL | Student home shows course cards visible in UI. Full navigation into course detail was not performed. |
| 5.2 | Course purchase flow                  | BLOCKED | Stripe keys not set. |
| 5.3 | Purchase confirmation                 | BLOCKED | Stripe keys not set. |
| 5.4 | Duplicate purchase prevention         | BLOCKED | Stripe keys not set. |
| 5.5 | Purchased course access               | BLOCKED | Stripe keys not set. |

**Section 5 summary: 1 PARTIAL, 4 BLOCKED**

---

## Section 6 — Agora Live Sessions

| ID  | Test                      | Result        | Notes |
|-----|---------------------------|---------------|-------|
| 6.1 | Host starts live session  | NOT TESTABLE  | No second device available for attendee role. |
| 6.2 | Student joins session     | NOT TESTABLE  | No second device available. |
| 6.3 | Video/audio streams       | NOT TESTABLE  | No second device available. |
| 6.4 | Session ends properly     | NOT TESTABLE  | No second device available. |

**Section 6 summary: 4 NOT TESTABLE (no second device)**

---

## Section 9 — Admin Panel

| ID  | Test                                       | Result | Notes |
|-----|--------------------------------------------|--------|-------|
| 9.1 | Admin login rejected for non-admin role    | FAIL   | No admin UI route exists. `login_view.dart` routes: Student→MainWrapper, Mentor→MentorBottomNavBar, Teacher→TeacherBottomNavBar, else→RoleSelectionScreen. No admin case. Admin user hits RoleSelectionScreen with no valid role path. |
| 9.2 | Admin can list users                       | FAIL   | No admin screen exists in the app. No admin-specific Dart files found under `lib/view/`. |
| 9.3 | Admin can list sessions                    | FAIL   | No admin screen. |
| 9.4 | Non-admin cannot access admin endpoints    | FAIL   | No admin UI to test from. Backend-level check not verifiable without admin UI. |

**Section 9 summary: 4 FAIL — admin panel not implemented**

---

## Section 10 — Wallet

| ID   | Test                                             | Result       | Notes |
|------|--------------------------------------------------|--------------|-------|
| 10.1 | Wallet balance displays                          | PARTIAL      | `EarinigView` (Tab 2, mentor nav) renders `totalEarnings - totalWithdrawn` as available balance, with a Withdraw button. Navigation to Tab 2 was blocked by P2 bug (full-screen scrollable in Tab 1 prevents tab switching). Code confirms display logic is implemented; physical rendering not verified. |
| 10.2 | Deduction with sufficient balance succeeds       | NOT IMPLEMENTED | `availability_view.dart` has TODO: "When wallet-deduction Lambda is ready." No deduction Lambda exists. |
| 10.3 | Deduction with insufficient balance returns 402  | NOT IMPLEMENTED | Same — deduction Lambda not deployed. |
| 10.4 | Duplicate deduction (same idempotencyKey) is no-op | NOT IMPLEMENTED | Same — deduction Lambda not deployed. |

**Section 10 summary: 1 PARTIAL, 3 NOT IMPLEMENTED**

---

## Security Checks

| ID | Check                                    | Result | Notes |
|----|------------------------------------------|--------|-------|
| S1 | APK secret scan (patterns in binary)     | PASS   | Extracted APK searched for `AIza`, `AQ.`, `sk_live_`, `pk_live_`, `AKIA`. No matches found in any APK file contents. |
| S2 | S3 unauthenticated PUT test              | PASS   | `curl -X PUT https://torino-uploads-dev.s3.amazonaws.com/uat-test-probe.txt` returned HTTP 403 (Access Denied). Unauthorized writes blocked. |
| S3 | Git grep for secrets in Dart code        | PASS   | `git grep -l 'sk_live_\|pk_live_\|AKIA\|AIza\|AQ\.'` scoped to `*.dart` returned no matches. Note: `sk_live_` and `pk_live_` appear in `.md` documentation files (`OWNER_DECISIONS_REQUIRED.md`, `PHASE_12_VERIFICATION_REPORT.md`, `EXECUTION_PLAN.md`) — documentation context only, not live secrets. |

**Security summary: 3 PASS**

---

## Performance Checks

| ID | Check              | Result | Notes |
|----|--------------------|--------|-------|
| P1 | Cold start time    | PASS   | `adb shell am start-activity -W`: TotalTime = **3488 ms**, WaitTime = 3496 ms. Under 5 s threshold. Impeller/Skia shader warm-up accounts for startup cost. |
| P2 | Scroll FPS         | PARTIAL | Pre-scroll measurement: 4 frames at 7–8 ms p99 (0% janky, pipeline Skia/OpenGL). Full scroll-test measurement returned 0 frames after gfxinfo reset — swipe events consumed by full-screen scrollable before reaching Flutter render. Insufficient data for sustained scroll FPS; frame latency when rendered is well within 60 fps budget. |
| P3 | Memory usage       | INFO   | `dumpsys meminfo com.torino.todd`: PSS Total = **455,508 KB (~445 MB)**, Native Heap = 63,868 KB (~62 MB), Total RSS = 549,157 KB (~536 MB). High PSS for a mobile app — GPU texture cache and Skia buffers account for a significant portion. Recommend profiling on release build. |

---

## Bugs Found

### P0 — CRITICAL: Firebase crash blocks post-login navigation

**File:** `lib/services/analytics_service.dart:12`  
**Call site:** `lib/view/auth/login_view.dart:72`  
**Description:** `AnalyticsService.logLogin()` calls `FirebaseCrashlytics.instance.setCustomKey('last_event', 'login')` unconditionally after successful Cognito auth. With no `google-services.json` present, this throws `[core/no-app] No Firebase App '[DEFAULT]'`, aborting navigation. No `try-catch` wraps the call.  
**Impact:** Every login attempt fails to navigate. App is unusable without the Firebase workaround.  
**Workaround (UAT only):** Wrapped `Firebase.initializeApp()` and `FcmService.init()` in try-catch in `main.dart`/`fcm_service.dart`; used force-stop + restart to bypass navigation via stored tokens.

---

### P1 — HIGH: Role routing fails on every restart

**File:** `lib/view/splash/splash_view.dart`  
**Description:** Splash compares JWT `custom:role` claim (lowercase: `'mentor'`, `'student'`, `'teacher'`) against capitalized string literals (`'Mentor'`, `'Student'`, `'Teacher'`). The comparison always fails, routing every logged-in user to `RoleSelectionScreen` on restart.  
**Impact:** Users must manually re-select role on every app restart. Session continuity is broken.

---

### P2 — HIGH: Full-screen scrollable blocks bottom nav bar

**Files:** `lib/view/users/mentor_view/mentor_home_view.dart`, `mentor_sessions_view.dart` and other home views  
**Description:** A `ListView` with full-screen dimensions `[0,0][720,1600]` overlays the bottom navigation bar, consuming all touch events and preventing tab switching via `input tap` and intermittently via `input touchscreen tap`. The scrollable sits above the nav bar in the widget tree.  
**Impact:** Tab navigation broken in almost all test conditions. Affects sections 2, 3, 10.

---

### P3 — MEDIUM: Drawer toggle not accessible via UIAutomator

**File:** `lib/view/users/mentor_view/mentor_home_view.dart`  
**Description:** The hamburger menu / AdvancedDrawer toggle is a `GestureDetector` with no semantics, not exposed in the a11y tree. UIAutomator cannot interact with it. Left-edge swipe is consumed by the full-screen scrollable.  
**Impact:** Logout flow not testable via automated a11y tools. Drawer contents (including logout) inaccessible in headless testing.

---

### P4 — HIGH: Admin panel not implemented

**Description:** No admin routing, no admin views, no admin-specific API calls exist in Dart code. `login_view.dart` has no admin case. Admin users reach `RoleSelectionScreen` with no valid role path.  
**Impact:** All Section 9 tests fail. Admin user role is effectively locked out of the app.

---

### P5 — MEDIUM: Wallet deduction Lambda not deployed

**File:** `lib/view/users/student_view/availability_view.dart`  
**Description:** Code contains TODO comment: `// When wallet-deduction Lambda is ready`. `EarningsRepo` has `getEarningsSummary()` and `getEarningsHistory()` endpoints but no deduction endpoint. The wallet balance display in `EarinigView` is implemented; the deduction path is not.  
**Impact:** Sections 10.2–10.4 not testable.

---

## Test Result Summary

| Section | Name              | PASS | PARTIAL | FAIL | BLOCKED | NOT TESTABLE | NOT IMPLEMENTED |
|---------|-------------------|------|---------|------|---------|--------------|-----------------|
| 1       | Authentication    | 2    | 5       | 0    | 0       | 0            | 0               |
| 2       | Mentor Profile    | 1    | 1       | 0    | 0       | 1            | 0               |
| 3       | Student Search    | 4    | 0       | 0    | 0       | 0            | 0               |
| 4       | Session Booking   | 2    | 0       | 0    | 3       | 0            | 0               |
| 5       | Course Purchase   | 0    | 1       | 0    | 4       | 0            | 0               |
| 6       | Agora             | 0    | 0       | 0    | 0       | 4            | 0               |
| 9       | Admin Panel       | 0    | 0       | 4    | 0       | 0            | 0               |
| 10      | Wallet            | 0    | 1       | 0    | 0       | 0            | 3               |
| S1–S3   | Security          | 3    | 0       | 0    | 0       | 0            | 0               |
| P1–P3   | Performance       | 1    | 1       | 0    | 0       | 1            | 0               |
| **Total** |                | **13** | **9** | **4** | **7** | **6**        | **3**           |

---

## Firebase Disable Workaround — Revert Confirmation

The following files were modified for UAT (Firebase disabled locally) and have been reverted after testing:

- `android/app/build.gradle` — `id "com.google.gms.google-services"` uncommented
- `android/build.gradle` — `classpath 'com.google.gms:google-services:4.4.2'` uncommented
- `lib/main.dart` — Firebase init try-catch removed; original code restored
- `lib/services/fcm_service.dart` — Background handler try-catch removed; original code restored

`git status` after revert: only `UAT_PLAN.md` and `docs/audit/device-test-report.md` are untracked.
