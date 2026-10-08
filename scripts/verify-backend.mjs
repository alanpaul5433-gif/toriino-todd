// Backend verification for the /prod API (API Gateway pq8cu94cfd, us-east-1).
//
// For each of the 27 features in docs/audit/backend-verification.md (+ subscriptions) it checks:
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
  return { id, access: j.AuthenticationResult.AccessToken, sub: claims.sub, role: claims['custom:role'], email };
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

// ── "Not configured" probes (same pattern as the Stripe probes) ─
// SSM parameters exist with a NOT_SET placeholder until the owner fills them in, and
// the script never reads secret values. A probe that reaches the credential check
// tells the two apart: 503 "... not configured" → BLOCKED; a configured response →
// pass; anything else → BROKEN.
function configProbe(c, label, res, configuredOk, configuredMsg = 'credentials loaded') {
  const detail = `${res.status}${res.msg ? ` "${res.msg.slice(0, 80)}"` : ''}`;
  if (res.status === 503 && /not configured/i.test(res.msg)) c.fail('blocker', `${label} → ${detail}`);
  else if (configuredOk(res)) c.pass(`${label} → ${detail} (${configuredMsg})`);
  else if (res.status === 404 && res.msg === 'Route not found') c.fail('notDeployed', `${label} → ${detail}`);
  else c.fail('defect', `${label} → ${detail}; expected 503 "not configured" or a configured response`);
}

const PROBE_SESSION = 'verify-backend-test-session-probe';

// Agora: start a recording with a bogus RTC token on a session that does not exist.
// Agora credentials are read before any network call, so NOT_SET → 503. When they
// are set, Agora rejects the bogus token (500 "Agora ... failed") and nothing is
// written; a 2xx would mean a recording really started, so it is stopped again.
async function probeRecording(c, U) {
  const label = `POST /sessions/${PROBE_SESSION}/recording/start (bogus token)`;
  const res = await api('POST', `/sessions/${PROBE_SESSION}/recording/start`, U.TEACHER,
    { channelName: PROBE_SESSION, token: 'verify-backend-bogus-token', uid: '1' });
  try {
    configProbe(c, label, res, r => r.status === 500 && /^Agora .*failed/i.test(r.msg), 'credentials loaded; Agora rejected the bogus token');
    if (is2xx(res)) c.fail('defect', `${label} started a recording with a bogus token`);
  } finally {
    if (is2xx(res)) {
      const { resourceId, sid } = res.json || {};
      await api('POST', `/sessions/${PROBE_SESSION}/recording/stop`, U.TEACHER, { channelName: PROBE_SESSION, uid: '1', resourceId, sid });
    }
    if (tableExists('toriino-recordings')) {
      const key = JSON.stringify({ sessionId: { S: PROBE_SESSION } });
      if (aws(['dynamodb', 'get-item', '--table-name', 'toriino-recordings', '--key', key])?.Item) {
        aws(['dynamodb', 'delete-item', '--table-name', 'toriino-recordings', '--key', key]);
        c.pass('probe cleanup: deleted the probe recording row');
      }
    }
  }
}

// Gemini via ai-summaries: the transcript is passed in the body, so no stored
// transcript is needed. When configured this writes a summary row for the probe
// session, which is deleted again.
async function probeSummary(c, U) {
  const key = JSON.stringify({ sessionId: { S: PROBE_SESSION } });
  try {
    const res = await api('POST', `/sessions/${PROBE_SESSION}/summary`, U.TEACHER,
      { transcript: `${TEST_MARKER}. Short probe transcript.`, subjectArea: 'verification' });
    configProbe(c, `POST /sessions/${PROBE_SESSION}/summary`, res, is2xx);
  } finally {
    if (tableExists('toriino-session-summaries') && aws(['dynamodb', 'get-item', '--table-name', 'toriino-session-summaries', '--key', key])?.Item) {
      aws(['dynamodb', 'delete-item', '--table-name', 'toriino-session-summaries', '--key', key]);
      c.pass('probe cleanup: deleted the probe summary row');
    }
  }
}

// Gemini via ai-chat. When configured this writes the user message and the AI
// reply to the caller's chat history; both rows are deleted again.
async function probeChat(c, U) {
  const S = U.STUDENT;
  const res = await api('POST', `/ai/chat/${S.sub}`, S, { message: TEST_MARKER });
  try {
    configProbe(c, 'POST /ai/chat/{self}', res, is2xx);
  } finally {
    const ids = new Set([res.json?.userMessage?.messageId, res.json?.aiMessage?.messageId].filter(Boolean));
    if (tableExists('toriino-ai-chat')) {
      for (const i of aws(['dynamodb', 'query', '--table-name', 'toriino-ai-chat', '--key-condition-expression', 'userId = :u',
        '--expression-attribute-values', JSON.stringify({ ':u': { S: S.sub } })]).Items || [])
        if (i.text?.S === TEST_MARKER) ids.add(i.messageId.S);
      for (const id of ids) aws(['dynamodb', 'delete-item', '--table-name', 'toriino-ai-chat', '--key',
        JSON.stringify({ userId: { S: S.sub }, messageId: { S: id } })]);
      if (ids.size) c.pass(`probe cleanup: deleted ${ids.size} probe chat row(s)`);
    }
  }
}

