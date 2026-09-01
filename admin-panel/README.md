# Toriino Admin Panel

A Next.js web dashboard for managing the Toriino EdTech platform.

## Screens

| Screen | Path | Features |
|---|---|---|
| Dashboard | `/` | KPI cards, user role breakdown, session stats, monthly revenue |
| Users | `/users` | List/search/filter, activate/deactivate, change role |
| Courses | `/courses` | List by status, approve/reject/publish/delete |
| Sessions | `/sessions` | List by status, view AI summaries, cancel sessions |
| Mentors | `/mentors` | List all mentor profiles, approve/reject applications |
| Earnings | `/earnings` | Platform revenue overview, monthly chart, top earners |
| Reviews | `/reviews` | Moderation queue, remove inappropriate reviews |
| AI Analytics | `/ai` | AI chat/twin/transcript/summary usage stats |
| Notifications | `/notifications` | Broadcast to all/students/teachers/mentors |
| Settings | `/settings` | API config, endpoint list, DynamoDB table overview |

## Setup

### 1. Configure credentials

Create `admin-panel/.env.local`:

```
NEXT_PUBLIC_API_BASE=https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod
NEXT_PUBLIC_COGNITO_REGION=us-east-1
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=YOUR_APP_CLIENT_ID
```

Find these in the AWS Console → Cognito → User Pools → your pool → App clients.

### 2. Create an admin user

In AWS Cognito Console:
1. Go to your User Pool → Users → Create user
2. Enter email and temporary password
3. After creation, go to Groups → Create group named `Admins`
4. Add the user to the `Admins` group

Or via CLI:
```bash
aws cognito-idp create-group --group-name Admins --user-pool-id us-east-1_XXXXXXXX
aws cognito-idp admin-add-user-to-group --user-pool-id us-east-1_XXXXXXXX --username USER_SUB --group-name Admins
```

### 3. Deploy the admin Lambda

```bash
cd aws-backend
node infrastructure/deploy-ai.js --gemini-key=YOUR_KEY
```

Then add `/admin/**` routes to API Gateway pointing to `toriino-admin` Lambda.

### 4. Install and run

```bash
cd admin-panel
npm install
npm run dev
```

Open http://localhost:3001 and sign in with your admin credentials.

## Production deployment

```bash
npm run build
npm start
```

Or deploy to Vercel: connect the `admin-panel/` subdirectory as the project root.
