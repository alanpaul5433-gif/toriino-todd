// Backend verification for the /prod API (API Gateway pq8cu94cfd, us-east-1).
//
// For each of the 27 features in docs/audit/backend-verification.md it checks:
//   - the /prod route exists and has the Cognito authorizer (public routes are allow-listed below)
//   - every Lambda behind it has its handler file in the deployed package
//   - required env var NAMES are set (values are never printed)
//   - every DynamoDB table the feature needs exists
//   - live API calls as the .env.test users (Authorization: Bearer <idToken>, like the app)
//   - a few static checks of the Flutter app wiring (lib/)
//   - write tests (enroll, review, FCM token): pass only if the record can be read back.
//     Review/FCM test records are named verify-backend-test-*; the enroll test uses a real
//     free course and removes only the enrollment it created. Everything is restored afterwards.
//
// Aside from those write tests (which clean up after themselves) it changes nothing:
// only AWS describe/list/get calls and GET API calls (+ POST /sessions/token, which
// writes nothing, and an unauthenticated bad-signature POST to the Stripe webhook,
// which must be rejected). Never prints tokens, passwords, signed URLs or env var values.
//
// Verdict per feature:
//   NOT DEPLOYED  required code/route is not deployed
//   BROKEN        deployed but a check fails
//   BLOCKED       the only failures are missing third-party credentials
//                 (Stripe keys, Gemini key, Firebase config, Agora customer ID/secret)
//   WORKS         all checks pass
// Exit code 0 only if every feature is WORKS or BLOCKED.
//
// Requires: AWS CLI v2 configured for account 888245942659, Node 18+, ../.env.test.
// Usage (from toriino-splash/):  node scripts/verify-backend.mjs

import fs from 'fs';
import path from 'path';
import zlib from 'zlib';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REGION = 'us-east-1';
const API_ID = 'pq8cu94cfd';
const STAGE = 'prod';
const BASE = `https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}`;
const USER_POOL = 'us-east-1_CAiea51iC';
const CLIENT_ID = 'jcpvch4o651070m0a2jvuhh22';
const MONOLITH = 'torino-api';

// The only routes allowed to have no authorizer, besides OPTIONS (CORS preflight):
// the Stripe webhook (Stripe calls it; it must verify the Stripe signature instead).
// Sign-up/login go straight to Cognito, so /auth/* must have the Cognito authorizer.
const STRIPE_WEBHOOK_ROUTE = { method: 'POST', path: '/stripe/webhook' }; // per docs/API.md
const PUBLIC_ROUTES = [`${STRIPE_WEBHOOK_ROUTE.method} ${STRIPE_WEBHOOK_ROUTE.path}`];

// Test record names (write tests). Anything carrying these is safe to delete.
const TEST_REVIEW_TARGET = 'verify-backend-test-target';
const TEST_MARKER = 'VERIFY-BACKEND TEST RECORD - safe to delete';
const TEST_FCM_TOKEN = `verify-backend-test-token-${Date.now()}`;

// ── AWS CLI helpers ─────────────────────────────────────────
function aws(args) {
  const out = execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
    encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024,
  });
  return out.trim() ? JSON.parse(out) : null;
}
function awsTry(args) {
  try { return { ok: true, data: aws(args) }; }
  catch (e) { return { ok: false, err: String(e.stderr || e.message).trim().split('\n').pop() }; }
}

let TABLES;
function tableExists(name) {
  if (!TABLES) TABLES = new Set(aws(['dynamodb', 'list-tables']).TableNames);
  return TABLES.has(name);
}
const keySchemas = {};
function keyOf(table, item) {
  keySchemas[table] ??= aws(['dynamodb', 'describe-table', '--table-name', table]).Table.KeySchema;
  return Object.fromEntries(keySchemas[table].map(k => [k.AttributeName, item[k.AttributeName]]));
}
function scanFor(table, attr, value) {
  if (!tableExists(table)) return [];
  return aws(['dynamodb', 'scan', '--table-name', table, '--filter-expression', '#a = :v',
    '--expression-attribute-names', JSON.stringify({ '#a': attr }),
    '--expression-attribute-values', JSON.stringify({ ':v': { S: value } })]).Items || [];
}
function deleteItems(table, items) {
  for (const it of items) aws(['dynamodb', 'delete-item', '--table-name', table, '--key', JSON.stringify(keyOf(table, it))]);
  return items.length;
}

// ── Zip reader (to inspect deployed Lambda packages) ────────
function zipEntries(buf) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('not a zip');
  const count = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16);
  const entries = [];
  for (let n = 0; n < count; n++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) break;
    const method = buf.readUInt16LE(p + 10), csize = buf.readUInt32LE(p + 20);
    const nlen = buf.readUInt16LE(p + 28), elen = buf.readUInt16LE(p + 30), clen = buf.readUInt16LE(p + 32);
    const lho = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + nlen);
    entries.push({
      name,
      read: () => {
        const start = lho + 30 + buf.readUInt16LE(lho + 26) + buf.readUInt16LE(lho + 28);
        const data = buf.subarray(start, start + csize);
        return (method === 8 ? zlib.inflateRawSync(data) : data).toString('utf8');
      },
    });
    p += 46 + nlen + elen + clen;
  }
  return entries;
}

// Download with retries; transient network errors must not look like a broken package.
async function download(url, tries = 4) {
  for (let i = 1; ; i++) {
    try {
      const r = await fetch(url);
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return Buffer.from(await r.arrayBuffer());
    } catch (e) {
      if (i >= tries) throw new Error(`download failed after ${tries} tries: ${e.cause?.code || e.message}`);
      await new Promise(res => setTimeout(res, 1000 * i));
    }
  }
}