// Gemini via ai-twins: build a twin for the test student. Runs only when the student
// has no twin, so an existing one is never overwritten; one created by the probe
// (configured case) is deleted again.
async function probeTwin(c, U) {
  const S = U.STUDENT;
  const key = JSON.stringify({ userId: { S: S.sub } });
  const getTwin = () => tableExists('toriino-ai-twins') ? aws(['dynamodb', 'get-item', '--table-name', 'toriino-ai-twins', '--key', key])?.Item : undefined;
  if (getTwin()) return c.fail('defect', 'twin probe skipped: the test student already has an AI twin');
  try {
    const res = await api('POST', `/ai/twins/${S.sub}`, S, { role: 'student', name: 'verify-backend-test-twin', bio: TEST_MARKER });
    configProbe(c, 'POST /ai/twins/{self}', res, is2xx);
  } finally {
    if (getTwin()) {
      aws(['dynamodb', 'delete-item', '--table-name', 'toriino-ai-twins', '--key', key]);
      c.pass('probe cleanup: deleted the probe twin');
    }
  }
}

// ── GET /users/{id}: access rule + no contact details ──────
// Rule (users Lambda): teacher/mentor profiles are public; a student profile is visible
// only to the student, or to a teacher/mentor sharing a session or an active enrollment
// in one of their courses. Contact details (email, phone) are never returned.
const CONTACT_KEY = /^(email|e-?mail|phone|phone_?number|mobile|contactEmail|contactPhone)$/i;
function contactLeaks(json, text, targetItem, extraEmail) {
  const leaks = [];
  (function walk(o, p) {
    if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) {
      if (CONTACT_KEY.test(k)) leaks.push(`${p}${k}`);
      walk(v, `${p}${k}.`);
    }
  })(json, '');
  // Values from the target's own record must not appear anywhere in the body (not printed).
  const values = [targetItem?.email?.S, targetItem?.phone?.S, targetItem?.phoneNumber?.S, extraEmail].filter(v => v && v.length > 3);
  if (values.some(v => text.includes(v))) leaks.push('contact value in body');
  return leaks;
}
function relatedPerData(educatorId, studentId) {
  const sess = aws(['dynamodb', 'scan', '--table-name', 'torino-sessions', '--filter-expression', 'studentId = :s AND (mentorId = :c OR teacherId = :c)',
    '--expression-attribute-values', JSON.stringify({ ':s': { S: studentId }, ':c': { S: educatorId } }), '--select', 'COUNT']).Count;
  const courses = (aws(['dynamodb', 'scan', '--table-name', 'torino-courses', '--filter-expression', 'teacherId = :c OR mentorId = :c',
    '--expression-attribute-values', JSON.stringify({ ':c': { S: educatorId } }), '--projection-expression', 'courseId']).Items || []).map(i => i.courseId.S);
  const enrolled = courses.some(cid => scanFor('toriino-enrollments', 'courseId', cid).some(e => [e.userId?.S, e.studentId?.S].includes(studentId)));
  return sess > 0 || enrolled;
}
async function checkUserById(c, U) {
  c.route('GET', '/users/x', { lambda: 'toriino-users' });
  const userItem = id => aws(['dynamodb', 'get-item', '--table-name', 'torino-users', '--key', JSON.stringify({ userId: { S: id } })])?.Item;
  const view = async (label, caller, targetId, expect, targetEmail) => {
    const raw = await fetch(`${BASE}/users/${targetId}`, { headers: { Authorization: `Bearer ${caller.id}` } });
    const text = await raw.text(); let json = null; try { json = JSON.parse(text); } catch { }
    const res = { status: raw.status, msg: String(json?.error || json?.message || '') };
    c.check(res.status === expect, 'defect', `GET /users/{id} ${label} → ${res.status}`,
      `GET /users/{id} ${label} → ${res.status}${res.msg ? ` "${res.msg}"` : ''}, expected ${expect}`);
    const leaks = contactLeaks(json, text, userItem(targetId), targetEmail);
    c.check(leaks.length === 0, 'defect', `GET /users/{id} ${label}: no email/phone in the response`,
      `GET /users/{id} ${label}: response exposes ${leaks.join(', ')}`);
  };
  const S = U.STUDENT, T = U.TEACHER, M = U.MENTOR;
  // Refusals: an unrelated teacher, and another student.
  if (!relatedPerData(T.sub, S.sub)) await view('unrelated teacher → test student', T, S.sub, 403, S.email);
  else c.fail('defect', 'GET /users/{id}: test teacher is related to the test student, so the unrelated-educator case cannot be checked');
  const other = (aws(['dynamodb', 'scan', '--table-name', 'torino-users', '--filter-expression', '#r IN (:a, :b)',
    '--expression-attribute-names', '{"#r":"role"}', '--expression-attribute-values', '{":a":{"S":"student"},":b":{"S":"Student"}}',
    '--projection-expression', 'userId']).Items || []).map(i => i.userId.S).filter(id => id !== S.sub).sort()[0];
  if (other) await view('test student → another student', S, other, 403);
  else c.fail('defect', 'GET /users/{id}: no other student record to check the student → student refusal');
  // Allowed views must still carry no contact details.
  if (relatedPerData(M.sub, S.sub)) await view('related mentor → test student', M, S.sub, 200, S.email);
  else c.fail('note', 'GET /users/{id}: no mentor shares a session with the test student; related-educator view not checked');
  await view('student → test teacher (public profile)', S, T.sub, 200, T.email);
  await view('test student → self', S, S.sub, 200);
}

