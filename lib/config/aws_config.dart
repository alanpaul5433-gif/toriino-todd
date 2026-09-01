class AWSConfig {
  // ── Cognito ──────────────────────────────────────────
  static const String userPoolId = 'us-east-1_CAiea51iC';
  static const String clientId = 'jcpvch4o651070m0a2jvuhh22';
  static const String region = 'us-east-1';

  // ── S3 Storage ───────────────────────────────────────
  static const String s3Bucket = 'torino-app-storage';
  static const String s3Region = 'us-east-1';

  // ── API Gateway ──────────────────────────────────────
  static const String apiEndpoint =
      'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/dev';

  // ── Cognito Pool URL ─────────────────────────────────
  static String get cognitoPoolUrl =>
      'https://cognito-idp.$region.amazonaws.com/$userPoolId';
}
