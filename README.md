# Torino Todd

A Flutter-based learning platform connecting students, teachers, and mentors.

## Prerequisites

- Flutter 3.x
- Dart 3.x
- Android SDK 34+
- Node.js 20+ (for Lambda development)

## Setup

### 1. Clone and install

```bash
flutter pub get
```

### 2. Configure environment

Copy `android/app/google-services.json.example` to `android/app/google-services.json` and fill in real values from Firebase console.

Required `--dart-define` values at build time:

| Key | Description |
|-----|-------------|
| `API_BASE_URL` | AWS API Gateway /prod base URL |
| `GEMINI_API_KEY` | Google AI Studio key (Lambda env preferred) |
| `AGORA_APP_ID` | Agora.io app ID |
| `STRIPE_PK` | Stripe publishable key (`pk_test_` for dev) |

### 3. Run (development)

```powershell
.\tool\run_dev.ps1
```

### 4. Build release APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod \
  --dart-define=AGORA_APP_ID=<your-agora-app-id>
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## API reference

See [docs/API.md](docs/API.md).

## Deployment

See [docs/RUNBOOK.md](docs/RUNBOOK.md).