// ── GET /payments/quote: server fee split matches PLATFORM_FEE_PERCENT ─
async function checkQuote(c, U) {
  c.route('GET', '/payments/quote', { lambda: 'toriino-payments' });
  const prefix = (await lambdaInfo('toriino-payments')).env?.SSM_PREFIX;
  const p = prefix && awsTry(['ssm', 'get-parameter', '--name', `${prefix}PLATFORM_FEE_PERCENT`]); // SSM String, not a secret
  const pct = p?.ok ? Number(p.data.Parameter.Value) : NaN;
  if (!c.check(Number.isFinite(pct) && pct >= 0 && pct <= 100, 'defect', `PLATFORM_FEE_PERCENT = ${pct}%`,
    'PLATFORM_FEE_PERCENT is missing or not a number 0–100')) return;
  const expect = priceDollars => {
    const priceCents = Math.round(priceDollars * 100), fee = Math.round(priceCents * pct / 100);
    return { price: priceCents / 100, platformFee: fee / 100, teacherShare: (priceCents - fee) / 100 };
  };
  const compare = (label, res, priceDollars) => {
    if (!is2xx(res)) return c.live(label, res, () => false);
    const e = expect(priceDollars), q = res.json || {};
    const diffs = ['price', 'platformFee', 'teacherShare'].filter(k => q[k] !== e[k]);
    if (q.platformFeePercent !== pct) diffs.push('platformFeePercent');
    c.check(diffs.length === 0, 'defect',
      `${label} → price ${q.price}, fee ${q.platformFee} (${q.platformFeePercent}%), teacher ${q.teacherShare} — matches`,
      `${label} → ${JSON.stringify(Object.fromEntries(['price', 'platformFeePercent', 'platformFee', 'teacherShare'].map(k => [k, q[k]])))}, expected ${JSON.stringify({ ...e, platformFeePercent: pct })}`);
  };
  const course = (aws(['dynamodb', 'scan', '--table-name', 'torino-courses', '--filter-expression', 'price > :z AND (attribute_not_exists(#s) OR #s <> :d)',
    '--expression-attribute-names', '{"#s":"status"}', '--expression-attribute-values', '{":z":{"N":"0"},":d":{"S":"deleted"}}',
    '--projection-expression', 'courseId,price']).Items || []).map(i => ({ id: i.courseId.S, price: Number(i.price.N) })).sort((a, b) => a.id.localeCompare(b.id))[0];
  if (course) compare(`GET /payments/quote?courseId=${course.id}`, await api('GET', `/payments/quote?courseId=${course.id}`, U.STUDENT), course.price);
  const mentor = approvedMentor();
  if (mentor) compare(`GET /payments/quote?mentorId=…&duration=45 (hourlyRate ${mentor.rate})`,
    await api('GET', `/payments/quote?mentorId=${mentor.id}&duration=45`, U.STUDENT), mentor.rate * 45 / 60);
}
function approvedMentor() {
  return (aws(['dynamodb', 'scan', '--table-name', 'torino-mentors', '--filter-expression', 'hourlyRate > :z AND (attribute_not_exists(approved) OR approved = :t)',
    '--expression-attribute-values', '{":z":{"N":"0"},":t":{"BOOL":true}}', '--projection-expression', 'mentorId,hourlyRate']).Items || [])
    .map(i => ({ id: i.mentorId.S, rate: Number(i.hourlyRate.N) })).sort((a, b) => a.id.localeCompare(b.id))[0];
}

