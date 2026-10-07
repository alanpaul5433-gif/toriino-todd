/**
 * upload-url Lambda — pre-signed S3 PUT URLs  (Cognito authorizer)
 *
 *   GET /upload-url?folder=&contentType=&ext=
 *       folder: profiles | courses/thumbnails | intro-videos   (public, served by CloudFront)
 *             | lessons | course-materials                    (private)
 *       → { uploadUrl, key, expiresIn, publicUrl? }
 *   GET /courses/upload-url?fileName=&contentType=&courseId=     (older app builds)
 *       → same; stored under course-materials/ (private, so no publicUrl)
 *
 * The bucket stays private. Public folders are readable only through the CloudFront
 * distribution (Origin Access Control), so `publicUrl` is a CloudFront URL. Private
 * objects (paid lesson videos, course materials) get no URL here: the courses Lambda
 * issues a short-lived pre-signed GET after checking enrollment.
 *
 * Keys are always scoped to the caller's Cognito sub, so a user can only write
 * under their own prefix. No AWS credentials ever reach the app.
 *
 * Env: S3_BUCKET, CDN_BASE (https://<distribution>.cloudfront.net), URL_EXPIRY (seconds, default 300)
 */
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { randomUUID } = require('crypto');

const REGION = process.env.AWS_REGION || 'us-east-1';
const BUCKET = process.env.S3_BUCKET;
const CDN_BASE = process.env.CDN_BASE || '';
const URL_EXPIRY = parseInt(process.env.URL_EXPIRY || '300', 10);

const s3 = new S3Client({ region: REGION });

const PUBLIC_FOLDERS = new Set(['profiles', 'courses/thumbnails', 'intro-videos']);
const ALLOWED_FOLDERS = new Set([...PUBLIC_FOLDERS, 'lessons', 'course-materials']);
const ALLOWED_TYPES = new Set([
  'image/jpeg', 'image/png', 'image/gif', 'image/webp',
  'video/mp4', 'video/quicktime', 'video/webm',
  'application/pdf', 'text/plain',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
]);

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

const clean = (s, max) => String(s).replace(/[^a-zA-Z0-9]/g, '').slice(0, max);

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});
  if (event.httpMethod !== 'GET') return res(404, { error: 'Route not found' });

  const userId = event.requestContext?.authorizer?.claims?.sub;
  if (!userId) return res(401, { error: 'Unauthorized' });
  if (!BUCKET || !CDN_BASE) return res(503, { error: 'Uploads not configured (S3_BUCKET / CDN_BASE)' });

  const qs = event.queryStringParameters || {};
  const legacy = event.path === '/courses/upload-url';

  let folder = qs.folder;
  let ext = qs.ext;
  const contentType = qs.contentType;
  if (legacy) {
    if (!qs.fileName || !contentType) return res(400, { error: 'fileName and contentType are required' });
    folder = 'course-materials';
    ext = String(qs.fileName).includes('.') ? String(qs.fileName).split('.').pop() : '';
  }

  if (!folder || !contentType || !ext) return res(400, { error: 'folder, contentType, and ext are required' });
  if (!ALLOWED_FOLDERS.has(folder)) {
    return res(400, { error: `folder must be one of: ${[...ALLOWED_FOLDERS].join(', ')}` });
  }
  if (!ALLOWED_TYPES.has(contentType)) return res(400, { error: `contentType ${contentType} is not allowed` });
  const safeExt = clean(ext, 10);
  if (!safeExt) return res(400, { error: 'ext is invalid' });

  const scope = legacy && qs.courseId ? `${userId}/${clean(qs.courseId, 64)}` : userId;
  const key = `${folder}/${scope}/${randomUUID()}.${safeExt}`;

  try {
    const uploadUrl = await getSignedUrl(
      s3,
      new PutObjectCommand({ Bucket: BUCKET, Key: key, ContentType: contentType }),
      { expiresIn: URL_EXPIRY },
    );
    const body = { uploadUrl, key, expiresIn: URL_EXPIRY };
    if (PUBLIC_FOLDERS.has(folder)) body.publicUrl = body.url = `${CDN_BASE}/${key}`;
    return res(200, body);
  } catch (err) {
    console.error(JSON.stringify({ level: 'ERROR', message: 'pre-sign failed', error: err.message }));
    return res(500, { error: 'Failed to generate upload URL' });
  }
};
