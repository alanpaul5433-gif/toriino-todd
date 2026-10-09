// Idempotent route deployment for API Gateway pq8cu94cfd (us-east-1, stage prod).
//
// Reads aws-backend/routes.json and, for every route:
//   - creates any missing resource (path parts are created parent-first)
//   - creates the method, or updates its authorization if it drifted
//     (Cognito authorizer everywhere; only routes marked "auth": "NONE" are public,
//      and the manifest is rejected unless that is exactly POST /stripe/webhook)
//   - points the method at its Lambda (AWS_PROXY), overwriting any old integration;
//     a route with "mock404": true gets a MOCK integration answering 404 instead
//     (used for the /{proxy+} catch-all, so nothing falls through to the old monolith)
//   - grants API Gateway permission to invoke the Lambda (skipped when an existing
//     statement already covers the route)
//   - adds a public MOCK OPTIONS preflight with CORS headers if the resource has none
// then creates a deployment of the prod stage. Never deletes resources, methods or stages.
//
// Usage (from toriino-splash/):
//   node scripts/deploy-api-routes.mjs            apply + deploy
//   node scripts/deploy-api-routes.mjs --dry-run  print what would change, change nothing
// Requires AWS CLI v2 configured for the account.

import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'aws-backend', 'routes.json'), 'utf8'));
const { region: REGION, restApiId: API, stage: STAGE, authorizerName } = manifest;
const DRY = process.argv.includes('--dry-run');
const ALLOWED_PUBLIC = new Set(['POST /stripe/webhook']);

function aws(args, { allowFail = false } = {}) {
  try {
    const out = execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024,
    });
    return out.trim() ? JSON.parse(out) : {};
  } catch (e) {
    const msg = String(e.stderr || e.message).trim();
    if (allowFail) return { __error: msg };
    throw new Error(msg);
  }
}
const isNotFound = (r) => r?.__error && /NotFoundException|ResourceNotFoundException/.test(r.__error);
const log = (...a) => console.log(...a);
const change = (msg) => log(`${DRY ? '[dry-run] would ' : ''}${msg}`);

// ── Validate the manifest ───────────────────────────────────
for (const r of manifest.routes) {
  if (!r.path?.startsWith('/') || !Array.isArray(r.methods) || !(r.lambda || r.mock404)) throw new Error(`bad route entry: ${JSON.stringify(r)}`);
  if (r.auth && r.auth !== 'NONE') throw new Error(`route ${r.path}: auth must be omitted (Cognito) or "NONE"`);
  if (r.auth === 'NONE') for (const m of r.methods) {
    if (!ALLOWED_PUBLIC.has(`${m} ${r.path}`)) throw new Error(`${m} ${r.path} may not be public — only ${[...ALLOWED_PUBLIC].join(', ')}`);
  }
}

// ── Look up the account, authorizer and existing resources ──
const account = aws(['sts', 'get-caller-identity']).Account;
const authorizer = (aws(['apigateway', 'get-authorizers', '--rest-api-id', API]).items || [])
  .find((a) => a.name === authorizerName && a.type === 'COGNITO_USER_POOLS');
if (!authorizer) throw new Error(`Cognito authorizer "${authorizerName}" not found on ${API}`);

const resources = {};
for (const item of aws(['apigateway', 'get-resources', '--rest-api-id', API, '--limit', '500', '--embed', 'methods']).items || []) {
  resources[item.path] = { id: item.id, methods: item.resourceMethods || {} };
}

let created = 0, updated = 0, unchanged = 0;

function ensureResource(p) {
  if (resources[p]) return resources[p].id;
  const parts = p.split('/').filter(Boolean);
  let parentPath = '/';
  for (let i = 0; i < parts.length; i++) {
    const cur = '/' + parts.slice(0, i + 1).join('/');
    if (!resources[cur]) {
      change(`create resource ${cur}`);
      const id = DRY ? `dry-${cur}` : aws(['apigateway', 'create-resource', '--rest-api-id', API,
        '--parent-id', resources[parentPath].id, '--path-part', parts[i]]).id;
      resources[cur] = { id, methods: {} };
      created++;
    }
    parentPath = cur;
  }
  return resources[p].id;
}

// ── Lambda ARNs and invoke permissions ──────────────────────
const lambdaArns = {};
function lambdaArn(name) {
  if (lambdaArns[name]) return lambdaArns[name];
  const r = aws(['lambda', 'get-function-configuration', '--function-name', name], { allowFail: true });
  if (r.__error) throw new Error(`Lambda ${name} not found — deploy it first (sam deploy)`);
  return (lambdaArns[name] = r.FunctionArn);
}