// ── Booking: a client-sent price must be ignored or rejected ─
// Write test: the student books a real mentor sending price 1 / currency eur. Passes if
// the booking is refused (4xx) or the stored session has the server price
// (hourlyRate × duration, usd). The session row is deleted afterwards.
async function checkBookingPrice(c, U) {
  const mentor = approvedMentor();
  if (!mentor) return c.fail('defect', 'booking price test: no approved mentor with an hourlyRate');
  const minutes = 30, serverPrice = Math.round(mentor.rate * minutes / 60 * 100) / 100;
  const marker = `${TEST_MARKER} (booking price)`;
  const findMine = () => (aws(['dynamodb', 'scan', '--table-name', 'torino-sessions', '--filter-expression', '#t = :t',
    '--expression-attribute-names', '{"#t":"title"}', '--expression-attribute-values', JSON.stringify({ ':t': { S: marker } })]).Items || []);
  let res;
  try {
    res = await api('POST', '/sessions', U.STUDENT, {
      mentorId: mentor.id, duration: minutes, price: 1, currency: 'eur', title: marker,
      dateTime: new Date(Date.now() + 365 * 864e5).toISOString(),
    });
    if (res.status >= 400 && res.status < 500) c.pass(`booking with a client price → ${res.status} (rejected)`);
    else if (res.status === 201) {
      const stored = findMine()[0];
      const price = Number(stored?.price?.N), cur = stored?.currency?.S;
      c.check(price === serverPrice && cur === 'usd', 'defect',
        `booking with client price 1 eur → stored ${price} ${cur} = server price (hourlyRate ${mentor.rate} × ${minutes} min)`,
        `booking with client price 1 eur → stored ${price} ${cur}, expected server price ${serverPrice} usd`);
      const p = res.json?.session?.pricing;
      if (p) c.check(p.price === serverPrice, 'defect', `booking response pricing.price = ${p.price}`, `booking response pricing.price = ${p.price}, expected ${serverPrice}`);
    } else c.live('POST /sessions (booking with a client price)', res, () => false);
  } finally {
    const rows = findMine();
    for (const r of rows) aws(['dynamodb', 'delete-item', '--table-name', 'torino-sessions', '--key', JSON.stringify({ sessionId: r.sessionId })]);
    if (rows.length) c.pass(`write test cleanup: deleted ${rows.length} test session(s)`);
  }
}

// ── Agora AccessToken2 decoder ──────────────────────────────
// Layout (agora-token AccessToken2, little-endian): "007" + base64(zlib(
//   string signature, string appId, u32 issueTs, u32 expire, u32 salt, u16 serviceCount,
//   services: u16 type, map<u16,u32> privileges, then for RTC (type 1): string channel, string uid)).
// string = u16 length + bytes. Returns a list of problems (empty = valid).
function validateAgoraToken2(token, { appId, channelName, uid, role }) {
  const problems = [];
  if (!token.startsWith('007')) return ['does not start with version "007"'];
  let buf;
  try { buf = zlib.inflateSync(Buffer.from(token.slice(3), 'base64')); }
  catch { return ['payload after "007" is not zlib-compressed base64 (legacy 006-style layout?)']; }
  let p = 0;
  const u16 = () => { const v = buf.readUInt16LE(p); p += 2; return v; };
  const u32 = () => { const v = buf.readUInt32LE(p); p += 4; return v; };
  const str = () => { const n = u16(); const v = buf.subarray(p, p + n); p += n; return v; };
  try {
    const sig = str(), tokAppId = str().toString(), issueTs = u32(), expire = u32(), salt = u32(), count = u16();
    if (sig.length !== 32) problems.push(`signature is ${sig.length} bytes, expected 32 (HMAC-SHA256)`);
    if (tokAppId !== appId) problems.push('App ID inside the token does not match AGORA_APP_ID');
    const now = Date.now() / 1000;
    if (Math.abs(issueTs - now) > 600) problems.push(`issue time is ${Math.round(issueTs - now)}s from now`);
    if (!(expire > 0 && expire <= 7 * 86400)) problems.push(`token lifetime ${expire}s is not in (0, 7 days]`);
    if (!(salt >= 1 && salt <= 99999999)) problems.push('salt out of range');
    let rtc = null;
    for (let i = 0; i < count; i++) {
      const type = u16(), privs = {};
      for (let n = u16(), j = 0; j < n; j++) { const k = u16(); privs[k] = u32(); }
      if (type !== 1) { problems.push(`unexpected service type ${type}`); break; }
      rtc = { privs, channel: str().toString(), uid: str().toString() };
    }
    if (!rtc) problems.push('no RTC service');
    else {
      if (rtc.channel !== channelName) problems.push('channel name does not match the request');
      if (rtc.uid !== (uid === 0 ? '' : String(uid))) problems.push('uid does not match the request');
      const need = role === 'publisher' ? [1, 2, 3, 4] : [1];
      const missing = need.filter(k => !(rtc.privs[k] > 0));
      if (missing.length) problems.push(`missing privilege(s) ${missing.join(',')} (1 join, 2-4 publish)`);
    }
    if (p !== buf.length) problems.push(`${buf.length - p} unexpected trailing bytes`);
  } catch (e) { problems.push(`truncated payload (${e.message})`); }
  return problems;
}

