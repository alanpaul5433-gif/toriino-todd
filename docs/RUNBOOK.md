# Runbook

## Deploy a Lambda

1. Edit files in `aws-backend/lambda/<name>/index.js`
2. Zip and upload:
   ```bash
   cd aws-backend/lambda/<name>
   zip -r function.zip .
   aws lambda update-function-code --function-name torino-<name> --zip-file fileb://function.zip
   ```
3. Verify in CloudWatch Logs.

## Release an APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod \
  --dart-define=GEMINI_API_KEY=<key> \
  --dart-define=AGORA_APP_ID=<id> \
  --dart-define=STRIPE_PK=<pk_live_key>
```

Sign with `android/key.properties` (gitignored). Upload to Play Console.

## Rotate the Gemini API key

1. Go to aistudio.google.com → API keys → revoke old key.
2. Create new key.
3. Update `GEMINI_API_KEY` in Lambda env (ai-chat Lambda).
4. Update `--dart-define=GEMINI_API_KEY=<newkey>` in your build script.
5. Do NOT commit the key to source control.

## Rotate the Stripe webhook secret

1. Stripe Dashboard → Webhooks → endpoint → Reveal signing secret.
2. Update `STRIPE_WEBHOOK_SECRET` in stripe-webhook Lambda env.

## Rollback a Lambda

```bash
aws lambda list-versions-by-function --function-name torino-<name>
aws lambda update-alias --function-name torino-<name> --name live --function-version <prev-version>
```

## Emergency: disable payments

Set `STRIPE_SECRET_KEY` to an invalid value in the payments Lambda env. The Lambda will return 500 and no charges will be attempted.
