// UAT helper (GATE-03): sign up a brand-new account in the Torino app on the connected phone.
//
//   node scripts/uat-signup-teacher.mjs --email you+tag@example.com   (your own inbox)
//   node scripts/uat-signup-teacher.mjs                               (temporary mail.tm inbox)
//
// Steps: generate a strong random password → save email + password to .env.test as
// UAT_NEW_TEACHER_EMAIL / UAT_NEW_TEACHER_PASSWORD → fill the app's sign-up form and submit →
// get the 6-digit Cognito code (with --email: you type it in this terminal; without: the script
// polls the mail.tm inbox every 10 s, max 3 min) → type it on the verification screen → stop at
// the role-selection screen (the tester chooses Teacher from there).
//
// It never prints the password and never confirms the account any other way (no admin-confirm).
// Run it yourself — it is meant for a human-driven UAT.

import crypto from 'crypto';
import {
  connect, run, ask, adb, launchToLogin, tapLabel, waitFor, editTexts, typeInto, hideKeyboard, tapXY,
  labels, nodes, writeEnvKeys, fail, sleep,
} from './lib/uat-device.mjs';

const MAILTM = 'https://api.mail.tm';
const POLL_EVERY_MS = 10_000;
const POLL_MAX_MS = 180_000;

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--email') out.email = argv[++i];
    else if (a.startsWith('--email=')) out.email = a.slice('--email='.length);
    else fail(`unknown argument "${a}". Usage: node scripts/uat-signup-teacher.mjs [--email <address>]`);
  }
  if ('email' in out && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(out.email || '')) fail('--email needs a valid address');
  return out;
}

