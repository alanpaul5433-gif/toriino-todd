// Shared adb helpers for the UAT scripts (scripts/uat-login.mjs, scripts/uat-signup-teacher.mjs).
// They drive the Torino debug app on a connected Android device via adb + UIAutomator.
// Secret values are never printed: typeText(…, { secret: true }) hides them, including from
// adb error messages (which would otherwise echo the command line).

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
export const APP = 'com.torino.todd';
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// fail() throws instead of calling process.exit(): on Windows, exiting while fetch sockets or
// readline handles are still closing aborts Node with a UV_HANDLE_CLOSING assertion. run()
// catches it, prints the message, sets the exit code and lets the event loop drain.
export class UatError extends Error {}
export function fail(message) {
  throw new UatError(message);
}
export async function run(main) {
  try {
    await main();
  } catch (e) {
    console.error(`ERROR: ${e instanceof UatError ? e.message : e?.stack || e}`);
    process.exitCode = 1;
  }
}

// Asks a question on the terminal; the readline interface is always closed before returning.
export async function ask(question) {
  const { createInterface } = await import('readline/promises');
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  try {
    return (await rl.question(question)).trim();
  } finally {
    rl.close();
  }
}

// ── .env.test ────────────────────────────────────────────────
export const ENV_FILE = path.join(ROOT, '.env.test');
export function readEnv() {
  if (!fs.existsSync(ENV_FILE)) fail(`${ENV_FILE} not found`);
  return Object.fromEntries(fs.readFileSync(ENV_FILE, 'utf8').split(/\r?\n/)
    .filter((l) => /^[A-Z_][A-Z0-9_]*=/.test(l))
    .map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).trim()]));
}
// Sets or replaces KEY=value lines, keeping every other line as it is.
export function writeEnvKeys(pairs) {
  const lines = fs.existsSync(ENV_FILE) ? fs.readFileSync(ENV_FILE, 'utf8').split(/\r?\n/) : [];
  for (const [k, v] of Object.entries(pairs)) {
    const i = lines.findIndex((l) => l.startsWith(`${k}=`));
    if (i >= 0) lines[i] = `${k}=${v}`;
    else {
      if (lines.length && lines[lines.length - 1] === '') lines.pop();
      lines.push(`${k}=${v}`, '');
    }
  }
  fs.writeFileSync(ENV_FILE, lines.join(os.EOL === '\r\n' ? '\r\n' : '\n'));
}

// ── adb ──────────────────────────────────────────────────────
function findAdb() {
  // An explicit ADB path must exist: never fall back to another adb behind the user's back.
  // (Module load time, outside run(), so this one exits directly; nothing is open yet.)
  if (process.env.ADB) {
    if (!fs.existsSync(process.env.ADB)) {
      console.error(`ERROR: ADB=${process.env.ADB} does not exist`);
      process.exit(1);
    }
    return process.env.ADB;
  }
  const candidates = [
    'C:/AndroidSDK/platform-tools/adb.exe',
    process.env.ANDROID_HOME && path.join(process.env.ANDROID_HOME, 'platform-tools', 'adb.exe'),
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk', 'platform-tools', 'adb.exe'),
  ].filter(Boolean);
  for (const c of candidates) if (fs.existsSync(c)) return c;
  return 'adb'; // fall back to PATH
}
export const ADB = findAdb();

let SERIAL;
export function connect() {
  let out;
  try { out = execFileSync(ADB, ['devices'], { encoding: 'utf8' }); } catch {
    fail(`adb not found or not runnable (${ADB}). Set ADB=<path to adb.exe>.`);
  }
  const devices = out.split(/\r?\n/).slice(1).map((l) => l.trim().split(/\s+/)).filter((p) => p[1] === 'device').map((p) => p[0]);
  if (process.env.ANDROID_SERIAL) {
    if (!devices.includes(process.env.ANDROID_SERIAL)) fail(`device ${process.env.ANDROID_SERIAL} is not connected`);
    SERIAL = process.env.ANDROID_SERIAL;
  } else if (devices.length === 0) {
    fail('adb sees no device. Connect the phone by USB, unlock it, allow USB debugging, then retry.');
  } else {
    SERIAL = devices[0];
    if (devices.length > 1) console.log(`(several devices; using ${SERIAL} — set ANDROID_SERIAL to choose)`);
  }
  return SERIAL;
}