const globToRe = (g) => new RegExp('^' + g.split('*').map((s) => s.replace(/[.+?^${}()|[\]\\]/g, '\\$&')).join('.*') + '$');
const policyCache = {};
function ensurePermission(fn, method, p) {
  const routeArn = `arn:aws:execute-api:${REGION}:${account}:${API}/${STAGE}/${method === 'ANY' ? 'GET' : method}${p.replace(/\{[^}]+\}/g, 'x')}`;
  if (!policyCache[fn]) {
    const r = aws(['lambda', 'get-policy', '--function-name', fn], { allowFail: true });
    policyCache[fn] = r.__error ? [] : JSON.parse(r.Policy).Statement;
  }
  const covered = policyCache[fn].some((s) => {
    const principal = s.Principal?.Service || s.Principal;
    const src = s.Condition?.ArnLike?.['AWS:SourceArn'];
    return principal === 'apigateway.amazonaws.com' && [].concat(s.Action).some((a) => a === 'lambda:InvokeFunction' || a === 'lambda:*')
      && (!src || globToRe(src).test(routeArn));
  });
  if (covered) return;
  const sourceArn = `arn:aws:execute-api:${REGION}:${account}:${API}/*`;
  change(`grant API Gateway invoke on ${fn} (${sourceArn})`);
  if (!DRY) {
    const r = aws(['lambda', 'add-permission', '--function-name', fn, '--statement-id', `apigw-${API}-invoke`,
      '--action', 'lambda:InvokeFunction', '--principal', 'apigateway.amazonaws.com', '--source-arn', sourceArn], { allowFail: true });
    if (r.__error && !/ResourceConflictException/.test(r.__error)) throw new Error(r.__error);
  }
  policyCache[fn].push({ Principal: { Service: 'apigateway.amazonaws.com' }, Action: 'lambda:InvokeFunction',
    Condition: { ArnLike: { 'AWS:SourceArn': sourceArn } } });
}

// ── Methods ─────────────────────────────────────────────────
const MOCK_404_BODY = JSON.stringify({ message: 'Not found' });
function ensureMock404(resourceId, p, method) {
  const label = `${method.padEnd(6)} ${p} → MOCK 404 (Cognito)`;
  const existing = DRY && resourceId.startsWith('dry-') ? { __error: 'NotFoundException' }
    : aws(['apigateway', 'get-method', '--rest-api-id', API, '--resource-id', resourceId, '--http-method', method], { allowFail: true });
  const integ = existing.methodIntegration;
  const done = !existing.__error && existing.authorizationType === 'COGNITO_USER_POOLS' && existing.authorizerId === authorizer.id
    && integ?.type === 'MOCK' && integ?.integrationResponses?.['404']?.responseTemplates?.['application/json'] === MOCK_404_BODY;
  if (done) { unchanged++; return; }
  if (existing.__error && !isNotFound(existing)) throw new Error(existing.__error);

  change(isNotFound(existing) ? `create ${label}` : `re-point ${label} (was ${(integ?.uri || integ?.type || 'none').match(/function:([^/:]+)/)?.[1] || integ?.type || 'none'})`);
  isNotFound(existing) ? created++ : updated++;
  if (DRY) return;
  const base = ['--rest-api-id', API, '--resource-id', resourceId, '--http-method', method];
  if (isNotFound(existing)) {
    aws(['apigateway', 'put-method', ...base, '--authorization-type', 'COGNITO_USER_POOLS', '--authorizer-id', authorizer.id]);
  } else if (existing.authorizationType !== 'COGNITO_USER_POOLS' || existing.authorizerId !== authorizer.id) {
    aws(['apigateway', 'update-method', ...base, '--patch-operations', JSON.stringify([
      { op: 'replace', path: '/authorizationType', value: 'COGNITO_USER_POOLS' },
      { op: 'replace', path: '/authorizerId', value: authorizer.id }])]);
  }
  aws(['apigateway', 'put-integration', ...base, '--type', 'MOCK',
    '--request-templates', JSON.stringify({ 'application/json': '{"statusCode": 404}' })]);
  aws(['apigateway', 'put-method-response', ...base, '--status-code', '404',
    '--response-parameters', JSON.stringify({ 'method.response.header.Access-Control-Allow-Origin': false })], { allowFail: true });
  aws(['apigateway', 'put-integration-response', ...base, '--status-code', '404', '--selection-pattern', '',
    '--response-templates', JSON.stringify({ 'application/json': MOCK_404_BODY }),
    '--response-parameters', JSON.stringify({ 'method.response.header.Access-Control-Allow-Origin': "'*'" })]);
}

