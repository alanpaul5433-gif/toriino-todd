// UAT helper: log in to the Torino app on the connected phone with a test account.
//
//   node scripts/uat-login.mjs <student|teacher|mentor|admin|newteacher>
//
// Reads that role's login from .env.test (TEST_<ROLE>_EMAIL / TEST_<ROLE>_PASSWORD; for
// "newteacher": UAT_NEW_TEACHER_EMAIL / UAT_NEW_TEACHER_PASSWORD), types it on the login screen
// via adb and taps Login. The password is never printed. Run it yourself — it is meant for a
// human-driven UAT where the tester (not an assistant) performs the sign-in.
//
// Needs: USB debugging on, the app installed, the app on the login screen (it is launched if closed).

import {
  connect, run, readEnv, launchToLogin, editTexts, typeInto, hideKeyboard, tapLabel, waitFor, labels, fail, sleep,
} from './lib/uat-device.mjs';

const ROLES = {
  student: ['TEST_STUDENT_EMAIL', 'TEST_STUDENT_PASSWORD'],
  teacher: ['TEST_TEACHER_EMAIL', 'TEST_TEACHER_PASSWORD'],
  mentor: ['TEST_MENTOR_EMAIL', 'TEST_MENTOR_PASSWORD'],
  admin: ['TEST_ADMIN_EMAIL', 'TEST_ADMIN_PASSWORD'],
  newteacher: ['UAT_NEW_TEACHER_EMAIL', 'UAT_NEW_TEACHER_PASSWORD'],
};

await run(async () => {
  const role = (process.argv[2] || '').toLowerCase();
  if (!ROLES[role]) fail(`usage: node scripts/uat-login.mjs <${Object.keys(ROLES).join('|')}>`);

  const env = readEnv();
  const [emailKey, passKey] = ROLES[role];
  const email = env[emailKey];
  const password = env[passKey];
  if (!email || !password) fail(`${emailKey} / ${passKey} are not set in .env.test`);

  const serial = connect();
  console.log(`device ${serial} — logging in as ${role} (${email})`);
  await launchToLogin();

  const fields = editTexts();
  if (fields.length < 2) fail('could not find the email and password fields on the login screen');
  await typeInto(fields[0], email);
  await typeInto(editTexts()[1] || fields[1], password, { secret: true });
  console.log(`typed email and password (${password.length} characters, hidden)`);
  await hideKeyboard();
  tapLabel(/^Login$/);
  console.log('tapped Login — waiting for the next screen…');

  const left = await (async () => {
    for (let i = 0; i < 20; i++) {
      await sleep(1500);
      if (!labels().some((l) => /Welcome Back/i.test(l))) return true;
    }
    return false;
  })();
  if (!left) {
    const shown = labels().filter((l) => !/Welcome Back|Log in to explore|Forgot|Create an account|New here|^Login$/i.test(l));
    fail(`still on the login screen after 30 s${shown.length ? ` — app says: ${shown.join(' / ').slice(0, 200)}` : ''}`);
  }
  await waitFor(/./, 5);
  console.log(`DONE — logged in as ${role}. Now on: ${labels().slice(0, 4).join(' / ').slice(0, 160)}`);
});
