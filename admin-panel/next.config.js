/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',   // static export for S3/CloudFront hosting
  trailingSlash: true,
  images: { unoptimized: true },
  env: {
    NEXT_PUBLIC_API_BASE: process.env.NEXT_PUBLIC_API_BASE || 'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod',
    NEXT_PUBLIC_COGNITO_REGION: process.env.NEXT_PUBLIC_COGNITO_REGION || 'us-east-1',
    NEXT_PUBLIC_COGNITO_USER_POOL_ID: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID || 'us-east-1_CAiea51iC',
    NEXT_PUBLIC_COGNITO_CLIENT_ID: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID || 'jcpvch4o651070m0a2jvuhh22',
  },
};

module.exports = nextConfig;
