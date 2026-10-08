# API Reference

Base URL: `https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod`  
All endpoints require `Authorization: Bearer <access_token>` except where noted.

## Auth (public)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Sign up |
| POST | `/auth/verify` | Confirm OTP |
| POST | `/auth/login` | Sign in, returns JWT |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/forgot-password` | Send reset code |
| POST | `/auth/reset-password` | Confirm new password |
| POST | `/auth/set-role` | Set the caller's role once, while it is empty: `student`, `teacher` or `mentor` (409 if already set, 403 for admin, 400 otherwise). Admin is never self-assigned |
| POST | `/auth/logout` | Invalidate refresh token |

## Users

| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/profile` | Get own profile |
| PUT | `/users/profile` | Update profile |
| GET | `/users/role` | Get role |
| POST | `/users/avatar` | Upload avatar |
| DELETE | `/users/account` | Delete account |

## Courses

| Method | Path | Description |
|--------|------|-------------|
| GET | `/courses` | List published courses (supports `?lastKey=` pagination) |
| POST | `/courses` | Create course (teacher) |
| GET | `/courses/my-courses` | Student enrolled courses |
| GET | `/courses/my-created` | Teacher created courses |
| GET | `/courses/:id` | Get course |
| PUT | `/courses/:id` | Update course |
| DELETE | `/courses/:id` | Delete course (cascades lessons, blocked if enrolled) |
| GET | `/courses/:id/lessons` | List lessons |
| POST | `/courses/:id/lessons` | Add lesson |
| POST | `/courses/:id/enroll` | Enroll student |

## Sessions

| Method | Path | Description |
|--------|------|-------------|
| GET | `/sessions` | List sessions for current user |
| POST | `/sessions` | Book session |
| GET | `/sessions/:id` | Get session |
| PATCH | `/sessions/:id/status` | Update status |
| GET | `/sessions/token` | Get Agora token |
| POST | `/sessions/:id/recording/start` | Start recording |
| POST | `/sessions/:id/recording/stop` | Stop recording |

## Payments

| Method | Path | Description |
|--------|------|-------------|
| POST | `/payments/create-intent` | Create Stripe PaymentIntent |
| POST | `/stripe/webhook` | Stripe webhook (public, sig-verified) |

## Mentors

| Method | Path | Description |
|--------|------|-------------|
| GET | `/mentors` | List mentors |
| GET | `/mentors/:id` | Get mentor |
| GET | `/mentors/:id/availability` | Get availability slots |
| PUT | `/mentors/:id/availability` | Update availability slots |
| PUT | `/mentors/intro-video` | Update intro video URL |

## Reviews

| Method | Path | Description |
|--------|------|-------------|
| GET | `/reviews/:targetId` | List reviews for a target |
| POST | `/reviews/:targetId` | Submit a review |

## Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notifications` | List notifications for current user |
| PATCH | `/notifications/:sortKey/read` | Mark notification as read |
| POST | `/notifications/fcm-token` | Register FCM device token |

## Earnings

| Method | Path | Description |
|--------|------|-------------|
| GET | `/earnings` | Earnings summary |
| GET | `/earnings/history` | Earnings history |

## Upload

| Method | Path | Description |
|--------|------|-------------|
| GET | `/upload-url` | Pre-signed S3 PUT URL scoped to caller's `sub` |

## AI

| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/ai/chat/:userId` | AI tutor chat history |
| GET/PUT | `/ai/twins/:userId` | AI twin configuration |
| GET/PUT | `/ai/memory/:userId` | User memory (progress, activity, preferences) |
| GET | `/sessions/:id/summary` | AI-generated session summary |
| GET | `/sessions/:id/transcript` | Session transcript |