export function adb(args, { secret = false } = {}) {
  try {
    return execFileSync(ADB, ['-s', SERIAL, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 32 << 20 });
  } catch (e) {
    if (secret) fail('an adb command failed (details hidden because it contained a secret)');
    throw e;
  }
}

// ── screen ───────────────────────────────────────────────────
// Every UIAutomator node with its label, class and bounds.
export function nodes() {
  let xml = '';
  for (let i = 0; i < 4 && !xml.includes('<hierarchy'); i++) {
    try {
      adb(['shell', 'uiautomator', 'dump', '/sdcard/uat_ui.xml']);
      xml = adb(['shell', 'cat', '/sdcard/uat_ui.xml']);
    } catch { /* retry */ }
  }
  const out = [];
  for (const m of xml.matchAll(/<node [^>]*?>/g)) {
    const n = m[0];
    const attr = (k) => (n.match(new RegExp(`${k}="([^"]*)"`)) || [])[1] || '';
    const b = attr('bounds').match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
    if (!b) continue;
    const [x1, y1, x2, y2] = b.slice(1).map(Number);
    out.push({
      label: [attr('text'), attr('content-desc')].filter(Boolean).join(' | ').replace(/&amp;/g, '&'),
      cls: attr('class'), x1, y1, x2, y2, x: (x1 + x2) >> 1, y: (y1 + y2) >> 1,
    });
  }
  return out;
}
export const labels = () => nodes().map((n) => n.label).filter(Boolean);
export const editTexts = () => nodes().filter((n) => n.cls === 'android.widget.EditText').sort((a, b) => a.y - b.y || a.x - b.x);

export async function waitFor(re, seconds = 20) {
  const until = Date.now() + seconds * 1000;
  while (Date.now() < until) {
    const n = nodes().find((x) => re.test(x.label));
    if (n) return n;
    await sleep(1500);
  }
  return null;
}

export function tapXY(x, y) { adb(['shell', 'input', 'tap', String(x), String(y)]); }
export function tapLabel(re) {
  const n = nodes().find((x) => re.test(x.label));
  if (!n) fail(`could not find "${re.source}" on screen`);
  tapXY(n.x, n.y);
  return n;
}

// Finds a node whose text or content-desc matches `re` (labels join both; `re` may also be a
// predicate on the node). Hides the keyboard
// first, then swipes up (scrolls down) up to `scrolls` times if it is not visible yet.
export async function findOnScreen(re, { scrolls = 3 } = {}) {
  await hideKeyboard();
  for (let i = 0; ; i++) {
    const n = nodes().find(typeof re === 'function' ? re : (x) => re.test(x.label));
    if (n || i >= scrolls) return n || null;
    adb(['shell', 'input', 'swipe', '360', '1100', '360', '500', '300']);
    await sleep(800);
  }
}

function imeShown() {
  try { return /mInputShown=true|isInputViewShown=true/.test(adb(['shell', 'dumpsys', 'input_method'])); } catch { return false; }
}
export async function hideKeyboard() {
  if (imeShown()) { adb(['shell', 'input', 'keyevent', 'KEYCODE_BACK']); await sleep(600); }
}

// `adb shell input text` goes through the device shell: escape its metacharacters; %s = space.
function escapeForInput(text) {
  if (text.includes('%')) fail('text contains "%", which adb input cannot type reliably');
  return text.replace(/([\\'"`$&|;<>()#*?~!\[\]{}^])/g, '\\$1').replace(/ /g, '%s');
}
export async function clearFocused() {
  adb(['shell', 'input', 'keyevent', 'KEYCODE_MOVE_END']);
  adb(['shell', 'input', 'keyevent', ...Array(64).fill('KEYCODE_DEL')]);
}
export async function typeInto(node, text, { secret = false } = {}) {
  tapXY(node.x, node.y);
  await sleep(500);
  await clearFocused();
  adb(['shell', 'input', 'text', escapeForInput(text)], { secret });
  await sleep(400);
}

export async function launchToLogin() {
  if (await waitFor(/Welcome Back/i, 2)) return;
  adb(['shell', 'am', 'start', '-n', `${APP}/.MainActivity`]);
  if (!(await waitFor(/Welcome Back/i, 25))) {
    fail('the app is not on the login screen. Log out in the app (or clear its data), then retry.');
  }
}
