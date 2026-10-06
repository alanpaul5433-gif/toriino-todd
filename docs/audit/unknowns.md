# Security Audit — Resolved Unknowns

| ID | Finding | File | Line | Risk |
|----|---------|------|------|------|
| UNK01 | Agora App ID `82cc37a56aad47eea0cb717dc33b9ccd` is hardcoded in `AppConfig`. App Certificate is server-only (Lambda). Token fetched from `/sessions/token` endpoint at runtime. | `lib/config/app_config.dart` | 9 | Medium — App ID is public by design; certificate is correctly server-side. |
| UNK02 | No hardcoded AWS access key ID or secret key found anywhere in the Dart source. Cognito Pool ID and client ID are present but those are not IAM credentials. | `lib/config/aws_config.dart` | 3–5 | Low — No IAM credentials in binary. |
| UNK03 | Live Stripe publishable key `pk_live_[REDACTED]` is hardcoded in `AppConfig`. Used in `StripeService.init()`. Secret key is Lambda-only. | `lib/config/app_config.dart` | 20–21 | Low-Medium — Publishable keys are intentionally public, but this is a **live** key embedded in the binary; consider using test key in debug builds. |
| UNK04 | Gemini API key was hardcoded in `AppConfig` (key redacted — see git history; must be revoked). | `lib/config/app_config.dart` | 15–16 | High — Gemini API keys are quota-bearing credentials; hardcoding them in a Flutter binary exposes them to extraction via reverse engineering. |
| UNK05 | Two hardcoded Lambda/API Gateway endpoint URLs exist: (1) `https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod` in `AppUrl.baseUrl`; (2) `https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/dev` in `AWSConfig.apiEndpoint`. Both are hardcoded. Same stage ID in both, only environment path differs. | `lib/data/appURL/app_url.dart` line 3; `lib/config/aws_config.dart` line 12–13 | 3 / 12 | Medium — Endpoint URLs expose infrastructure detail; no credential leakage, but prod/dev mismatch is a bug risk. |
| UNK06 | S3 bucket name `torino-app-storage` (region `us-east-1`) is hardcoded in `AWSConfig`. `S3Service.uploadFile()` sends unauthenticated HTTP PUT with header `'x-amz-acl': 'public-read'` — **no auth enforced on uploads**. | `lib/config/aws_config.dart` line 8; `lib/services/s3_service.dart` line 24–30 | 8 / 24 | Critical — Unauthenticated public-write uploads allow arbitrary content injection; bucket ACL must be tightened and pre-signed URLs or Cognito credentials used. |
| UNK07 | No plaintext bank/routing numbers are hardcoded in source. The withdrawal sheet (`withdraw_sheet.dart`) collects them from user input at runtime via `TextEditingController` and POSTs them to the API; they are never persisted locally. | `lib/view/widgets/withdraw_sheet.dart` | 61–65 | Low — Input only; not stored. Ensure transmission is over TLS (API Gateway enforces this). |
| UNK08 | **Dual mechanism**: `FlutterSecureStorage` is used in `AuthService` for JWT tokens (access, id, refresh). `SharedPreferences` is used in `UsersPrefrence` for non-sensitive data such as `userRole`. | `lib/services/auth_service.dart` line 12; `lib/viewmodel/controller/login/user_prefrence/users_prefrence.dart` line 2 | 12 / 2 | Medium — Tokens are stored securely. Role in SharedPreferences is plaintext but low sensitivity. Ensure no token ever migrates to SharedPreferences. |
| UNK09 | Teacher role is **not hardcoded** at a global level. However `AuthService.signUp()` does hardcode `custom:role = 'Student'` at Cognito sign-up time. Role routing in `login_view.dart` reads from the JWT claim. | `lib/services/auth_service.dart` line 21; `lib/view/auth/login_view.dart` line 72–83 | 21 / 72 | High — Role hardcoded to Student at sign-up means teacher/mentor selection never takes effect in JWT. This is confirmed BUG-P1-06 / GATE-03. |
| UNK10 | One force-unwrap `!` on a nullable JWT value exists: `_session!.idToken.jwtToken!.split('.')` during sign-in (line 97). Also `_session!.refreshToken!.token` on line 91. Both are inside a `try/catch (_) {}` block so a crash is swallowed silently. | `lib/services/auth_service.dart` | 91, 97 | Medium — Silent failure means a null token write could leave the user appearing logged-in with no valid token. |

---

## Top 3 Critical Items

### 1. UNK06 — Unauthenticated S3 Uploads (Critical / GATE-05)
`S3Service.uploadFile()` performs a raw HTTP PUT to the public S3 bucket URL with `x-amz-acl: public-read` and **no authentication header**. Anyone who discovers the bucket name can upload arbitrary files to any path. Fix: Lambda `upload-url` issues pre-signed PUT scoped to `users/{cognitoSub}/{uuid}.{ext}`. Block public PUT on bucket. See P2-2.

### 2. UNK04 — Gemini API Key Hardcoded in Binary (High / GATE-01)
The Gemini API key is embedded as a compile-time constant in `AppConfig`. Flutter release APKs can be reverse-engineered with `apktool` + `grep "AIza"`, exposing this key. An attacker can consume quota or exfiltrate training data. Fix: Lambda `ai-tutor` proxy reads key from env var. Revoke current key immediately — it is in git history. See P2-1.

### 3. UNK09 / BUG-P1-06 — Teacher Role Hardcoded to Student at Sign-Up (High / GATE-03)
`AuthService.signUp()` sets `custom:role = 'Student'` unconditionally. This means the JWT `custom:role` claim is always Student regardless of what the user selected in the role chooser. Teacher and Mentor users are permanently mis-routed. Fix: pass the selected role through sign-up params and sync Cognito attribute after role selection. See P3-3.

---

## Key File Locations

| File | Relevant To |
|------|-------------|
| `lib/config/app_config.dart` | Agora App ID (UNK01), Gemini API key (UNK04), Stripe PK (UNK03) |
| `lib/config/aws_config.dart` | Cognito Pool/Client IDs, S3 bucket (UNK06), API endpoint (UNK05) |
| `lib/data/appURL/app_url.dart` | Prod Lambda base URL (UNK05) |
| `lib/services/auth_service.dart` | Token storage (UNK08), force-unwrap (UNK10), role bug (UNK09) |
| `lib/services/s3_service.dart` | Unauthenticated upload (UNK06) |
| `lib/viewmodel/controller/login/user_prefrence/users_prefrence.dart` | SharedPreferences role (UNK08) |
| `lib/view/auth/login_view.dart` | JWT role extraction and routing (UNK09) |
| `lib/view/widgets/withdraw_sheet.dart` | Bank details runtime input (UNK07) |