// ── Set-role rules and custom:role protection ───────────────
// Snapshot a user's Cognito custom:role and users-table row; restore() puts both back exactly.
function roleSnapshot(email, sub) {
  const attr = () => (aws(['cognito-idp', 'admin-get-user', '--user-pool-id', USER_POOL, '--username', email]).UserAttributes || [])
    .find(a => a.Name === 'custom:role')?.Value;
  const ukey = JSON.stringify({ userId: { S: sub } });
  const row = () => aws(['dynamodb', 'get-item', '--table-name', 'torino-users', '--key', ukey])?.Item;
  const before = { role: attr(), row: row() };
  return {
    before, attr,
    restore(c) {
      const now = attr();
      if (now !== before.role) {
        if (before.role) aws(['cognito-idp', 'admin-update-user-attributes', '--user-pool-id', USER_POOL, '--username', email,
          '--user-attributes', JSON.stringify([{ Name: 'custom:role', Value: before.role }])]);
        else aws(['cognito-idp', 'admin-delete-user-attributes', '--user-pool-id', USER_POOL, '--username', email, '--user-attribute-names', 'custom:role']);
        c.pass(`cleanup: restored ${email.split('@')[0]}'s Cognito custom:role`);
      }
      const r = row();
      if (JSON.stringify(r) !== JSON.stringify(before.row)) {
        if (before.row) aws(['dynamodb', 'put-item', '--table-name', 'torino-users', '--item', JSON.stringify(before.row)]);
        else aws(['dynamodb', 'delete-item', '--table-name', 'torino-users', '--key', ukey]);
        c.pass(`cleanup: restored ${email.split('@')[0]}'s users-table row`);
      }
    },
  };
}

async function checkSetRole(c, U) {
  const S = U.STUDENT, M = U.MENTOR, A = U.ADMIN;
  const setRole = (u, role) => api('POST', '/auth/set-role', u, { role });
  const expectStatus = (label, res, want) => c.check(res.status === want, 'defect', `${label} → ${res.status}${res.msg ? ` "${res.msg}"` : ''}`,
    `${label} → ${res.status}${res.msg ? ` "${res.msg}"` : ''}, expected ${want}`);

  // Refusals (no change expected; anything that slips through is undone).
  const sSnap = roleSnapshot(S.email, S.sub), aSnap = roleSnapshot(A.email, A.sub);
  try {
    expectStatus('set-role: student (role already set) → Teacher', await setRole(S, 'Teacher'), 409);
    expectStatus('set-role: student → admin', await setRole(S, 'admin'), 403);
    expectStatus('set-role: admin → Student', await setRole(A, 'Student'), 403);
  } finally { sSnap.restore(c); aSnap.restore(c); }

  // Mentor allowed once: clear the test mentor's custom:role, pick Mentor (200), then any
  // second pick is 409. The mentor's Cognito attribute and users row are restored exactly.
  const mSnap = roleSnapshot(M.email, M.sub);
  if (mSnap.before.role !== 'mentor') return c.fail('defect', `mentor-once test skipped: test mentor's custom:role is "${mSnap.before.role}", expected "mentor"`);
  try {
    aws(['cognito-idp', 'admin-delete-user-attributes', '--user-pool-id', USER_POOL, '--username', M.email, '--user-attribute-names', 'custom:role']);
    const first = await setRole(M, 'Mentor');
    c.check(is2xx(first) && mSnap.attr() === 'mentor', 'defect', `set-role: user with no role → Mentor → ${first.status}, custom:role = mentor`,
      `set-role: user with no role → Mentor → ${first.status}${first.msg ? ` "${first.msg}"` : ''}, custom:role = ${mSnap.attr()}`);
    expectStatus('set-role: same user again → Teacher', await setRole(M, 'Teacher'), 409);
  } finally { mSnap.restore(c); }

  // custom:role must not be writable by the user through Cognito itself.
  const client = aws(['cognito-idp', 'describe-user-pool-client', '--user-pool-id', USER_POOL, '--client-id', CLIENT_ID]).UserPoolClient;
  c.check(Array.isArray(client.WriteAttributes) && !client.WriteAttributes.includes('custom:role'), 'defect',
    'app client WriteAttributes does not include custom:role',
    client.WriteAttributes ? 'app client WriteAttributes includes custom:role' : 'app client has no WriteAttributes list (all writable attributes allowed)');
  const snap = roleSnapshot(S.email, S.sub);
  try {
    const r = await fetch(`https://cognito-idp.${REGION}.amazonaws.com/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-amz-json-1.1', 'X-Amz-Target': 'AWSCognitoIdentityProviderService.UpdateUserAttributes' },
      body: JSON.stringify({ AccessToken: S.access, UserAttributes: [{ Name: 'custom:role', Value: 'teacher' }] }),
    });
    const j = await r.json().catch(() => ({}));
    c.check(r.status >= 400 && snap.attr() === snap.before.role, 'defect',
      `Cognito UpdateUserAttributes custom:role with the student's access token → ${r.status} ${j.__type || ''} (refused)`,
      `Cognito UpdateUserAttributes custom:role with the student's access token → ${r.status}; custom:role is now ${snap.attr()}`);
  } finally { snap.restore(c); }
}