const lambdaCache = {};
async function lambdaInfo(name) {
  if (lambdaCache[name]) return lambdaCache[name];
  const r = awsTry(['lambda', 'get-function', '--function-name', name]);
  if (!r.ok) return (lambdaCache[name] = { exists: false });
  const cfg = r.data.Configuration;
  const info = { exists: true, handler: cfg.Handler, env: cfg.Environment?.Variables || {} };
  const [mod] = cfg.Handler.split(/\.(?=[^.]+$)/);
  const wanted = ['.js', '.mjs', '.cjs'].map(ext => mod + ext);
  try {
    const buf = await download(r.data.Code.Location);
    const entries = zipEntries(buf);
    const hit = entries.find(e => wanted.includes(e.name));
    info.handlerFile = hit?.name || null;
    info.source = hit ? hit.read() : '';
    info.backslashEntries = entries.filter(e => e.name.includes('\\')).length;
  } catch (e) { info.handlerFile = null; info.source = ''; info.zipError = e.message; }
  return (lambdaCache[name] = info);
}

// ── Deployed /prod routes ───────────────────────────────────
let ROUTES;
function loadRoutes() {
  const file = path.join(fs.mkdtempSync(path.join(process.env.TEMP || process.env.TMPDIR || '/tmp', 'vb-')), 'prod.json');
  aws(['apigateway', 'get-export', '--rest-api-id', API_ID, '--stage-name', STAGE, '--export-type', 'oas30',
    '--parameters', 'extensions=apigateway', file]);
  const spec = JSON.parse(fs.readFileSync(file, 'utf8'));
  const schemes = spec.components?.securitySchemes || {};
  ROUTES = [];
  for (const [tpl, ops] of Object.entries(spec.paths)) {
    for (const [m, op] of Object.entries(ops)) {
      if (m === 'parameters') continue;
      const method = m === 'x-amazon-apigateway-any-method' ? 'ANY' : m.toUpperCase();
      const sec = Object.keys(op.security?.[0] || {});
      const cognito = sec.some(s => schemes[s]?.['x-amazon-apigateway-authtype'] === 'cognito_user_pools'
        && JSON.stringify(schemes[s]).includes(USER_POOL));
      const uri = op['x-amazon-apigateway-integration']?.uri || '';
      const lambda = (uri.match(/function:([^/:]+)/) || [])[1] || null;
      ROUTES.push({ tpl, method, cognito, lambda });
    }
  }
}
function matchScore(tpl, p) {
  const t = tpl.split('/').filter(Boolean), s = p.split('?')[0].split('/').filter(Boolean);
  const score = [];
  for (let i = 0; i < t.length; i++) {
    if (/^\{.+\+\}$/.test(t[i])) return s.length > i ? [...score, 0] : null;
    if (i >= s.length) return null;
    if (/^\{.+\}$/.test(t[i])) score.push(1);
    else if (t[i] === s[i]) score.push(2);
    else return null;
  }
  return s.length === t.length ? score : null;
}
function cmp(a, b) {
  for (let i = 0; i < Math.max(a.length, b.length); i++) if ((a[i] ?? -1) !== (b[i] ?? -1)) return (a[i] ?? -1) - (b[i] ?? -1);
  return 0;
}
// Resolve the route API Gateway would use for METHOD PATH (most specific resource wins).
function resolveRoute(method, p) {
  let best = null, bestScore = null;
  for (const tpl of new Set(ROUTES.map(r => r.tpl))) {
    const sc = matchScore(tpl, p);
    if (sc && (!bestScore || cmp(sc, bestScore) > 0)) { best = tpl; bestScore = sc; }
  }
  if (!best) return null;
  const onRes = ROUTES.filter(r => r.tpl === best);
  return onRes.find(r => r.method === method) || onRes.find(r => r.method === 'ANY') || { tpl: best, method: null };
}

// ── Live API helpers ────────────────────────────────────────
const env = Object.fromEntries(fs.readFileSync(path.join(ROOT, '.env.test'), 'utf8')
  .split(/\r?\n/).filter(l => /^[A-Z_]+=/.test(l)).map(l => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).trim()]));

