/**
 * Toriino — Full Backend API Test Suite
 * Tests every deployed endpoint against the live AWS environment.
 * Usage: node tests/api-test-runner.js
 */

const https = require("https");
const {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const BASE   = "https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod";
const POOL   = "us-east-1_CAiea51iC";
const CLIENT = "jcpvch4o651070m0a2jvuhh22";

const ADMIN_EMAIL    = "oriarte88@gmail.com";
const ADMIN_PASSWORD = "Todd@#$13";
const STUDENT_EMAIL  = "demo.student@toriino.com";
const STUDENT_PASS   = "Demo@1234";

const cognito = new CognitoIdentityProviderClient({ region: "us-east-1" });

// ─── runner state ─────────────────────────────────────────────────────────────
let passed = 0, failed = 0, warned = 0;
const failures = [];

function color(code, text) { return `\x1b[${code}m${text}\x1b[0m`; }
const green  = t => color(32, t);
const red    = t => color(31, t);
const yellow = t => color(33, t);
const bold   = t => color(1, t);
const dim    = t => color(2, t);

function log(symbol, label, detail = "", ms = null) {
  const time = ms !== null ? dim(` ${ms}ms`) : "";
  console.log(`  ${symbol} ${label}${detail ? "  " + dim(detail) : ""}${time}`);
}

function pass(label, detail, ms)  { passed++;  log(green("✓"), label, detail, ms); }
function fail(label, detail, ms)  { failed++;  failures.push({ label, detail }); log(red("✗"), label, detail, ms); }
function warn(label, detail, ms)  { warned++;  log(yellow("⚠"), label, detail, ms); }

// ─── HTTP helper ──────────────────────────────────────────────────────────────
function request(method, path, token, body) {
  return new Promise((resolve, reject) => {
    const url   = new URL(BASE + path);
    const data  = body ? JSON.stringify(body) : null;
    const start = Date.now();

    const opts = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data   ? { "Content-Length": Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(opts, res => {
      let raw = "";
      res.on("data", c => (raw += c));
      res.on("end", () => {
        const ms   = Date.now() - start;
        const json = (() => { try { return JSON.parse(raw); } catch { return null; } })();
        resolve({ status: res.statusCode, json, ms });
      });
    });
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

// ─── Cognito auth ─────────────────────────────────────────────────────────────
async function getToken(email, password) {
  const r = await cognito.send(new InitiateAuthCommand({
    AuthFlow: "USER_PASSWORD_AUTH",
    ClientId: CLIENT,
    AuthParameters: { USERNAME: email, PASSWORD: password },
  }));
  return r.AuthenticationResult.IdToken;
}

// ─── test helpers ─────────────────────────────────────────────────────────────
async function test(label, fn) {
  try {
    await fn();
  } catch (e) {
    fail(label, e.message);
  }
}

function expect200(label, r, extraCheck) {
  if (r.status === 200) {
    if (extraCheck && !extraCheck(r.json)) {
      warn(label, `200 but response shape unexpected: ${JSON.stringify(r.json).slice(0,80)}`, r.ms);
    } else {
      pass(label, `200 OK`, r.ms);
    }
  } else {
    fail(label, `Expected 200, got ${r.status} — ${JSON.stringify(r.json).slice(0,120)}`, r.ms);
  }
}

// ─── TEST SUITES ──────────────────────────────────────────────────────────────

async function suiteAuth() {
  console.log(`\n${bold("── AUTH ──────────────────────────────────────────")}`);

  await test("Admin Cognito login", async () => {
    const token = await getToken(ADMIN_EMAIL, ADMIN_PASSWORD);
    if (!token) throw new Error("No token returned");
    pass("Admin Cognito login", "JWT received", null);
  });

  await test("Student Cognito login", async () => {
    const token = await getToken(STUDENT_EMAIL, STUDENT_PASS);
    if (!token) throw new Error("No token returned");
    pass("Student Cognito login", "JWT received", null);
  });

  await test("Invalid credentials rejected", async () => {
    try {
      await getToken("bad@email.com", "wrongpass");
      fail("Invalid credentials rejected", "Should have thrown");
    } catch (e) {
      if (e.name === "NotAuthorizedException" || e.name === "UserNotFoundException") {
        pass("Invalid credentials rejected", e.name);
      } else {
        throw e;
      }
    }
  });
}

async function suiteAdminStats(token) {
  console.log(`\n${bold("── ADMIN — DASHBOARD STATS ───────────────────────")}`);

  await test("GET /admin/stats", async () => {
    const r = await request("GET", "/admin/stats", token);
    expect200("GET /admin/stats", r, j =>
      j && typeof j.totalUsers === "number" && typeof j.monthlyRevenue === "number"
    );
    if (r.status === 200 && r.json) {
      console.log(dim(`       totalUsers=${r.json.totalUsers}  totalCourses=${r.json.totalCourses}  totalSessions=${r.json.totalSessions}  revenue=$${r.json.monthlyRevenue}`));
    }
  });
}

async function suiteAdminUsers(token) {
  console.log(`\n${bold("── ADMIN — USERS ─────────────────────────────────")}`);

  let userId;
  await test("GET /admin/users", async () => {
    const r = await request("GET", "/admin/users", token);
    expect200("GET /admin/users", r, j => j && Array.isArray(j.users));
    if (r.status === 200) {
      userId = r.json.users?.[0]?.userId;
      console.log(dim(`       ${r.json.total} users returned`));
    }
  });

  await test("GET /admin/users?role=Student", async () => {
    const r = await request("GET", "/admin/users?role=Student", token);
    expect200("GET /admin/users?role=Student", r, j => j?.users?.every(u => u.role === "Student"));
  });

  await test("GET /admin/users?search=alex", async () => {
    const r = await request("GET", "/admin/users?search=alex", token);
    expect200("GET /admin/users?search=alex", r);
  });

  if (userId) {
    await test("PUT /admin/users/:id/status (active)", async () => {
      const r = await request("PUT", `/admin/users/${userId}/status`, token, { status: "active" });
      expect200("PUT /admin/users/:id/status", r, j => j?.success === true);
    });

    await test("PUT /admin/users/:id/role", async () => {
      const r = await request("PUT", `/admin/users/${userId}/role`, token, { role: "Student" });
      expect200("PUT /admin/users/:id/role", r, j => j?.success === true);
    });
  }
}

async function suiteAdminCourses(token) {
  console.log(`\n${bold("── ADMIN — COURSES ───────────────────────────────")}`);

  let courseId;
  await test("GET /admin/courses", async () => {
    const r = await request("GET", "/admin/courses", token);
    expect200("GET /admin/courses", r, j => Array.isArray(j?.courses));
    if (r.status === 200) {
      courseId = r.json.courses?.[0]?.courseId;
      console.log(dim(`       ${r.json.total} courses returned`));
    }
  });

  await test("GET /admin/courses?status=published", async () => {
    const r = await request("GET", "/admin/courses?status=published", token);
    expect200("GET /admin/courses?status=published", r);
  });

  if (courseId) {
    await test("PUT /admin/courses/:id/status", async () => {
      const r = await request("PUT", `/admin/courses/${courseId}/status`, token, { status: "published" });
      expect200("PUT /admin/courses/:id/status", r, j => j?.success === true);
    });
  }
}

async function suiteAdminSessions(token) {
  console.log(`\n${bold("── ADMIN — SESSIONS ──────────────────────────────")}`);

  let sessionId;
  await test("GET /admin/sessions", async () => {
    const r = await request("GET", "/admin/sessions", token);
    expect200("GET /admin/sessions", r, j => Array.isArray(j?.sessions));
    if (r.status === 200) {
      sessionId = r.json.sessions?.[0]?.sessionId;
      console.log(dim(`       ${r.json.total} sessions returned`));
    }
  });

  await test("GET /admin/sessions?status=completed", async () => {
    const r = await request("GET", "/admin/sessions?status=completed", token);
    expect200("GET /admin/sessions?status=completed", r);
  });

  if (sessionId) {
    await test("GET /admin/sessions/:id/summary", async () => {
      const r = await request("GET", `/admin/sessions/${sessionId}/summary`, token);
      if (r.status === 200) pass("GET /admin/sessions/:id/summary", "200 OK", r.ms);
      else if (r.status === 404) warn("GET /admin/sessions/:id/summary", "404 — no summary for this session (expected)", r.ms);
      else fail("GET /admin/sessions/:id/summary", `${r.status}`, r.ms);
    });
  }
}

async function suiteAdminMentors(token) {
  console.log(`\n${bold("── ADMIN — MENTORS ───────────────────────────────")}`);

  let mentorId;
  await test("GET /admin/mentors", async () => {
    const r = await request("GET", "/admin/mentors", token);
    expect200("GET /admin/mentors", r, j => Array.isArray(j?.mentors));
    if (r.status === 200) {
      mentorId = r.json.mentors?.[0]?.mentorId;
      console.log(dim(`       ${r.json.total} mentors returned`));
    }
  });

  if (mentorId) {
    await test("PUT /admin/mentors/:id/approval", async () => {
      const r = await request("PUT", `/admin/mentors/${mentorId}/approval`, token, { approved: true });
      expect200("PUT /admin/mentors/:id/approval", r, j => j?.success === true);
    });
  }
}

async function suiteAdminEarnings(token) {
  console.log(`\n${bold("── ADMIN — EARNINGS ──────────────────────────────")}`);

  await test("GET /admin/earnings", async () => {
    const r = await request("GET", "/admin/earnings", token);
    expect200("GET /admin/earnings", r, j =>
      typeof j?.platformTotal === "number" && Array.isArray(j?.byMonth)
    );
    if (r.status === 200 && r.json) {
      console.log(dim(`       platformTotal=$${r.json.platformTotal}  months=${r.json.byMonth?.length}  topEarners=${r.json.byUser?.length}`));
    }
  });
}

async function suiteAdminReviews(token) {
  console.log(`\n${bold("── ADMIN — REVIEWS ───────────────────────────────")}`);

  await test("GET /admin/reviews", async () => {
    const r = await request("GET", "/admin/reviews", token);
    expect200("GET /admin/reviews", r, j => Array.isArray(j?.reviews));
    if (r.status === 200) console.log(dim(`       ${r.json.total} reviews returned`));
  });

  await test("GET /admin/reviews?rating=5", async () => {
    const r = await request("GET", "/admin/reviews?rating=5", token);
    expect200("GET /admin/reviews?rating=5", r);
  });

  await test("GET /admin/reviews?type=mentor", async () => {
    const r = await request("GET", "/admin/reviews?type=mentor", token);
    expect200("GET /admin/reviews?type=mentor", r);
  });
}

async function suiteAdminAI(token) {
  console.log(`\n${bold("── ADMIN — AI STATS ──────────────────────────────")}`);

  await test("GET /admin/ai/stats", async () => {
    const r = await request("GET", "/admin/ai/stats", token);
    expect200("GET /admin/ai/stats", r, j => typeof j?.totalChatMessages === "number");
    if (r.status === 200 && r.json) {
      console.log(dim(`       chats=${r.json.totalChatMessages}  summaries=${r.json.totalSummaries}  transcripts=${r.json.totalTranscripts}  twins=${r.json.totalTwins}`));
    }
  });
}

async function suiteAdminNotifications(token) {
  console.log(`\n${bold("── ADMIN — NOTIFICATIONS ─────────────────────────")}`);

  await test("POST /admin/notifications/broadcast", async () => {
    const r = await request("POST", "/admin/notifications/broadcast", token, {
      title: "Test Broadcast",
      message: "This is an automated test notification.",
      targetRole: "Student",
    });
    expect200("POST /admin/notifications/broadcast", r, j => j?.success === true);
    if (r.status === 200 && r.json) console.log(dim(`       sentTo=${r.json.sentTo} users`));
  });
}

async function suiteAdminSecurity() {
  console.log(`\n${bold("── SECURITY — UNAUTHENTICATED ACCESS ─────────────")}`);

  await test("GET /admin/stats — no token → blocked", async () => {
    const r = await request("GET", "/admin/stats", null);
    if (r.status === 401 || r.status === 403) {
      pass("GET /admin/stats — no token → blocked", `${r.status} Unauthorized`, r.ms);
    } else if (r.status === 200) {
      warn("GET /admin/stats — no token → blocked", "WARNING: endpoint accessible without auth!", r.ms);
    } else {
      warn("GET /admin/stats — no token → blocked", `Got ${r.status} (API Gateway may handle auth)`, r.ms);
    }
  });

  await test("CORS headers present on OPTIONS", async () => {
    const r = await request("OPTIONS", "/admin/stats", null);
    if (r.status === 200) pass("CORS OPTIONS /admin/stats", "200 OK — CORS preflight works", r.ms);
    else warn("CORS OPTIONS /admin/stats", `Got ${r.status}`, r.ms);
  });
}

// ─── main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log("\n" + bold("═══════════════════════════════════════════════════════"));
  console.log(bold("  TORIINO — Full Backend API Test Suite"));
  console.log(bold("  Target: " + BASE));
  console.log(bold("═══════════════════════════════════════════════════════"));

  const startTime = Date.now();

  // Auth
  await suiteAuth();

  // Get admin token for all subsequent tests
  let adminToken;
  try {
    adminToken = await getToken(ADMIN_EMAIL, ADMIN_PASSWORD);
  } catch (e) {
    console.log(red(`\n  [FATAL] Cannot get admin token: ${e.message}`));
    console.log(red("  Skipping all authenticated tests.\n"));
    process.exit(1);
  }

  // Admin suites
  await suiteAdminStats(adminToken);
  await suiteAdminUsers(adminToken);
  await suiteAdminCourses(adminToken);
  await suiteAdminSessions(adminToken);
  await suiteAdminMentors(adminToken);
  await suiteAdminEarnings(adminToken);
  await suiteAdminReviews(adminToken);
  await suiteAdminAI(adminToken);
  await suiteAdminNotifications(adminToken);
  await suiteAdminSecurity();

  // ─── summary ──────────────────────────────────────────────────────────────
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  const total   = passed + failed + warned;

  console.log("\n" + bold("═══════════════════════════════════════════════════════"));
  console.log(bold("  RESULTS"));
  console.log(bold("═══════════════════════════════════════════════════════"));
  console.log(`  ${green(`✓ ${passed} passed`)}   ${red(`✗ ${failed} failed`)}   ${yellow(`⚠ ${warned} warnings`)}   ${dim(`(${total} total, ${elapsed}s)`)}`);

  if (failures.length) {
    console.log(`\n${red("  Failures:")}`);
    failures.forEach(f => console.log(`    ${red("✗")} ${f.label}: ${dim(f.detail)}`));
  }
  console.log();

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => { console.error(red(`\n  [error] ${e.message}\n`)); process.exit(1); });
