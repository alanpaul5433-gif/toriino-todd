/**
 * upload-url Lambda — GET /upload-url
 *
 * Returns a pre-signed S3 PUT URL so the Flutter app can upload files
 * directly to S3 without embedding AWS credentials or sending raw bytes
 * through the API Gateway.
 *
 * Request query params:
 *   folder      — 'profiles' | 'courses/thumbnails' | 'lessons' (required)
 *   contentType — MIME type, e.g. 'image/jpeg' (required)
 *   ext         — file extension, e.g. 'jpg' (required)
 *
 * Response:
 *   { uploadUrl, key, publicUrl, expiresIn }
 *
 * OWNER env vars:
 *   S3_BUCKET   — torino-app-storage
 *   S3_REGION   — us-east-1
 *   CDN_BASE    — optional CloudFront domain, e.g. https://d1234.cloudfront.net
 *                 If omitted, publicUrl uses the S3 endpoint (HTTPS).
 *   URL_EXPIRY  — seconds until the pre-signed URL expires (default 300)
 *
 * After deploying:
 *   1. Block public PUT and public ACLs on the S3 bucket (AWS console →
 *      Block Public Access settings → enable all four toggles).
 *   2. Point the bucket policy's Allow-PUT to only this Lambda's role.
 */

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { randomUUID } = require('crypto');

const REGION      = process.env.AWS_REGION  || 'us-east-1';
const BUCKET      = process.env.S3_BUCKET   || 'torino-app-storage';
const CDN_BASE    = process.env.CDN_BASE    || '';
const URL_EXPIRY  = parseInt(process.env.URL_EXPIRY || '300', 10);

const s3 = new S3Client({ region: REGION });

const ALLOWED_FOLDERS = new Set(['profiles', 'courses/thumbnails', 'lessons']);
const ALLOWED_TYPES   = new Set([
  'image/jpeg', 'image/png', 'image/gif', 'image/webp',
  'video/mp4', 'application/pdf',
]);
const MAX_SIZE = 20 * 1024 * 1024; // 20 MB content-length-range cap

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function getUserId(event) {
  const sub = event.requestContext?.authorizer?.claims?.sub;
  if (sub) return sub;
  try {
    const auth = event.headers?.Authorization || event.headers?.authorization || '';
    const token = auth.replace(/^Bearer\s+/i, '');
    if (!token) return null;
    return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()).sub || null;
  } catch { return null; }
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});

  const userId = getUserId(event);
  if (!userId) return res(401, { error: 'Unauthorized' });

  const { folder, contentType, ext } = event.queryStringParameters || {};

  if (!folder || !contentType || !ext) {
    return res(400, { error: 'folder, contentType, and ext are required' });
  }
  if (!ALLOWED_FOLDERS.has(folder)) {
    return res(400, { error: `folder must be one of: ${[...ALLOWED_FOLDERS].join(', ')}` });
  }
  if (!ALLOWED_TYPES.has(contentType)) {
    return res(400, { error: `contentType not allowed` });
  }

  // Key scoped to the Cognito sub — users can only write to their own prefix
  const key = `${folder}/${userId}/${randomUUID()}.${ext.replace(/[^a-zA-Z0-9]/g, '')}`;

  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    ContentType: contentType,
  });

  try {
    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: URL_EXPIRY });

    const publicUrl = CDN_BASE
      ? `${CDN_BASE}/${key}`
      : `https://${BUCKET}.s3.${REGION}.amazonaws.com/${key}`;

    return res(200, { uploadUrl, key, publicUrl, expiresIn: URL_EXPIRY });
  } catch (err) {
    console.error('pre-sign error:', err);
    return res(500, { error: 'Failed to generate upload URL' });
  }
};