async function login(email, password) {
  const r = await fetch(`https://cognito-idp.${REGION}.amazonaws.com/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-amz-json-1.1', 'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth' },
    body: JSON.stringify({ AuthFlow: 'USER_PASSWORD_AUTH', ClientId: CLIENT_ID, AuthParameters: { USERNAME: email, PASSWORD: password } }),
  });
  const j = await r.json();
  if (!j.AuthenticationResult) return { err: `${j.__type}: ${j.message}` };
  const id = j.AuthenticationResult.IdToken;
  const claims = JSON.parse(Buffer.from(id.split('.')[1], 'base64url').toString());
  return { id, sub: claims.sub, role: claims['custom:role'], email };
}

async function api(method, p, user, body) {
  const headers = { 'Content-Type': 'application/json' };
  if (user?.id) headers.Authorization = `Bearer ${user.id}`;
  try {
    const r = await fetch(BASE + p, { method, headers, body: body ? JSON.stringify(body) : undefined });
    const text = await r.text();
    let json = null; try { json = JSON.parse(text); } catch { }
    const msg = json && !Array.isArray(json) ? String(json.message || json.error || '') : '';
    return { status: r.status, json, msg };
  } catch (e) { return { status: 0, json: null, msg: e.message }; }
}

// ── Flutter app static checks ───────────────────────────────
const LIB = {};
(function walk(d) {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const full = path.join(d, f.name);
    if (f.isDirectory()) walk(full);
    else if (f.name.endsWith('.dart')) LIB[path.relative(ROOT, full).replace(/\\/g, '/')] = fs.readFileSync(full, 'utf8');
  }
})(path.join(ROOT, 'lib'));
// Strip // comments so commented-out code doesn't count as a call site.
const code = src => src.split('\n').map(l => l.replace(/^\s*\/\/.*$/, '')).join('\n');
function usedOutside(pattern, ...excludeFiles) {
  return Object.entries(LIB).some(([f, s]) => !excludeFiles.some(x => f.endsWith(x)) && pattern.test(code(s)));
}
function fileContains(rel, pattern) { return LIB[rel] !== undefined && pattern.test(code(LIB[rel])); }

// ── Check context: each feature collects results ────────────
// kind: 'notDeployed' | 'defect' | 'blocker' | 'note'
class Ctx {
  constructor() { this.results = []; }
  pass(msg) { this.results.push({ ok: true, msg }); }
  fail(kind, msg) { this.results.push({ ok: false, kind, msg }); }
  check(cond, kind, okMsg, failMsg) { cond ? this.pass(okMsg) : this.fail(kind, failMsg ?? okMsg); return cond; }

  route(method, p, { lambda, publicOk = false, missingKind = 'notDeployed' } = {}) {
    const r = resolveRoute(method, p);
    const label = `${method} ${p.split('?')[0]}`;
    if (!r || !r.method) return this.fail(missingKind, `route ${label}: no /prod route`), null;
    const via = `${r.method} ${r.tpl} → ${r.lambda || 'no Lambda'}`;
    const isPublic = PUBLIC_ROUTES.includes(`${r.method} ${r.tpl}`);
    if (r.cognito) this.pass(`route ${label} (${via}) has Cognito authorizer`);
    else if (isPublic && publicOk) this.pass(`route ${label} (${via}) is public (allow-listed)`);
    else this.fail('defect', `route ${label} (${via}) has NO authorizer`);
    if (lambda && r.lambda !== lambda) this.fail(missingKind, `route ${label} goes to ${r.lambda}, expected ${lambda}`);
    return r;
  }
  async lambda(name, { missingKind = 'notDeployed' } = {}) {
    const info = await lambdaInfo(name);
    if (!info.exists) return this.fail(missingKind, `Lambda ${name} is not deployed`), info;
    if (info.handlerFile) this.pass(`Lambda ${name}: handler file ${info.handlerFile} present`);
    else if (info.zipError) this.fail('defect', `Lambda ${name}: could not inspect deployed package (${info.zipError})`);
    else this.fail('defect', `Lambda ${name}: handler ${info.handler} has no matching file at the package root`
      + (info.backslashEntries ? ` (${info.backslashEntries} zip entries use backslash paths)` : '')
      + (info.zipError ? ` (${info.zipError})` : ''));
    return info;
  }
  async envVars(name, vars, kind = 'defect') {
    const info = await lambdaInfo(name);
    if (!info.exists) return;
    for (const v of vars) this.check(Boolean(info.env[v]), kind, `Lambda ${name}: env ${v} is set`, `Lambda ${name}: env ${v} is missing or empty`);
  }
  // Credential: set in the Lambda env, or (when the Lambda has SSM_PREFIX) present as an
  // SSM parameter. Values are never read; a NOT_SET placeholder in SSM is caught by the
  // feature's live "not configured" probe instead.
  async secret(name, v, kind = 'blocker') {
    const info = await lambdaInfo(name);
    if (!info.exists) return;
    if (info.env[v]) return this.pass(`Lambda ${name}: env ${v} is set`);
    const prefix = info.env.SSM_PREFIX;
    if (prefix) {
      const r = awsTry(['ssm', 'describe-parameters', '--parameter-filters', `Key=Name,Values=${prefix}${v}`]);
      if (r.ok && r.data.Parameters?.length) return this.pass(`Lambda ${name}: ${v} is an SSM parameter (value not read)`);
      return this.fail(kind, `Lambda ${name}: ${v} is not in the env or in SSM under its SSM_PREFIX`);
    }
    this.fail(kind, `Lambda ${name}: env ${v} is missing or empty`);
  }
  // Env var holding a table name: must be set and the table must exist (value not printed).
  async envTable(name, v) {
    const info = await lambdaInfo(name);
    if (!info.exists) return;
    if (!info.env[v]) return this.fail('defect', `Lambda ${name}: env ${v} is missing or empty`);
    this.check(tableExists(info.env[v]), 'defect', `Lambda ${name}: env ${v} names an existing table`,
      `Lambda ${name}: env ${v} names a table that does not exist`);
  }
  tables(...names) {
    for (const t of names) this.check(tableExists(t), 'defect', `table ${t} exists`, `table ${t} does not exist`);
  }
  live(label, res, ok) {
    const detail = `${res.status}${res.msg ? ` "${res.msg.slice(0, 80)}"` : ''}`;
    if (ok(res)) this.pass(`${label} → ${detail}`);
    else if (res.status === 404 && res.msg === 'Route not found') this.fail('notDeployed', `${label} → ${detail}`);
    else this.fail('defect', `${label} → ${detail}`);
  }
  verdict() {
    const bad = this.results.filter(r => !r.ok && r.kind !== 'note');
    if (bad.some(r => r.kind === 'notDeployed')) return 'NOT DEPLOYED';
    if (bad.some(r => r.kind === 'defect')) return 'BROKEN';
    if (bad.some(r => r.kind === 'blocker')) return 'BLOCKED';
    return 'WORKS';
  }
}

const is2xx = r => r.status >= 200 && r.status < 300;
const not5xx = r => r.status > 0 && r.status < 500 && r.msg !== 'Route not found';
const list = (r, k) => Array.isArray(r.json?.[k]) ? r.json[k] : null;

// ── Write tests (read back, then delete) ────────────────────
// Enrolls the test student in a real FREE course (price 0, not deleted) from the
// table the courses Lambda reads (its COURSES_TABLE), one the student is not
// already enrolled in. Passes only if the enrollment is read back both from the
// table and from GET /courses/my-courses. Cleanup deletes only enrollments the
// test created and undoes the course's `enrollments` counter bump.
async function writeTestEnroll(c, S) {
  const enrollTable = 'toriino-enrollments';
  const coursesTable = (await lambdaInfo('toriino-courses')).env?.COURSES_TABLE;
  if (!coursesTable || !tableExists(coursesTable) || !tableExists(enrollTable))
    return c.fail('defect', 'write test: enroll skipped — courses or enrollments table is missing');
  const mine = courseId => scanFor(enrollTable, 'courseId', courseId)
    .filter(i => [i.userId?.S, i.studentId?.S].includes(S.sub));
  const free = (aws(['dynamodb', 'scan', '--table-name', coursesTable,
    '--filter-expression', 'price = :z AND (attribute_not_exists(#s) OR #s <> :d)',
    '--expression-attribute-names', JSON.stringify({ '#s': 'status' }),
    '--expression-attribute-values', JSON.stringify({ ':z': { N: '0' }, ':d': { S: 'deleted' } })]).Items || [])
    .map(i => i.courseId.S).sort();
  const courseId = free.find(id => mine(id).length === 0);
  if (!courseId) return c.fail('defect', `write test: enroll skipped — no free course the test student is not already enrolled in (${free.length} free)`);

  const ckey = JSON.stringify({ courseId: { S: courseId } });
  const getCourse = () => aws(['dynamodb', 'get-item', '--table-name', coursesTable, '--key', ckey])?.Item;
  const counterBefore = getCourse()?.enrollments;
  try {
    const res = await api('POST', `/courses/${courseId}/enroll`, S);
    const inTable = mine(courseId).length > 0;
    const my = await api('GET', '/courses/my-courses', S);
    const inApi = (list(my, 'courses') || []).some(x => x.courseId === courseId);
    c.check(res.status === 201 && inTable && inApi, 'defect',
      `write test: POST /courses/${courseId}/enroll (free course) → 201, read back from ${enrollTable} and GET /courses/my-courses`,
      `write test: POST /courses/${courseId}/enroll (free course) → ${res.status}${res.msg ? ` "${res.msg}"` : ''}; in ${enrollTable}: ${inTable}, in my-courses: ${inApi}`);
  } finally {
    const created = mine(courseId);
    if (created.length) c.pass(`write test cleanup: deleted ${deleteItems(enrollTable, created)} test enrollment(s)`);
    const counterAfter = getCourse()?.enrollments;
    if (JSON.stringify(counterAfter) !== JSON.stringify(counterBefore)) {
      if (counterBefore) aws(['dynamodb', 'update-item', '--table-name', coursesTable, '--key', ckey,
        '--update-expression', 'ADD enrollments :m', '--expression-attribute-values', JSON.stringify({ ':m': { N: '-1' } })]);
      else aws(['dynamodb', 'update-item', '--table-name', coursesTable, '--key', ckey, '--update-expression', 'REMOVE enrollments']);
      c.pass(`write test cleanup: restored ${courseId} enrollments counter`);
    }
  }
}

async function writeTestReview(c, S) {
  const tables = ['toriino-reviews'];
  const find = () => tables.flatMap(t => scanFor(t, 'targetId', TEST_REVIEW_TARGET).map(i => ({ t, i })));
  for (const { t, i } of find()) deleteItems(t, [i]);
  try {
    const res = await api('POST', '/reviews', S, { targetId: TEST_REVIEW_TARGET, targetType: 'mentor', rating: 5, comment: TEST_MARKER });
    const back = await api('GET', `/reviews/${TEST_REVIEW_TARGET}`, S);
    const seen = (list(back, 'reviews') || []).some(r => r.comment === TEST_MARKER);
    c.check(is2xx(res) && seen, 'defect',
      `write test: POST /reviews → ${res.status}, read back via GET /reviews/${TEST_REVIEW_TARGET}`,
      `write test: POST /reviews → ${res.status}, but GET /reviews/${TEST_REVIEW_TARGET} returned ${back.status} without the test review`);
  } finally {
    const left = find();
    for (const { t, i } of left) deleteItems(t, [i]);
    if (left.length) c.pass(`write test cleanup: deleted ${left.length} test review(s)`);
  }
}

async function writeTestFcm(c, S) {
  // Same body the app sends (lib/services/fcm_service.dart).
  const usersTable = 'torino-users', devicesTable = 'toriino-devices';
  const key = JSON.stringify({ userId: { S: S.sub } });
  const getUser = () => tableExists(usersTable) ? aws(['dynamodb', 'get-item', '--table-name', usersTable, '--key', key])?.Item : undefined;
  const before = getUser();
  try {
    const res = await api('POST', '/notifications/fcm-token', S, { token: TEST_FCM_TOKEN, platform: 'android' });
    const after = getUser();
    const inUsers = after?.fcmToken?.S === TEST_FCM_TOKEN;
    const inDevices = scanFor(devicesTable, 'token', TEST_FCM_TOKEN).length > 0;
    c.check(is2xx(res) && (inUsers || inDevices), 'defect',
      `write test: POST /notifications/fcm-token → ${res.status}, token read back from ${inUsers ? usersTable : devicesTable}`,
      `write test: POST /notifications/fcm-token → ${res.status}, but the token could not be read back`);
  } finally {
    // Restore the student's user record exactly as it was (the Lambda also sets
    // fcmPlatform / fcmUpdatedAt, so restore the whole item, not just fcmToken).
    const after = getUser();
    if (after && !before) {
      aws(['dynamodb', 'delete-item', '--table-name', usersTable, '--key', key]);
      c.pass('write test cleanup: removed user record created by the test');
    } else if (after && JSON.stringify(after) !== JSON.stringify(before)) {
      aws(['dynamodb', 'put-item', '--table-name', usersTable, '--item', JSON.stringify(before)]);
      c.pass('write test cleanup: restored the user record to its previous state');
    }
    const dev = scanFor(devicesTable, 'token', TEST_FCM_TOKEN);
    if (dev.length) c.pass(`write test cleanup: deleted ${deleteItems(devicesTable, dev)} test device row(s)`);
  }
}

// ── Features (same 27 as docs/audit/backend-verification.md) ─
const FEATURES = [
  ['Sign-up / login / OTP (P3-5, P3-6)', async (c, U) => {
    for (const [r, u] of Object.entries(U)) {
      if (u.err) c.fail('defect', `Cognito login ${r.toLowerCase()} failed: ${u.err}`);
      else c.check(u.role === r.toLowerCase(), 'defect', `Cognito login ${r.toLowerCase()} ok, custom:role=${u.role}`);
    }
  }],
  ['Role selection → set-role (P3-3)', async (c, U) => {
    c.route('POST', '/auth/set-role');
    c.live('GET /auth/set-role (route probe)', await api('GET', '/auth/set-role', U.STUDENT), r => r.status !== 404);
  }],
  ['User profile (home screens, profile screen)', async (c, U) => {
    c.route('GET', '/users/profile', { lambda: 'toriino-users' });
    c.route('PUT', '/users/profile', { lambda: 'toriino-users' });
    await c.lambda('toriino-users');
    await c.envTable('toriino-users', 'USERS_TABLE');
    for (const r of ['STUDENT', 'TEACHER', 'MENTOR']) c.live(`GET /users/profile as ${r.toLowerCase()}`, await api('GET', '/users/profile', U[r]), is2xx);
  }],
  ['Profile edit / change password / delete account', async (c) => {
    for (const f of ['lib/view/users/student_view/edit_profile_view.dart', 'lib/view/users/mentor_view/edit_mentor_profile_view.dart', 'lib/view/users/teacher/teacher_profile_edit_view.dart'])
      c.check(fileContains(f, /updateProfile\s*\(/), 'defect', `app: ${f} calls updateProfile()`, `app: ${f} never calls updateProfile() (Save only closes the screen)`);
    c.check(fileContains('lib/view/users/student_view/change_password_view.dart', /changePassword\s*\(/), 'defect',
      'app: change_password_view.dart calls changePassword()', 'app: change_password_view.dart never calls changePassword() (hardcoded success toast)');
    c.check(fileContains('lib/view/users/student_view/settings.dart', /deleteAccount\s*\(/), 'defect',
      'app: settings.dart calls deleteAccount()', 'app: settings.dart Delete Account never calls deleteAccount()');
  }],
  ['Course list + detail (P8-6)', async (c, U) => {
    const r = c.route('GET', '/courses');
    c.route('GET', '/courses/x');
    if (r?.lambda) await c.lambda(r.lambda);
    c.tables('torino-courses');
    const res = await api('GET', '/courses', U.STUDENT);
    c.live('GET /courses', res, x => is2xx(x) && (list(x, 'courses') || []).length > 0);
    const id = list(res, 'courses')?.[0]?.courseId;
    if (id) c.live(`GET /courses/${id}`, await api('GET', `/courses/${id}`, U.STUDENT), is2xx);
    const src = (await lambdaInfo(r?.lambda || MONOLITH)).source || '';
    if (!/lastKey|LastEvaluatedKey/.test(src)) c.fail('note', 'pagination (lastKey) is not in the deployed code');
  }],
  ['Lessons list / add lesson (P8-2, P6-1)', async (c, U) => {
    c.route('GET', '/courses/x/lessons');
    c.route('POST', '/courses/x/lessons');
    c.tables('toriino-lessons');
    const id = list(await api('GET', '/courses', U.STUDENT), 'courses')?.[0]?.courseId || 'x';
    c.live(`GET /courses/${id}/lessons`, await api('GET', `/courses/${id}/lessons`, U.STUDENT), is2xx);
  }],
  ['Course upload URL (P6-1)', async (c, U) => {
    c.route('GET', '/courses/upload-url');
    c.live('GET /courses/upload-url', await api('GET', '/courses/upload-url?fileName=verify.png&contentType=image/png', U.TEACHER),
      r => is2xx(r) && typeof r.json?.uploadUrl === 'string');
  }],
  ['Course delete cascade + enrollment guard (P6-3)', async (c) => {
    const r = c.route('DELETE', '/courses/x');
    c.tables('torino-courses', 'toriino-lessons', 'toriino-enrollments');
    const src = r?.lambda ? (await lambdaInfo(r.lambda)).source || '' : '';
    c.check(src.includes('Cannot delete a course with enrolled students'), 'notDeployed',
      `deployed ${r?.lambda} has the enrollment guard`, `enrollment guard / lesson cascade is not in the deployed ${r?.lambda} code (DELETE not called)`);
  }],
  ['Enroll + My Courses (P5-1)', async (c, U) => {
    c.route('POST', '/courses/x/enroll');
    c.route('GET', '/courses/my-courses');
    c.tables('toriino-enrollments');
    c.live('GET /courses/my-courses', await api('GET', '/courses/my-courses', U.STUDENT), r => is2xx(r) && list(r, 'courses'));
    await writeTestEnroll(c, U.STUDENT);
  }],
  ['Stripe payment intent (P5-1/2/3)', async (c, U) => {
    const r = c.route('POST', '/payments/create-intent');
    if (r?.lambda) { await c.lambda(r.lambda); await c.secret(r.lambda, 'STRIPE_SECRET_KEY'); }
    // Empty body: no type and no amount, so no PaymentIntent can be created. Expect
    // 400 (validation, Stripe configured) or 503 "Stripe not configured".
    const res = await api('POST', '/payments/create-intent', U.STUDENT, {});
    const label = 'POST /payments/create-intent with an empty body';
    if (res.status === 503 && /Stripe not configured/i.test(res.msg)) c.fail('blocker', `${label} → 503 "${res.msg}"`);
    else c.live(label, res, x => x.status === 400);
  }],
  ['Stripe webhook (P1-3)', async (c) => {
    const names = ['stripe-webhook', 'toriino-stripe-webhook'];
    const found = [];
    for (const n of names) if ((await lambdaInfo(n)).exists) found.push(n);
    if (!found.length) c.fail('notDeployed', `Lambda stripe-webhook is not deployed (looked for ${names.join(', ')})`);
    else { await c.lambda(found[0]); for (const v of ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET']) await c.secret(found[0], v); }
    const { method: wm, path: wp } = STRIPE_WEBHOOK_ROUTE;
    const r = resolveRoute(wm, wp);
    if (!r || !r.method || r.tpl !== wp) {
      c.fail('notDeployed', `no ${wm} ${wp} route on /prod${r?.method ? ` (falls through to ${r.method} ${r.tpl} → ${r.lambda})` : ''}`);
    } else {
      c.route(wm, wp, { publicOk: true });
      if (r.cognito) c.fail('defect', `${wm} ${wp} has a Cognito authorizer — Stripe cannot send a Cognito token`);
    }
    // Unauthenticated request with a bad signature, as an attacker would send it.
    // Must be rejected: 400 (bad signature), or 503 "not configured" while Stripe keys are empty.
    const res = await fetch(BASE + wp, {
      method: wm,
      headers: { 'Content-Type': 'application/json', 'Stripe-Signature': 't=0,v1=verify-backend-bad-signature' },
      body: JSON.stringify({ id: 'evt_verify_backend_bad_sig', type: 'payment_intent.succeeded' }),
    }).then(async x => { const t = await x.text(); let j = null; try { j = JSON.parse(t); } catch { } return { status: x.status, msg: String(j?.message || j?.error || '') }; })
      .catch(e => ({ status: 0, msg: e.message }));
    const detail = `${res.status}${res.msg ? ` "${res.msg.slice(0, 80)}"` : ''}`;
    const label = `${wm} ${wp} with a bad Stripe-Signature, no auth`;
    if (res.status === 400) c.pass(`${label} → ${detail} (rejected)`);
    else if (res.status === 503 && /not configured/i.test(res.msg)) c.fail('blocker', `${label} → ${detail} (Stripe keys not set)`);
    else c.fail(r?.tpl === wp ? 'defect' : 'notDeployed', `${label} → ${detail}; expected 400, or 503 "not configured"`);
    c.tables('toriino-stripe-events');
  }],
  ['General uploads / S3Service (P2-2)', async (c, U) => {
    c.live('GET /upload-url (route probe)', await api('GET', '/upload-url', U.STUDENT), r => r.msg !== 'Route not found' && r.status !== 404);
    if (!(await lambdaInfo('toriino-upload-url')).exists && !(await lambdaInfo('upload-url')).exists) c.fail('notDeployed', 'Lambda upload-url is not deployed');
    const pab = awsTry(['s3api', 'get-public-access-block', '--bucket', 'torino-app-storage']);
    const cfg = pab.data?.PublicAccessBlockConfiguration || {};
    c.check(pab.ok && Object.values(cfg).length === 4 && Object.values(cfg).every(Boolean), 'defect',
      'S3 torino-app-storage: all 4 public-access-block settings on', 'S3 torino-app-storage: public access block is not fully on');
    if (!usedOutside(/S3Service\./, 'services/s3_service.dart')) c.fail('note', 'app: S3Service is never called');
  }],
  ['Mentor list / detail', async (c, U) => {
    c.route('GET', '/mentors');
    c.route('GET', '/mentors/x');
    c.tables('torino-mentors');
    const res = await api('GET', '/mentors', U.STUDENT);
    c.live('GET /mentors', res, x => is2xx(x) && (list(x, 'mentors') || []).length > 0);
    const m = list(res, 'mentors')?.[0];
    const id = m?.mentorId || m?.userId;
    if (id) c.live(`GET /mentors/${id}`, await api('GET', `/mentors/${id}`, U.STUDENT), is2xx);
  }],
  ['Mentor availability (P7-1)', async (c, U) => {
    c.route('GET', '/mentors/x/availability');
    c.route('PUT', '/mentors/availability');
    c.tables('torino-mentors');
    c.live('GET /mentors/{mentor}/availability', await api('GET', `/mentors/${U.MENTOR.sub}/availability`, U.MENTOR), is2xx);
    c.check(usedOutside(/MentorAvailability\s*\(/, 'mentor_view/mentor_availability.dart'), 'defect',
      'app: MentorAvailability screen is opened from somewhere', 'app: MentorAvailability screen is never opened (unreachable)');
  }],
  ['Sessions list (P7-2)', async (c, U) => {
    c.route('GET', '/sessions');
    c.tables('torino-sessions');
    for (const r of ['STUDENT', 'TEACHER', 'MENTOR']) {
      const res = await api('GET', `/sessions?role=${r.toLowerCase()}`, U[r]);
      const items = list(res, 'sessions');
      if (!is2xx(res) || !items) { c.live(`GET /sessions?role=${r.toLowerCase()}`, res, () => false); continue; }
      const foreign = items.filter(s => ![s.studentId, s.mentorId, s.teacherId].includes(U[r].sub)).length;
      c.check(foreign === 0, 'defect', `GET /sessions?role=${r.toLowerCase()} → ${items.length} session(s), all the caller's`,
        `GET /sessions?role=${r.toLowerCase()} → ${foreign} of ${items.length} sessions belong to other users (data leak)`);
    }
  }],
  ['Live-session Agora token', async (c, U) => {
    c.route('POST', '/sessions/token');
    await c.envVars(MONOLITH, ['AGORA_APP_ID', 'AGORA_APP_CERTIFICATE']);
    c.live('POST /sessions/token', await api('POST', '/sessions/token', U.STUDENT, { channelName: 'verify-backend-probe', uid: 0 }),
      r => is2xx(r) && typeof r.json?.token === 'string');
  }],
  ['Session recording', async (c, U) => {
    for (const [m, p] of [['GET', '/sessions/x/recording'], ['POST', '/sessions/x/recording/start'], ['POST', '/sessions/x/recording/stop']])
      c.route(m, p, { lambda: 'toriino-agora-recording' });
    await c.lambda('toriino-agora-recording');
    await c.envVars('toriino-agora-recording', ['AGORA_APP_ID', 'AGORA_APP_CERTIFICATE', 'RECORDING_TABLE', 'RECORDING_S3_BUCKET']);
    for (const v of ['AGORA_CUSTOMER_ID', 'AGORA_CUSTOMER_SECRET']) await c.secret('toriino-agora-recording', v);
    c.tables('toriino-recordings');
    c.live('GET /sessions/{none}/recording', await api('GET', '/sessions/verify-backend-none/recording', U.STUDENT), not5xx);
  }],
  ['Transcript / summary', async (c, U) => {
    c.route('GET', '/sessions/x/transcript', { lambda: 'toriino-ai-transcripts' });
    c.route('GET', '/sessions/x/summary', { lambda: 'toriino-ai-summaries' });
    for (const l of ['toriino-ai-transcripts', 'toriino-ai-summaries', 'toriino-transcribe-processor']) await c.lambda(l);
    for (const l of ['toriino-ai-summaries', 'toriino-transcribe-processor']) await c.secret(l, 'GEMINI_API_KEY');
    c.tables('toriino-transcripts', 'toriino-session-summaries');
    c.live('GET /sessions/{none}/transcript', await api('GET', '/sessions/verify-backend-none/transcript', U.STUDENT), not5xx);
    c.live('GET /sessions/{none}/summary', await api('GET', '/sessions/verify-backend-none/summary', U.STUDENT), not5xx);
    c.check(usedOutside(/\.addSegment\s*\(/, 'services/session_intelligence_service.dart'), 'defect',
      'app: transcript segments are recorded (addSegment called)', 'app: addSegment() is never called, so the summary screen never opens');
  }],
  ['AI Tutor chat (P2-1)', async (c, U) => {
    c.route('GET', '/ai/chat/x', { lambda: 'toriino-ai-chat' });
    c.route('POST', '/ai/chat/x', { lambda: 'toriino-ai-chat' });
    await c.lambda('toriino-ai-chat');
    await c.secret('toriino-ai-chat', 'GEMINI_API_KEY');
    c.tables('toriino-ai-chat');
    c.live('GET /ai/chat/{self}', await api('GET', `/ai/chat/${U.STUDENT.sub}`, U.STUDENT), is2xx);
    c.live("GET /ai/chat/{other user} (expect 403)", await api('GET', `/ai/chat/${U.TEACHER.sub}`, U.STUDENT), r => r.status === 403);
  }],
  ['AI Twins / Memory', async (c, U) => {
    c.route('GET', '/ai/twins/x', { lambda: 'toriino-ai-twins' });
    c.route('GET', '/ai/memory/x', { lambda: 'toriino-ai-memory' });
    for (const l of ['toriino-ai-twins', 'toriino-ai-memory']) { await c.lambda(l); await c.secret(l, 'GEMINI_API_KEY'); }
    c.tables('toriino-ai-twins', 'toriino-ai-memory', 'toriino-knowledge-graph');
    c.live('GET /ai/twins/{self}', await api('GET', `/ai/twins/${U.STUDENT.sub}`, U.STUDENT), not5xx);
    c.live('GET /ai/memory/{self}', await api('GET', `/ai/memory/${U.STUDENT.sub}`, U.STUDENT), is2xx);
    c.live('GET /ai/memory/{self}/graph', await api('GET', `/ai/memory/${U.STUDENT.sub}/graph`, U.STUDENT), is2xx);
    if (!usedOutside(/AiTwinService\s*\(/, 'services/ai_twin_service.dart')) c.fail('note', 'app: no screen uses AI Twins / Memory');
  }],
  ['Wallet (P5-3)', async (c, U) => {
    c.route('GET', '/wallet', { lambda: 'toriino-wallet' });
    c.route('POST', '/wallet/deduct', { lambda: 'toriino-wallet' });
    await c.lambda('toriino-wallet');
    await c.envTable('toriino-wallet', 'WALLET_TABLE');
    await c.envTable('toriino-wallet', 'WALLET_EVENTS_TABLE');
    for (const r of ['STUDENT', 'MENTOR']) c.live(`GET /wallet as ${r.toLowerCase()}`, await api('GET', '/wallet', U[r]), x => is2xx(x) && typeof x.json?.balance === 'number');
    if (!usedOutside(/\.getBalance\s*\(/, 'repository/wallet_repo.dart')) c.fail('note', 'app: GET /wallet is never called (balance comes from earnings)');
  }],
  ['Student search (P7-2)', async (c, U) => {
    c.route('GET', '/students/search', { lambda: 'toriino-student-search' });
    await c.lambda('toriino-student-search');
    await c.envTable('toriino-student-search', 'USERS_TABLE');
    c.live('GET /students/search?q=st as mentor', await api('GET', '/students/search?q=st', U.MENTOR), is2xx);
  }],
  ['Earnings (P5-4)', async (c, U) => {
    c.route('GET', '/earnings');
    c.route('GET', '/earnings/history');
    c.tables('torino-earnings');
    for (const r of ['TEACHER', 'MENTOR']) {
      const res = await api('GET', '/earnings', U[r]);
      c.live(`GET /earnings as ${r.toLowerCase()}`, res, is2xx);
      if (is2xx(res)) for (const f of ['totalWithdrawn', 'availableBalance'])
        c.check(f in (res.json || {}), 'defect', `GET /earnings returns ${f}`, `GET /earnings response has no ${f} field`);
    }
    c.live('GET /earnings/history', await api('GET', '/earnings/history', U.TEACHER), r => is2xx(r) && list(r, 'history'));
  }],
  ['Notifications (P8-4)', async (c, U) => {
    const r = c.route('GET', '/notifications');
    c.route('PATCH', '/notifications/x/read');
    c.tables('toriino-notifications');
    c.live('GET /notifications', await api('GET', '/notifications', U.STUDENT), x => is2xx(x) && list(x, 'notifications'));
    const src = r?.lambda ? (await lambdaInfo(r.lambda)).source || '' : '';
    c.check(/["']read["']/.test(src), 'defect', `deployed ${r?.lambda} handles PATCH /notifications/{sk}/read`,
      `deployed ${r?.lambda} has no handler for PATCH /notifications/{sk}/read`);
  }],
  ['FCM token registration (P9-1)', async (c, U) => {
    c.route('POST', '/notifications/fcm-token');
    c.tables('torino-users', 'toriino-devices');
    c.check(fs.existsSync(path.join(ROOT, 'android/app/google-services.json')), 'blocker',
      'android/app/google-services.json present', 'android/app/google-services.json missing (no Firebase config)');
    await writeTestFcm(c, U.STUDENT);
  }],
  ['Reviews + one-per-student rule (P2-5)', async (c, U) => {
    const r = c.route('POST', '/reviews');
    c.route('GET', '/reviews/x');
    c.tables('toriino-reviews');
    const src = r?.lambda ? (await lambdaInfo(r.lambda)).source || '' : '';
    c.check(src.includes('already submitted a review'), 'defect', `deployed ${r?.lambda} has the one-review-per-student guard`,
      `deployed ${r?.lambda} has no one-review-per-student guard`);
    await writeTestReview(c, U.STUDENT);
  }],
  ['Admin panel (P10-7, P1-2)', async (c, U) => {
    const eps = ['stats', 'users', 'courses', 'sessions', 'mentors', 'earnings', 'reviews', 'ai/stats'];
    for (const e of eps) c.route('GET', `/admin/${e}`, { lambda: 'toriino-admin' });
    await c.lambda('toriino-admin');
    c.tables('torino-users', 'torino-courses', 'torino-sessions', 'torino-mentors', 'toriino-reviews', 'toriino-notifications', 'toriino-session-summaries');
    const g = awsTry(['cognito-idp', 'admin-list-groups-for-user', '--user-pool-id', USER_POOL, '--username', U.ADMIN.email]);
    c.check(g.ok && g.data.Groups.some(x => x.GroupName === 'Admins'), 'defect', 'test admin is in the Admins group', 'test admin is NOT in the Admins Cognito group');
    for (const e of eps) c.live(`GET /admin/${e} as admin`, await api('GET', `/admin/${e}`, U.ADMIN), is2xx);
    c.live('GET /admin/stats as student (expect 403)', await api('GET', '/admin/stats', U.STUDENT), r => r.status === 403);
  }],
];

// ── Run ─────────────────────────────────────────────────────
console.log(`Backend verification — ${BASE} — ${new Date().toISOString()}\n`);
loadRoutes();
const U = {};
for (const r of ['STUDENT', 'TEACHER', 'MENTOR', 'ADMIN']) U[r] = await login(env[`TEST_${r}_EMAIL`], env[`TEST_${r}_PASSWORD`]);

const totals = { WORKS: 0, BROKEN: 0, 'NOT DEPLOYED': 0, BLOCKED: 0 };
const summary = [];
for (const [i, [name, fn]] of FEATURES.entries()) {
  const c = new Ctx();
  try { await fn(c, U); } catch (e) { c.fail('defect', `check crashed: ${e.message}`); }
  const v = c.verdict();
  totals[v]++;
  summary.push([i + 1, name, v]);
  console.log(`${String(i + 1).padStart(2)}. [${v}] ${name}`);
  for (const r of c.results) console.log(`      ${r.ok ? 'ok  ' : r.kind === 'note' ? 'note' : 'FAIL'} ${r.ok ? '' : `(${r.kind}) `}${r.msg}`);
  console.log();
}

console.log('Summary');
for (const [n, name, v] of summary) console.log(`  ${String(n).padStart(2)}. ${v.padEnd(12)} ${name}`);
console.log(`\nTOTAL: ${totals.WORKS} WORKS · ${totals.BROKEN} BROKEN · ${totals['NOT DEPLOYED']} NOT DEPLOYED · ${totals.BLOCKED} BLOCKED  (of ${FEATURES.length})`);
const pass = totals.BROKEN === 0 && totals['NOT DEPLOYED'] === 0;
console.log(pass ? 'RESULT: PASS (every feature WORKS or BLOCKED)' : 'RESULT: FAIL');
process.exitCode = pass ? 0 : 1;
