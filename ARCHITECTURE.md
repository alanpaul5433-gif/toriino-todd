# Toriino Todd — Architecture Document

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (Client)                    │
│                                                             │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │  Views    │→ │  ViewModels   │→ │   Repositories     │   │
│  │ (UI/UX)  │← │ (GetxCtrl)   │← │   (Data Access)    │   │
│  └──────────┘  └──────────────┘  └─────────┬──────────┘   │
│                                             │               │
│  ┌──────────────────────────────────────────┴────────┐     │
│  │              Network Layer                         │     │
│  │  NetworkApiServices → Auth Interceptor → HTTP     │     │
│  └──────────────────────────────────┬────────────────┘     │
│                                     │                       │
│  ┌──────────────┐  ┌───────────────┴───────────────┐      │
│  │ SecureStorage │  │ WebSocket / AppSync Client    │      │
│  │ (Tokens)      │  │ (Real-time)                   │      │
│  └──────────────┘  └───────────────────────────────┘      │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS / WSS
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                        AWS CLOUD                            │
│                                                             │
│  ┌──────────────┐     ┌──────────────────────────────┐    │
│  │   Cognito     │     │       API Gateway (REST)      │    │
│  │  User Pool    │────→│  Cognito Authorizer           │    │
│  │  - Auth       │     │  /auth/*  /courses/*          │    │
│  │  - Roles      │     │  /sessions/* /mentors/*       │    │
│  │  - Tokens     │     │  /users/*  /notifications/*   │    │
│  └──────────────┘     └──────────┬───────────────────┘    │
│                                  │                         │
│                          ┌───────▼──────┐                  │
│                          │   Lambda      │                  │
│                          │  Functions    │                  │
│                          └───┬───┬───┬──┘                  │
│                              │   │   │                     │
│          ┌───────────────────┘   │   └──────────────┐     │
│          ▼                       ▼                   ▼     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  DynamoDB     │   │     S3        │   │   AppSync    │  │
│  │  (12 Tables)  │   │  (Files)      │   │  (Real-time) │  │
│  └──────────────┘   └──────────────┘   └──────────────┘  │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐                      │
│  │    SNS        │   │     SES       │                      │
│  │ (Push Notif)  │   │  (Email)      │                      │
│  └──────────────┘   └──────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Flutter App Architecture (GetX MVVM)

### Layer Diagram

```
┌────────────────────────────────────────────────────┐
│                    VIEW LAYER                       │
│  Splash → Login → Role Selection → Role-specific   │
│                                                     │
│  Student Views    Teacher Views    Mentor Views     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ HomeView   │  │ HomeView   │  │ HomeView   │   │
│  │ CourseView │  │ CreateCrs  │  │ Sessions   │   │
│  │ Mentors   │  │ Earnings   │  │ Earnings   │   │
│  │ Sessions  │  │ Profile    │  │ Avail.     │   │
│  │ AI Tutor  │  │ AI Tutor   │  │ Profile    │   │
│  └────────────┘  └────────────┘  └────────────┘   │
│            │              │              │          │
│            ▼              ▼              ▼          │
├────────────────────────────────────────────────────┤
│                 VIEWMODEL LAYER                     │
│           (GetxControllers + Rx<ApiResponse>)       │
│                                                     │
│  LoginVM  │ HomeVM  │ CourseVM  │ SessionVM  │ ... │
│           │         │          │            │      │
│            ▼              ▼              ▼          │
├────────────────────────────────────────────────────┤
│                REPOSITORY LAYER                     │
│         (Data access + JSON parsing)                │
│                                                     │
│  AuthRepo │ CourseRepo │ SessionRepo │ UserRepo │..│
│           │            │             │           │  │
│            ▼              ▼              ▼          │
├────────────────────────────────────────────────────┤
│                 NETWORK LAYER                       │
│                                                     │
│  NetworkApiServices (GET/POST/PUT/DELETE/PATCH)     │
│  AuthInterceptor (token injection)                  │
│  AppException hierarchy                             │
│  ApiResponse<T> wrapper (loading/success/error)     │
├────────────────────────────────────────────────────┤
│                 DATA LAYER                          │
│                                                     │
│  Models (fromJson/toJson)   SecureStorage (tokens) │
│  AppUrl (endpoint constants) SharedPrefs (settings)│
└────────────────────────────────────────────────────┘
```

---

## Authentication Flow

```
┌──────────┐    ┌──────────┐    ┌──────────────┐    ┌──────────┐
│  Splash  │───→│ Check    │───→│  Token Valid? │───→│ Role-    │
│  Screen  │    │ Token    │    │              │YES │ specific │
└──────────┘    └──────────┘    └──────┬───────┘    │ Home     │
                                       │NO          └──────────┘
                                       ▼
                                ┌──────────┐    ┌──────────┐
                                │  Login   │───→│  Cognito  │
                                │  Screen  │    │  Auth     │
                                └────┬─────┘    └────┬─────┘
                                     │               │
                                     │          ┌────▼─────┐
                                ┌────▼─────┐    │ Save     │
                                │  Sign Up │    │ Tokens   │
                                │  Screen  │    │ Securely │
                                └────┬─────┘    └────┬─────┘
                                     │               │
                                ┌────▼─────┐    ┌────▼──────────┐
                                │  OTP     │    │ Role Selection │
                                │  Verify  │    │ (if new user)  │
                                └──────────┘    └────┬──────────┘
                                                     │
                                    ┌────────────────┼────────────────┐
                                    ▼                ▼                ▼
                              ┌──────────┐    ┌──────────┐    ┌──────────┐
                              │ Student  │    │ Teacher  │    │ Mentor   │
                              │ NavShell │    │ NavShell │    │ NavShell │
                              └──────────┘    └──────────┘    └──────────┘
```

---

## Data Flow Pattern

```
User Action (tap, scroll, submit)
        │
        ▼
┌──────────────┐
│    View       │  Calls controller method
│  (Widget)     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  ViewModel    │  1. Sets rxData = ApiResponse.loading()
│ (GetxCtrl)   │  2. Calls repository
└──────┬───────┘  3. On success: rxData = ApiResponse.success(data)
       │          4. On error: rxData = ApiResponse.error(msg)
       ▼
┌──────────────┐
│  Repository   │  Calls NetworkApiServices with endpoint + data
│              │  Parses JSON response into Model
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ NetworkAPI    │  1. AuthInterceptor injects Bearer token
│  Services    │  2. Makes HTTP request
└──────┬───────┘  3. Handles status codes (200/201/401/500)
       │          4. Throws AppException on failure
       ▼
┌──────────────┐
│  AWS API      │  API Gateway → Lambda → DynamoDB/S3
│  Gateway     │
└──────────────┘
```

---

## DynamoDB Table Design

### Tables (12)

| Table | Partition Key | Sort Key | Purpose |
|-------|-------------|----------|---------|
| Users | userId | — | All user profiles (student/teacher/mentor) |
| Courses | courseId | — | Course details, category, price |
| CourseLessons | courseId | lessonId | Lessons within a course |
| Enrollments | studentId | courseId | Student-course enrollment records |
| Teachers | userId | — | Teacher-specific data (subjects, bio) |
| Mentors | userId | — | Mentor-specific data (expertise, rate) |
| Sessions | sessionId | — | Booked sessions (student + mentor/teacher) |
| Availability | mentorId | slotId | Mentor time slots |
| Reviews | targetId | reviewId | Reviews for mentors/teachers/courses |
| Notifications | userId | timestamp#notifId | User notifications (sorted by time) |
| Earnings | userId | periodKey | Monthly earning summaries |
| Subscriptions | userId | subscriptionId | User subscription plans |

### Global Secondary Indexes (GSIs)
- **Courses-by-category:** GSI on `category` for browsing
- **Courses-by-teacher:** GSI on `teacherId` for teacher dashboard
- **Sessions-by-mentor:** GSI on `mentorId` for mentor dashboard
- **Sessions-by-student:** GSI on `studentId` for student sessions
- **Sessions-by-date:** GSI on `date` for schedule views

---

## API Endpoints

### Auth (`/auth`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user (Cognito) |
| POST | `/auth/login` | Login (Cognito) |
| POST | `/auth/verify` | Verify OTP |
| POST | `/auth/refresh` | Refresh token |
| POST | `/auth/forgot-password` | Send reset code |
| POST | `/auth/reset-password` | Reset password |
| POST | `/auth/logout` | Sign out |

### Users (`/users`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users/profile` | Get current user profile |
| PUT | `/users/profile` | Update profile |
| PUT | `/users/role` | Set/update role |
| DELETE | `/users/account` | Delete account |
| POST | `/users/avatar` | Get S3 presigned URL for avatar upload |

### Courses (`/courses`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/courses` | List courses (with filters) |
| GET | `/courses/{id}` | Get course details |
| POST | `/courses` | Create course (teacher) |
| PUT | `/courses/{id}` | Update course (teacher) |
| DELETE | `/courses/{id}` | Delete course (teacher) |
| GET | `/courses/{id}/lessons` | Get lessons |
| POST | `/courses/{id}/lessons` | Add lesson (teacher) |
| PUT | `/courses/{id}/lessons/{lessonId}` | Update lesson |
| DELETE | `/courses/{id}/lessons/{lessonId}` | Delete lesson |
| POST | `/courses/{id}/enroll` | Enroll student |
| GET | `/courses/my-courses` | Student enrolled courses |
| GET | `/courses/my-created` | Teacher created courses |

### Sessions (`/sessions`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/sessions` | List user sessions |
| POST | `/sessions` | Book a session |
| PUT | `/sessions/{id}` | Update session (reschedule) |
| PATCH | `/sessions/{id}/status` | Update status (start/end/cancel) |
| GET | `/sessions/{id}` | Get session details |

### Mentors (`/mentors`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/mentors` | Browse mentors (with filters) |
| GET | `/mentors/{id}` | Get mentor public profile |
| GET | `/mentors/{id}/availability` | Get availability slots |
| PUT | `/mentors/availability` | Update own availability |
| POST | `/mentors/intro-video` | Get S3 presigned URL for video |

### Reviews (`/reviews`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reviews/{targetId}` | Get reviews for mentor/teacher/course |
| POST | `/reviews` | Submit review |

### Notifications (`/notifications`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | Get user notifications |
| PATCH | `/notifications/{id}/read` | Mark as read |
| POST | `/notifications/fcm-token` | Register FCM token |

### Earnings (`/earnings`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/earnings` | Get earnings summary |
| GET | `/earnings/history` | Get earning history |

---

## Real-time Architecture (Phase 6)

```
┌──────────────┐         ┌──────────────┐
│ Flutter App  │◄──WSS──►│  AWS AppSync  │
│              │         │  (GraphQL     │
│ WebSocket    │         │  Subscriptions│
│ Service      │         └──────┬───────┘
└──────────────┘                │
                                ▼
                        ┌──────────────┐
                        │  DynamoDB     │
                        │  Streams      │
                        └──────┬───────┘
                               │ Trigger
                        ┌──────▼───────┐
                        │   Lambda      │
                        │  (Process +   │
                        │   Notify)     │
                        └──────┬───────┘
                               │
                        ┌──────▼───────┐
                        │   SNS → FCM   │
                        │  (Push Notif) │
                        └──────────────┘
```

### Real-time Events
- **Session status changes** — started, ended, cancelled, rescheduled
- **New booking notifications** — for mentors/teachers
- **Enrollment notifications** — for teachers
- **Review notifications** — for mentors/teachers
- **System announcements** — broadcast to all users

---

## File Upload Flow (S3)

```
Flutter App                 Lambda                    S3
    │                         │                        │
    │  1. Request presigned   │                        │
    │     URL with file type  │                        │
    │────────────────────────►│                        │
    │                         │  2. Generate presigned │
    │                         │     PUT URL            │
    │                         │────────────────────────►
    │  3. Return presigned    │                        │
    │     URL                 │                        │
    │◄────────────────────────│                        │
    │                         │                        │
    │  4. Upload file directly│                        │
    │     to S3 using URL     │                        │
    │─────────────────────────────────────────────────►│
    │                         │                        │
    │  5. Save S3 key to      │                        │
    │     user profile/course │                        │
    │────────────────────────►│                        │
    │                         │  6. Store reference    │
    │                         │────────────────────────►
```

---

## Implementation Phases

| Phase | Scope | Weeks | Dependencies |
|-------|-------|-------|-------------|
| **1. Foundation & Auth** | AWS setup, Cognito auth, fix bugs, wire login/signup | 3-4 | — |
| **2. Data Layer** | All models, repos, viewmodels, DynamoDB tables | 2-3 | Phase 1 |
| **3. Student Features** | Wire 24 student views to real data | 3-4 | Phase 2 |
| **4. Teacher Features** | Wire 14 teacher views, course CRUD | 2-3 | Phase 2 |
| **5. Mentor Features** | Wire 15 mentor views, availability, S3 video | 2-3 | Phase 2 |
| **6. Real-time** | AppSync subscriptions, FCM push, live updates | 2-3 | Phases 3-5 |
| **7. Polish** | Error handling, loading states, routes, tests, localization | 3-4 | All |

**Phases 3, 4, 5 can run in parallel with multiple developers.**

---

## Security Considerations
- All tokens stored in FlutterSecureStorage (encrypted)
- AWS credentials never in Flutter code — use Cognito tokens + API Gateway authorizer
- S3 uploads via time-limited presigned URLs only
- API Gateway validates Cognito JWT on every request
- DynamoDB access scoped per-user via Lambda (no direct DB access from client)
- Input validation on both client and Lambda
- HTTPS enforced on all endpoints