// ── Withdraw: bank fields must be rejected ──────────────────
async function checkWithdrawBankFields(c, U) {
  c.route('POST', '/earnings/withdraw');
  const M = U.MENTOR, wTable = 'toriino-withdrawals';
  const mine = () => tableExists(wTable) ? aws(['dynamodb', 'query', '--table-name', wTable, '--key-condition-expression', 'userId = :u',
    '--expression-attribute-values', JSON.stringify({ ':u': { S: M.sub } })]).Items || [] : [];
  const before = new Set(mine().map(i => i.withdrawalId.S));
  try {
    // Obviously fake values; the API must refuse them before anything else.
    const res = await api('POST', '/earnings/withdraw', M, {
      amount: 1, bankDetails: { accountNumber: 'TEST-NOT-A-REAL-ACCOUNT', routingNumber: 'TEST-NOT-A-REAL-ROUTING' }, iban: 'TEST-NOT-A-REAL-IBAN',
    });
    const rejected = res.json?.rejectedFields || [];
    c.check(res.status === 400 && ['bankDetails', 'iban'].every(f => rejected.includes(f)), 'defect',
      `POST /earnings/withdraw with bank fields → 400, rejectedFields ${JSON.stringify(rejected)}`,
      `POST /earnings/withdraw with bank fields → ${res.status}${res.msg ? ` "${res.msg}"` : ''}, expected 400 naming the bank fields`);
  } finally {
    const created = mine().filter(i => !before.has(i.withdrawalId.S));
    for (const i of created) aws(['dynamodb', 'delete-item', '--table-name', wTable, '--key', JSON.stringify({ userId: i.userId, withdrawalId: i.withdrawalId })]);
    if (created.length) c.fail('defect', `withdraw with bank fields created ${created.length} withdrawal(s) (deleted)`);
  }
  // No stored withdrawal may carry bank data.
  const leaked = tableExists(wTable) ? aws(['dynamodb', 'scan', '--table-name', wTable, '--select', 'COUNT', '--filter-expression',
    'attribute_exists(bankDetails) OR attribute_exists(accountNumber) OR attribute_exists(routingNumber) OR attribute_exists(iban)']).Count : 0;
  c.check(leaked === 0, 'defect', `${wTable}: no stored withdrawal contains bank fields`, `${wTable}: ${leaked} withdrawal(s) contain bank fields`);
}

// ── Subscriptions + premium gate ────────────────────────────
// Plans live in SSM SUBSCRIPTION_PLANS (String JSON; not a secret). A plan is offered
// only if active, with a real Stripe Price ID and a valid price.
const ssmString = async (lambda, name) => {
  const prefix = (await lambdaInfo(lambda)).env?.SSM_PREFIX;
  const r = prefix && awsTry(['ssm', 'get-parameter', '--name', `${prefix}${name}`]);
  return r?.ok ? r.data.Parameter.Value : null;
};
const planOffered = p => p && p.active === true && ['student', 'teacher', 'mentor'].includes(p.audience)
  && p.stripePriceId && p.stripePriceId !== 'NOT_SET' && Number(p.price) > 0;

