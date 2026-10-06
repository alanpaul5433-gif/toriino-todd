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

- **API Gateway** `/prod` stage — 16+ Lambda functions
- **DynamoDB** — all tables prefixed `toriino-`
- **Cognito** — user pool, JWT tokens, `custom:role` claim
- **S3** — `torino-app-storage` (pre-signed PUT via `upload-url` Lambda)
- **SNS** — push notification delivery (pending setup)

## Auth flow

1. Sign up → Cognito (`/auth/register`) → OTP verify → role selection → `/auth/set-role`
2. Login → Cognito (`/auth/login`) → JWT stored in FlutterSecureStorage
3. Every request → `AuthInterceptor.getAuthHeaders()` → auto-refresh 60s before expiry
4. 401 → single-flight refresh → retry; second 401 → sign out

## Security model

- Secrets: Gemini key, Agora ID, Stripe keys via `--dart-define` only (never hardcoded)
- S3: pre-signed PUT scoped to Cognito `sub`; public ACLs blocked (owner action required)
- Bank data: not collected; withdrawals deferred to post-beta Stripe Connect

## Admin panel

The admin panel is a **separate repository** — it does not live inside this Flutter project.
To unblock admin workflows, the owner must:

1. Create a test admin Cognito user (e.g. via the AWS Console or `aws cognito-idp admin-create-user`).
2. Set `custom:role` to `admin` on that user.
3. Point the admin panel at the same API Gateway base URL
   (`https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod`).
