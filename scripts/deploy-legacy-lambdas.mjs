// Deploys the two Lambdas that are not in the SAM stack (torino-api has a bundled
// node_modules build and both predate the stack). Since 2026-10-07 every secret they use
// (GEMINI_API_KEY, AGORA_CUSTOMER_*, AGORA_APP_CERTIFICATE) is read from SSM at runtime:
//
//   toriino-agora-recording  ← aws-backend/lambda/agora-recording
//   torino-api               ← aws-backend/lambda/torino-api   (npm ci --omit=dev)
//
// For each it: builds a deterministic zip (forward-slash paths, fixed timestamps — never
// Compress-Archive) and uploads it only if the code changed; then edits the env by
// MERGING (adds SSM_PREFIX, removes the plain secret copies that now live in SSM, keeps
// everything else untouched) and applies the stack-managed execution role if one is
// configured. Env values are never printed.
//
// Run after `sam deploy` (it reads the torino-backend stack outputs).
// Usage (from toriino-splash/): node scripts/deploy-legacy-lambdas.mjs [--dry-run]

import fs from 'fs';
import os from 'os';
import path from 'path';
import zlib from 'zlib';
import crypto from 'crypto';
import { execFileSync, execSync } from 'child_process';
import { fileURLToPath } from 'url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REGION = 'us-east-1';
const STACK = 'torino-backend';
const SSM_PREFIX = '/torino/prod/';
const DRY = process.argv.includes('--dry-run');

const TARGETS = [
  {
    name: 'toriino-agora-recording',
    dir: 'aws-backend/lambda/agora-recording',
    removeEnv: ['AGORA_CUSTOMER_ID', 'AGORA_CUSTOMER_SECRET', 'AGORA_APP_CERTIFICATE'],
    roleOutput: 'AgoraRecordingRoleArn',
  },
  {
    name: 'torino-api',
    dir: 'aws-backend/lambda/torino-api',
    npm: true,
    removeEnv: ['GEMINI_API_KEY', 'AGORA_APP_CERTIFICATE'],
    // Non-secret config fixes (values may be printed).
    setEnv: { SESSIONS_TABLE: 'torino-sessions' },
  },
];

function aws(args) {
  const out = execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
    encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 256 * 1024 * 1024,
  });
  return out.trim() ? JSON.parse(out) : {};
}

// ── Minimal deterministic zip writer ────────────────────────
const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = CRC_TABLE[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function listFiles(dir, base = dir) {
  return fs.readdirSync(dir, { withFileTypes: true })
    .sort((a, b) => a.name.localeCompare(b.name))
    .flatMap((e) => {
      const full = path.join(dir, e.name);
      return e.isDirectory() ? listFiles(full, base) : [path.relative(base, full).split(path.sep).join('/')];
    });
}
function buildZip(dir) {
  const DOS_TIME = 0, DOS_DATE = (1 << 5) | 1; // 1980-01-01 00:00 — fixed so the zip is reproducible
  const locals = [], centrals = [];
  let offset = 0;
  for (const name of listFiles(dir)) {
    const data = fs.readFileSync(path.join(dir, name));
    const comp = zlib.deflateRawSync(data, { level: 9 });
    const nameBuf = Buffer.from(name, 'utf8');
    const crc = crc32(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0); local.writeUInt16LE(20, 4); local.writeUInt16LE(0x0800, 6);
    local.writeUInt16LE(8, 8); local.writeUInt16LE(DOS_TIME, 10); local.writeUInt16LE(DOS_DATE, 12);
    local.writeUInt32LE(crc, 14); local.writeUInt32LE(comp.length, 18); local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBuf.length, 26); local.writeUInt16LE(0, 28);
    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0); central.writeUInt16LE(0x0314, 4); central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x0800, 8); central.writeUInt16LE(8, 10); central.writeUInt16LE(DOS_TIME, 12);
    central.writeUInt16LE(DOS_DATE, 14); central.writeUInt32LE(crc, 16); central.writeUInt32LE(comp.length, 20);
    central.writeUInt32LE(data.length, 24); central.writeUInt16LE(nameBuf.length, 28);
    central.writeUInt32LE((0o100644 << 16) >>> 0, 38); central.writeUInt32LE(offset, 42);
    locals.push(local, nameBuf, comp);
    centrals.push(central, nameBuf);
    offset += 30 + nameBuf.length + comp.length;
  }
  const cd = Buffer.concat(centrals);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(centrals.length / 2, 8); end.writeUInt16LE(centrals.length / 2, 10);
  end.writeUInt32LE(cd.length, 12); end.writeUInt32LE(offset, 16);
  return Buffer.concat([...locals, cd, end]);
}