async function checkSubscriptions(c, U) {
  for (const [m, p] of [['GET', '/subscriptions/plans'], ['GET', '/subscriptions/me'], ['POST', '/subscriptions'], ['POST', '/subscriptions/cancel']])
    c.route(m, p, { lambda: 'toriino-subscriptions' });
  await c.lambda('toriino-subscriptions');
  await c.envTable('toriino-subscriptions', 'SUBSCRIPTIONS_TABLE');
  await c.envTable('toriino-subscriptions', 'USERS_TABLE');
  let plans = null;
  try { plans = JSON.parse(await ssmString('toriino-subscriptions', 'SUBSCRIPTION_PLANS')); } catch { }
  if (!c.check(Array.isArray(plans), 'defect', `SUBSCRIPTION_PLANS: ${plans?.length} server-defined plan(s)`, 'SUBSCRIPTION_PLANS is missing or not a JSON array')) return;

  // 1. Plans: only the server's offered plans for the caller's own role.
  for (const r of ['STUDENT', 'TEACHER', 'MENTOR']) {
    const role = r.toLowerCase();
    const res = await api('GET', '/subscriptions/plans', U[r]);
    if (!is2xx(res)) { c.live(`GET /subscriptions/plans as ${role}`, res, () => false); continue; }
    const got = list(res, 'plans') || [];
    const expected = plans.filter(p => p.audience === role && planOffered(p));
    const bad = got.filter(g => { const s = plans.find(p => p.planId === g.planId);
      return !s || s.audience !== role || !planOffered(s) || Number(g.price) !== Number(s.price); });
    const missing = expected.filter(e => !got.some(g => g.planId === e.planId));
    c.check(res.json.audience === role && bad.length === 0 && missing.length === 0 && res.json.comingSoon === (expected.length === 0), 'defect',
      `GET /subscriptions/plans as ${role} → audience ${res.json.audience}, ${got.length} plan(s), comingSoon=${res.json.comingSoon} — matches server config`,
      `GET /subscriptions/plans as ${role} → audience ${res.json.audience}, plans ${JSON.stringify(got.map(g => g.planId))}, comingSoon=${res.json.comingSoon}; `
      + `expected ${JSON.stringify(expected.map(e => e.planId))}${bad.length ? `, not server-offered: ${bad.map(b => b.planId)}` : ''}`);
    if (expected.length === 0) {
      const mine = plans.filter(p => p.audience === role);
      if (mine.length && mine.every(p => !p.stripePriceId || p.stripePriceId === 'NOT_SET'))
        c.fail('blocker', `${role} plans are "coming soon": Stripe Price IDs are NOT_SET (${mine.length} plan(s) defined, none offered)`);
      else if (!mine.length) c.fail('defect', `no ${role} plans defined in SUBSCRIPTION_PLANS`);
      else c.pass(`${role} plans are "coming soon": defined but switched off (active=false)`);
    }
  }

  // 2. Checkout must never activate anything. Probed only when it cannot create a real
  //    Stripe subscription: the plan is not offered, or Stripe is not configured.
  const S = U.STUDENT;
  const plan = plans.filter(p => p.audience === 'student').sort((a, b) => String(a.planId).localeCompare(String(b.planId)))[0];
  if (!plan) return c.fail('defect', 'checkout not checked: no student plan defined');
  const stripeUnset = (await api('POST', '/payments/create-intent', S, {})).status === 503;
  if (planOffered(plan) && !stripeUnset) return c.fail('note', `checkout not probed: ${plan.planId} is offered and Stripe is configured, so it would create a real Stripe subscription`);
  const subTable = (await lambdaInfo('toriino-subscriptions')).env?.SUBSCRIPTIONS_TABLE;
  const key = JSON.stringify({ userId: { S: S.sub } });
  const snap = () => ({
    sub: subTable && tableExists(subTable) ? aws(['dynamodb', 'get-item', '--table-name', subTable, '--key', key])?.Item : undefined,
    cust: aws(['dynamodb', 'get-item', '--table-name', 'torino-users', '--key', key, '--projection-expression', 'stripeCustomerId'])?.Item,
  });
  const before = snap();
  const label = `POST /subscriptions {planId: ${plan.planId}} as student`;
  try {
    const res = await api('POST', '/subscriptions', S, { planId: plan.planId });
    const detail = `${res.status}${res.msg ? ` "${res.msg}"` : ''}`;
    if (res.status === 503 && /stripe not configured/i.test(res.msg)) c.fail('blocker', `${label} → ${detail}`);
    else if (!planOffered(plan) && res.status === 404) {
      if (!plan.stripePriceId || plan.stripePriceId === 'NOT_SET')
        c.fail('blocker', `${label} → ${detail} (Stripe Price ID NOT_SET, so the plan is not offered and the Stripe check is never reached)`);
      else c.pass(`${label} → ${detail} (plan switched off; refused)`);
    }
    else c.fail('defect', `${label} → ${detail}; expected 503 "Stripe not configured" or 404 for a plan that is not offered`);
    const me = await api('GET', '/subscriptions/me', S);
    c.check(is2xx(me) && me.json?.premium === false, 'defect', `GET /subscriptions/me → premium=${me.json?.premium}, status=${me.json?.status}`,
      `GET /subscriptions/me → ${me.status} premium=${me.json?.premium} after a checkout attempt`);
    const after = snap();
    c.check(JSON.stringify(after) === JSON.stringify(before), 'defect', 'checkout attempt activated nothing (subscription record and stripeCustomerId unchanged)',
      'checkout attempt changed the subscription record or stripeCustomerId');
  } finally {
    const after = snap();
    if (subTable && JSON.stringify(after.sub) !== JSON.stringify(before.sub)) {
      if (before.sub) aws(['dynamodb', 'put-item', '--table-name', subTable, '--item', JSON.stringify(before.sub)]);
      else aws(['dynamodb', 'delete-item', '--table-name', subTable, '--key', key]);
      c.pass('write test cleanup: restored the subscription record');
    }
  }

  // 3. Premium gate: POST /ai/memory/{self}/recommend is gated as "ai_recommendations" and is
  //    read-only. The gate runs before Gemini, so "allowed" shows as anything but 402.
  let features = null;
  try { features = JSON.parse(await ssmString('toriino-ai-memory', 'PREMIUM_FEATURES')); } catch { }
  if (!c.check(Array.isArray(features), 'defect', `PREMIUM_FEATURES = ${JSON.stringify(features)}`, 'PREMIUM_FEATURES is missing or not a JSON array')) return;
  const gated = features.includes('ai_recommendations');
  const res = await api('POST', `/ai/memory/${S.sub}/recommend`, S, {});
  const detail = `${res.status}${res.msg ? ` "${res.msg}"` : ''}`;
  if (gated) c.check(res.status === 402, 'defect', `premium-gated call (ai_recommendations listed) as non-premium student → 402`,
    `premium-gated call (ai_recommendations listed) as non-premium student → ${detail}, expected 402`);
  else c.check(res.status !== 402 && res.status > 0, 'defect', `premium-gated call with ai_recommendations not listed → ${detail} (allowed through the gate)`,
    `premium-gated call with ai_recommendations not listed → ${detail}, expected it to pass the gate`);
}