async function mailtm(method, p, body, token) {
  let r;
  try {
    r = await fetch(MAILTM + p, {
      method,
      headers: { 'Content-Type': 'application/json', Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    fail(`mail.tm is unreachable (${e.cause?.code || e.message}). Use --email <your address> instead.`);
  }
  const text = await r.text();
  let json = null; try { json = JSON.parse(text); } catch { }
  if (!r.ok) fail(`mail.tm ${method} ${p} → HTTP ${r.status}. Use --email <your address> instead.`);
  return json;
}

// 16 chars with upper, lower, digit and a symbol that adb can type safely.
function strongPassword() {
  const pick = (set, n) => Array.from(crypto.randomBytes(n), (b) => set[b % set.length]).join('');
  const chars = [
    ...pick('ABCDEFGHJKLMNPQRSTUVWXYZ', 3), ...pick('abcdefghijkmnopqrstuvwxyz', 6),
    ...pick('23456789', 4), ...pick('.-_', 3),
  ];
  for (let i = chars.length - 1; i > 0; i--) { const j = crypto.randomInt(i + 1); [chars[i], chars[j]] = [chars[j], chars[i]]; }
  return chars.join('');
}

// Polls the mail.tm inbox for the Cognito code.
async function codeFromMailtm(token) {
  console.log('polling the inbox every 10 s (max 3 min)…');
  const until = Date.now() + POLL_MAX_MS;
  while (Date.now() < until) {
    const msgs = (await mailtm('GET', '/messages', null, token))?.['hydra:member'] || [];
    for (const m of msgs) {
      const full = await mailtm('GET', `/messages/${m.id}`, null, token);
      const hit = `${full?.subject || ''} ${full?.text || ''} ${full?.intro || ''}`.match(/\b(\d{6})\b/);
      if (hit) return hit[1];
    }
    await sleep(POLL_EVERY_MS);
  }
  fail('no verification email arrived within 3 minutes. The account exists but is unconfirmed; it was NOT confirmed any other way.');
}

// Asks the tester for the code, re-asking until it is exactly 6 digits (empty input aborts).
async function codeFromTerminal() {
  for (;;) {
    const code = (await ask('Enter the 6-digit code from your email: ')).replace(/\s+/g, '');
    if (/^\d{6}$/.test(code)) return code;
    if (!code) fail('no code entered. The account exists but is unconfirmed; it was NOT confirmed any other way.');
    console.log('That is not 6 digits — try again (or press Enter to abort).');
  }
}

await run(async () => {
  const args = parseArgs(process.argv.slice(2));

  // ── 1. Device + sign-up screen ─────────────────────────────
  const serial = connect();
  console.log(`device ${serial}`);
  await launchToLogin();
  tapLabel(/Create an account/i);
  if (!(await waitFor(/Create Your Account/i, 15))) fail('the sign-up screen did not open');

  // ── 2. Email + password ────────────────────────────────────
  const password = strongPassword();
  let email;
  let mailToken = null;
  if (args.email) {
    email = args.email;
  } else {
    const domains = (await mailtm('GET', '/domains'))?.['hydra:member'] || [];
    const domain = domains.find((d) => d.isActive && !d.isPrivate)?.domain;
    if (!domain) fail('mail.tm returned no usable domain. Use --email <your address> instead.');
    email = `torino-uat-${crypto.randomBytes(4).toString('hex')}@${domain}`;
    await mailtm('POST', '/accounts', { address: email, password });
    mailToken = (await mailtm('POST', '/token', { address: email, password }))?.token;
    if (!mailToken) fail('mail.tm did not return a token');
  }
  writeEnvKeys({ UAT_NEW_TEACHER_EMAIL: email, UAT_NEW_TEACHER_PASSWORD: password });
  console.log(`signing up ${email}; login saved to .env.test (UAT_NEW_TEACHER_EMAIL / UAT_NEW_TEACHER_PASSWORD)`);

  // ── 3. Fill and submit the form ────────────────────────────
  const f = editTexts(); // name, email, phone, password (top to bottom)
  if (f.length < 4) fail(`expected 4 fields on the sign-up screen, found ${f.length}`);
  await typeInto(f[0], `UAT Teacher ${crypto.randomBytes(2).toString('hex')}`);
  await typeInto(editTexts()[1], email);
  await typeInto(editTexts()[3], password, { secret: true });
  await hideKeyboard();
  const terms = nodes().find((n) => /Agree to/i.test(n.label));
  if (!terms) fail('could not find the "Agree to Terms & Privacy" checkbox');
  tapXY(Math.max(terms.x1 - 30, 10), terms.y); // the round checkbox sits left of the label
  await sleep(500);
  tapLabel(/^Sign Up$/);
  console.log('submitted the sign-up form — waiting for the verification screen…');
  if (!(await waitFor(/Verify Your Email/i, 40))) {
    fail(`the verification screen did not appear. App says: ${labels().slice(-3).join(' / ').slice(0, 200)}`);
  }

  // ── 4. Verification code ───────────────────────────────────
  console.log(`verification screen open — Cognito has emailed a code to ${email}`);
  const code = mailToken ? await codeFromMailtm(mailToken) : await codeFromTerminal();

  // ── 5. Type the code (six one-digit boxes) ─────────────────
  const boxes = editTexts().sort((a, b) => a.x - b.x).slice(0, 6);
  if (boxes.length < 6) fail(`expected 6 code boxes, found ${boxes.length}`);
  for (let i = 0; i < 6; i++) {
    tapXY(boxes[i].x, boxes[i].y);
    await sleep(250);
    adb(['shell', 'input', 'text', code[i]]);
    await sleep(300);
  }
  await hideKeyboard();
  tapLabel(/^Verify$/);
  console.log('tapped Verify — waiting for the role screen…');

  const role = await waitFor(/Teacher|Choose your role|Select.*role/i, 30);
  if (!role) fail(`did not reach the role screen. App says: ${labels().slice(-3).join(' / ').slice(0, 200)}`);
  console.log(`DONE — account ${email} verified; the app is on the role screen. Choose Teacher next.`);
});