function ensureMethod(resourceId, p, method, fn, isPublic) {
  const wantType = isPublic ? 'NONE' : 'COGNITO_USER_POOLS';
  const label = `${method.padEnd(6)} ${p} → ${fn} (${isPublic ? 'public' : 'Cognito'})`;
  const existing = DRY && resourceId.startsWith('dry-') ? { __error: 'NotFoundException' }
    : aws(['apigateway', 'get-method', '--rest-api-id', API, '--resource-id', resourceId, '--http-method', method], { allowFail: true });
  const uri = `arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${lambdaArn(fn)}/invocations`;

  if (isNotFound(existing)) {
    change(`create ${label}`);
    if (!DRY) {
      const args = ['apigateway', 'put-method', '--rest-api-id', API, '--resource-id', resourceId,
        '--http-method', method, '--authorization-type', wantType];
      if (!isPublic) args.push('--authorizer-id', authorizer.id);
      aws(args);
    }
    created++;
  } else if (existing.__error) {
    throw new Error(existing.__error);
  } else {
    const ops = [];
    if (existing.authorizationType !== wantType) ops.push({ op: 'replace', path: '/authorizationType', value: wantType });
    if (!isPublic && existing.authorizerId !== authorizer.id) ops.push({ op: 'replace', path: '/authorizerId', value: authorizer.id });
    const sameIntegration = existing.methodIntegration?.type === 'AWS_PROXY' && existing.methodIntegration?.uri === uri;
    if (!ops.length && sameIntegration) { unchanged++; ensurePermission(fn, method, p); return; }
    if (ops.length) {
      change(`update auth ${label} (was ${existing.authorizationType})`);
      if (!DRY) aws(['apigateway', 'update-method', '--rest-api-id', API, '--resource-id', resourceId,
        '--http-method', method, '--patch-operations', JSON.stringify(ops)]);
    }
    if (!sameIntegration) change(`re-point ${label} (was ${(existing.methodIntegration?.uri || 'none').match(/function:([^/:]+)/)?.[1] || 'none'})`);
    updated++;
  }

  if (!DRY) {
    aws(['apigateway', 'put-integration', '--rest-api-id', API, '--resource-id', resourceId, '--http-method', method,
      '--type', 'AWS_PROXY', '--integration-http-method', 'POST', '--uri', uri]);
  }
  ensurePermission(fn, method, p);
}

function ensureOptions(resourceId, p) {
  if (resources[p]?.methods?.OPTIONS) return;
  change(`add OPTIONS (CORS preflight) on ${p}`);
  if (!DRY) {
    const base = ['--rest-api-id', API, '--resource-id', resourceId, '--http-method', 'OPTIONS'];
    aws(['apigateway', 'put-method', ...base, '--authorization-type', 'NONE']);
    aws(['apigateway', 'put-integration', ...base, '--type', 'MOCK', '--request-templates', JSON.stringify({ 'application/json': '{"statusCode": 200}' })]);
    aws(['apigateway', 'put-method-response', ...base, '--status-code', '200', '--response-parameters', JSON.stringify({
      'method.response.header.Access-Control-Allow-Headers': false,
      'method.response.header.Access-Control-Allow-Methods': false,
      'method.response.header.Access-Control-Allow-Origin': false,
    })]);
    aws(['apigateway', 'put-integration-response', ...base, '--status-code', '200', '--response-parameters', JSON.stringify({
      'method.response.header.Access-Control-Allow-Headers': "'Content-Type,Authorization'",
      'method.response.header.Access-Control-Allow-Methods': "'GET,POST,PUT,PATCH,DELETE,OPTIONS'",
      'method.response.header.Access-Control-Allow-Origin': "'*'",
    })]);
  }
  resources[p].methods.OPTIONS = {};
}

// ── Apply ───────────────────────────────────────────────────
log(`API ${API} (${REGION}) stage ${STAGE} — authorizer ${authorizer.name} (${authorizer.id})${DRY ? ' — DRY RUN' : ''}\n`);
for (const r of manifest.routes) {
  const id = ensureResource(r.path);
  for (const m of r.methods) {
    if (r.mock404) ensureMock404(id, r.path, m);
    else ensureMethod(id, r.path, m, r.lambda, r.auth === 'NONE');
  }
  ensureOptions(id, r.path);
}

log(`\n${created} created · ${updated} updated · ${unchanged} unchanged`);
if (DRY) { log('Dry run: nothing changed, no deployment created.'); process.exit(0); }

const dep = aws(['apigateway', 'create-deployment', '--rest-api-id', API, '--stage-name', STAGE,
  '--description', `deploy-api-routes.mjs ${new Date().toISOString()}`]);
log(`Deployed to ${STAGE}: deployment ${dep.id}`);