// ── Features (same 27 as docs/audit/backend-verification.md, + subscriptions) ─
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
    await checkSetRole(c, U);
  }],
  ['User profile (home screens, profile screen)', async (c, U) => {
    c.route('GET', '/users/profile', { lambda: 'toriino-users' });
    c.route('PUT', '/users/profile', { lambda: 'toriino-users' });
    await c.lambda('toriino-users');
    await c.envTable('toriino-users', 'USERS_TABLE');
    for (const r of ['STUDENT', 'TEACHER', 'MENTOR']) c.live(`GET /users/profile as ${r.toLowerCase()}`, await api('GET', '/users/profile', U[r]), is2xx);
    await checkUserById(c, U);
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
    await checkQuote(c, U);
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
    await checkBookingPrice(c, U);
  }],
  ['Live-session Agora token', async (c, U) => {
    c.route('POST', '/sessions/token');
    await c.envVars(MONOLITH, ['AGORA_APP_ID']);
    // Plain env var or SSM parameter under the Lambda's SSM_PREFIX; not an allowed blocker.
    await c.secret(MONOLITH, 'AGORA_APP_CERTIFICATE', 'defect');
    // Not an allowed blocker: a 503 here (certificate missing) is BROKEN.
    const appId = (await lambdaInfo(MONOLITH)).env?.AGORA_APP_ID || '';
    const req = { channelName: 'verify-backend-probe', uid: 4242, role: 'publisher' };
    const res = await api('POST', '/sessions/token', U.STUDENT, req);
    if (!is2xx(res) || typeof res.json?.token !== 'string')
      return c.fail('defect', `POST /sessions/token → ${res.status}${res.msg ? ` "${res.msg}"` : ''}; expected a token`);
    const problems = validateAgoraToken2(res.json.token, { appId, ...req });
    c.check(problems.length === 0, 'defect',
      `POST /sessions/token → 200, valid AccessToken2: App ID, channel, uid 4242, RTC join + publish privileges, fresh issue time, 32-byte signature`,
      `POST /sessions/token → 200 but the token is not a valid AccessToken2: ${problems.join('; ')}`);
    c.fail('note', 'token signature not verified: that needs the App Certificate (SSM SecureString), which this script never reads');
  }],
  ['Session recording', async (c, U) => {
    for (const [m, p] of [['GET', '/sessions/x/recording'], ['POST', '/sessions/x/recording/start'], ['POST', '/sessions/x/recording/stop']])
      c.route(m, p, { lambda: 'toriino-agora-recording' });
    await c.lambda('toriino-agora-recording');
    await c.envVars('toriino-agora-recording', ['AGORA_APP_ID', 'RECORDING_TABLE', 'RECORDING_S3_BUCKET']);
    await c.secret('toriino-agora-recording', 'AGORA_APP_CERTIFICATE', 'defect');
    for (const v of ['AGORA_CUSTOMER_ID', 'AGORA_CUSTOMER_SECRET']) await c.secret('toriino-agora-recording', v);
    c.tables('toriino-recordings');
    c.live('GET /sessions/{none}/recording', await api('GET', '/sessions/verify-backend-none/recording', U.STUDENT), not5xx);
    await probeRecording(c, U);
  }],
  ['Transcript / summary', async (c, U) => {
    c.route('GET', '/sessions/x/transcript', { lambda: 'toriino-ai-transcripts' });
    c.route('GET', '/sessions/x/summary', { lambda: 'toriino-ai-summaries' });
    for (const l of ['toriino-ai-transcripts', 'toriino-ai-summaries', 'toriino-transcribe-processor']) await c.lambda(l);
    for (const l of ['toriino-ai-summaries', 'toriino-transcribe-processor']) await c.secret(l, 'GEMINI_API_KEY');
    c.tables('toriino-transcripts', 'toriino-session-summaries');
    c.live('GET /sessions/{none}/transcript', await api('GET', '/sessions/verify-backend-none/transcript', U.STUDENT), not5xx);
    c.live('GET /sessions/{none}/summary', await api('GET', '/sessions/verify-backend-none/summary', U.STUDENT), not5xx);
    await probeSummary(c, U);
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
    await probeChat(c, U);
  }],
  ['AI Twins / Memory', async (c, U) => {
    c.route('GET', '/ai/twins/x', { lambda: 'toriino-ai-twins' });
    c.route('GET', '/ai/memory/x', { lambda: 'toriino-ai-memory' });
    for (const l of ['toriino-ai-twins', 'toriino-ai-memory']) { await c.lambda(l); await c.secret(l, 'GEMINI_API_KEY'); }
    c.tables('toriino-ai-twins', 'toriino-ai-memory', 'toriino-knowledge-graph');
    c.live('GET /ai/twins/{self}', await api('GET', `/ai/twins/${U.STUDENT.sub}`, U.STUDENT), not5xx);
    c.live('GET /ai/memory/{self}', await api('GET', `/ai/memory/${U.STUDENT.sub}`, U.STUDENT), is2xx);
    c.live('GET /ai/memory/{self}/graph', await api('GET', `/ai/memory/${U.STUDENT.sub}/graph`, U.STUDENT), is2xx);
    // Read-only even when configured: recommend only reads memory and calls Gemini.
    configProbe(c, 'POST /ai/memory/{self}/recommend', await api('POST', `/ai/memory/${U.STUDENT.sub}/recommend`, U.STUDENT, {}), is2xx);
    await probeTwin(c, U);
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
    await checkWithdrawBankFields(c, U);
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
  ['Subscriptions + premium gate (P5-2)', async (c, U) => { await checkSubscriptions(c, U); }],
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
