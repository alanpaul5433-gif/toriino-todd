// Creates (once) the paid test course and its test lesson the backend checker uses to
// prove the lesson-media gate: an unenrolled student gets 402, an enrolled student or
// the owner gets a 5-minute pre-signed link.
//
//   course  "verify-test-course-paid"  $9.99, status "draft" (not in the public catalog),
//           owned by the .env.test teacher
//   lesson  "verify-test-lesson"       video scripts/fixtures/verify-test-lesson.mp4
//
// Everything goes through the real API as the test teacher (POST /courses, GET /upload-url,
// PUT to S3, POST /courses/{id}/lessons). Idempotent: existing course/lesson are reused.
// Prints IDs only — never tokens or signed URLs.
//
// Usage (from toriino-splash/): node scripts/seed-verify-test-lesson.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const BASE = 'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod';
const CLIENT_ID = 'jcpvch4o651070m0a2jvuhh22';
const COURSE_TITLE = 'verify-test-course-paid';
const LESSON_TITLE = 'verify-test-lesson';
const VIDEO = path.join(ROOT, 'scripts', 'fixtures', 'verify-test-lesson.mp4');

const env = Object.fromEntries(fs.readFileSync(path.join(ROOT, '.env.test'), 'utf8')
  .split(/\r?\n/).filter((l) => /^[A-Z_]+=/.test(l)).map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).trim()]));

async function login(role) {
  const r = await fetch('https://cognito-idp.us-east-1.amazonaws.com/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-amz-json-1.1', 'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth' },
    body: JSON.stringify({ AuthFlow: 'USER_PASSWORD_AUTH', ClientId: CLIENT_ID,
      AuthParameters: { USERNAME: env[`TEST_${role}_EMAIL`], PASSWORD: env[`TEST_${role}_PASSWORD`] } }),
  });
  const j = await r.json();
  if (!j.AuthenticationResult) throw new Error(`login ${role} failed: ${j.__type}`);
  return j.AuthenticationResult.IdToken;
}

async function api(token, method, p, body) {
  const r = await fetch(BASE + p, {
    method, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  let json = null; try { json = JSON.parse(text); } catch { }
  return { status: r.status, json };
}
function must(res, what, ok = (s) => s >= 200 && s < 300) {
  if (!ok(res.status)) throw new Error(`${what} → ${res.status} ${JSON.stringify(res.json)}`);
  return res.json;
}

const teacher = await login('TEACHER');

// 1. Course (draft, paid, owned by the test teacher)
const mine = must(await api(teacher, 'GET', '/courses/my-created'), 'GET /courses/my-created').courses || [];
let course = mine.find((c) => c.title === COURSE_TITLE);
if (course) {
  console.log(`course exists: ${course.courseId} (status ${course.status}, price ${course.price})`);
} else {
  course = must(await api(teacher, 'POST', '/courses', {
    title: COURSE_TITLE,
    description: '[TEST] Do not enroll. Backend verification fixture for the paid lesson-media gate.',
    category: 'Testing', price: 9.99, status: 'draft', level: 'Beginner',
  }), 'POST /courses');
  console.log(`course created: ${course.courseId}`);
}
const courseId = course.courseId;

// 2. Lesson with a private video uploaded through /upload-url
const lessons = must(await api(teacher, 'GET', `/courses/${courseId}/lessons`), 'GET lessons').lessons || [];
let lesson = lessons.find((l) => l.title === LESSON_TITLE);
if (lesson) {
  console.log(`lesson exists: ${lesson.lessonId} (videoKey under ${String(lesson.videoKey).split('/')[0]}/)`);
} else {
  const up = must(await api(teacher, 'GET', '/upload-url?folder=lessons&contentType=video/mp4&ext=mp4'), 'GET /upload-url');
  if (up.publicUrl) throw new Error('lessons/ upload unexpectedly returned a public URL');
  const put = await fetch(up.uploadUrl, { method: 'PUT', headers: { 'Content-Type': 'video/mp4' }, body: fs.readFileSync(VIDEO) });
  if (!put.ok) throw new Error(`S3 PUT → ${put.status}`);
  lesson = must(await api(teacher, 'POST', `/courses/${courseId}/lessons`, {
    title: LESSON_TITLE, description: '[TEST] 2-second test video', videoKey: up.key, duration: '0:02', order: 1, type: 'video',
  }), 'POST lesson');
  console.log(`lesson created: ${lesson.lessonId}`);
}

// 3. Prove the gate
const owner = await api(teacher, 'GET', `/courses/${courseId}/lessons/${lesson.lessonId}/media`);
console.log(`owner media → ${owner.status}${owner.json?.videoUrl ? `, signed URL issued, expiresIn ${owner.json.expiresIn}s` : ''}`);
const student = await api(await login('STUDENT'), 'GET', `/courses/${courseId}/lessons/${lesson.lessonId}/media`);
console.log(`unenrolled student media → ${student.status} ${student.json?.error || ''}`);
if (owner.status !== 200 || owner.json?.expiresIn !== 300 || student.status !== 402) process.exitCode = 1;
console.log(`\nCOURSE_ID=${courseId}\nLESSON_ID=${lesson.lessonId}`);