function stage(target) {
  const src = path.join(ROOT, target.dir);
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), `${target.name}-`));
  for (const f of fs.readdirSync(src)) {
    if (f === 'node_modules' || f.endsWith('.zip')) continue;
    fs.cpSync(path.join(src, f), path.join(tmp, f), { recursive: true });
  }
  // Fixed command string (no user input), so running it through the shell is safe.
  if (target.npm) execSync('npm ci --omit=dev --no-audit --no-fund', { cwd: tmp, stdio: 'ignore' });
  return tmp;
}

// ── Deploy ──────────────────────────────────────────────────
const outputs = Object.fromEntries((aws(['cloudformation', 'describe-stacks', '--stack-name', STACK]).Stacks[0].Outputs || [])
  .map((o) => [o.OutputKey, o.OutputValue]));

for (const t of TARGETS) {
  const cfg = aws(['lambda', 'get-function-configuration', '--function-name', t.name]);
  const zip = buildZip(stage(t));
  const sha = crypto.createHash('sha256').update(zip).digest('base64');

  if (sha === cfg.CodeSha256) {
    console.log(`${t.name}: code unchanged`);
  } else {
    console.log(`${DRY ? '[dry-run] would update' : 'updating'} ${t.name} code (${(zip.length / 1048576).toFixed(1)} MB)`);
    if (!DRY) {
      const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'zip-')), `${t.name}.zip`);
      fs.writeFileSync(file, zip);
      aws(['lambda', 'update-function-code', '--function-name', t.name, '--zip-file', `fileb://${file}`]);
      aws(['lambda', 'wait', 'function-updated-v2', '--function-name', t.name]);
    }
  }

  const env = { ...(cfg.Environment?.Variables || {}) };
  const removed = t.removeEnv.filter((k) => k in env);
  for (const k of t.removeEnv) delete env[k];
  const addPrefix = env.SSM_PREFIX !== SSM_PREFIX;
  env.SSM_PREFIX = SSM_PREFIX;
  const changedSet = Object.entries(t.setEnv || {}).filter(([k, v]) => env[k] !== v).map(([k, v]) => `${k}=${v}`);
  Object.assign(env, t.setEnv || {});
  const role = t.roleOutput ? outputs[t.roleOutput] : cfg.Role;
  if (t.roleOutput && !role) throw new Error(`stack output ${t.roleOutput} missing — run sam deploy first`);

  if (!removed.length && !addPrefix && !changedSet.length && role === cfg.Role) {
    console.log(`${t.name}: configuration unchanged`);
    continue;
  }
  console.log(`${DRY ? '[dry-run] would update' : 'updating'} ${t.name} configuration:`
    + `${removed.length ? ` remove env ${removed.join(', ')};` : ''}${addPrefix ? ' set SSM_PREFIX;' : ''}`
    + `${changedSet.length ? ` set ${changedSet.join(', ')};` : ''}`
    + `${role !== cfg.Role ? ` role → ${role.split('/').pop()}` : ''}`);
  if (!DRY) {
    // Env goes through a temp file so no value ever appears on a command line or in output.
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'env-')), 'env.json');
    fs.writeFileSync(file, JSON.stringify({ Variables: env }), { mode: 0o600 });
    try {
      aws(['lambda', 'update-function-configuration', '--function-name', t.name,
        '--environment', `file://${file}`, '--role', role]);
      aws(['lambda', 'wait', 'function-updated-v2', '--function-name', t.name]);
    } finally {
      fs.rmSync(file, { force: true });
    }
  }
}
