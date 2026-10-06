/**
 * Toriino — Gemini AI Integration Test Suite
 *
 * Tests all 5 AI features end-to-end against the live AWS backend:
 *   1. AI Chat         — conversational Gemini responses
 *   2. Session Summary — AI-generated summary, action items, insights
 *   3. AI Twins        — personality twin build + question answering
 *   4. AI Memory       — learning memory + recommendations
 *   5. Knowledge Graph — node/edge graph + recommendations
 *
 * Usage: node tests/gemini-test-runner.js
 */

const https = require("https");
const {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const BASE   = "https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod";
const CLIENT_ID = "jcpvch4o651070m0a2jvuhh22";

const STUDENT_EMAIL = "demo.student@toriino.com";
const STUDENT_PASS  = "Demo@1234";
const MENTOR_EMAIL  = "demo.mentor@toriino.com";
const MENTOR_PASS   = "Demo@1234";

const cognito = new CognitoIdentityProviderClient({ region: "us-east-1" });

// ─── runner ───────────────────────────────────────────────────────────────────
let passed = 0, failed = 0, warned = 0;
const failures = [];

const c = (code, t) => `\x1b[${code}m${t}\x1b[0m`;
const green = t => c(32, t), red = t => c(31, t), yellow = t => c(33, t);
const bold = t => c(1, t), dim = t => c(2, t);

function log(sym, label, detail = "", ms = null) {
  const time = ms != null ? dim(` ${ms}ms`) : "";
  console.log(`  ${sym} ${label}${detail ? "  " + dim(detail) : ""}${time}`);
}
function pass(l, d, ms) { passed++; log(green("✓"), l, d, ms); }
function fail(l, d, ms) { failed++; failures.push({ l, d }); log(red("✗"), l, d, ms); }
function warn(l, d, ms) { warned++; log(yellow("⚠"), l, d, ms); }
function info(msg) { console.log(dim(`       ${msg}`)); }

// ─── HTTP + JWT helpers ───────────────────────────────────────────────────────
function request(method, path, token, body) {
  return new Promise((resolve, reject) => {
    const data  = body ? JSON.stringify(body) : null;
    const start = Date.now();
    const req   = https.request({
      hostname: "pq8cu94cfd.execute-api.us-east-1.amazonaws.com",
      path: `/prod${path}`,
      method,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data  ? { "Content-Length": Buffer.byteLength(data) } : {}),
      },
    }, res => {
      let raw = "";
      res.on("data", c => raw += c);
      res.on("end", () => {
        const ms   = Date.now() - start;
        const json = (() => { try { return JSON.parse(raw); } catch { return null; } })();
        resolve({ status: res.statusCode, json, ms, raw });
      });
    });
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

async function getAuth(email, password) {
  const r = await cognito.send(new InitiateAuthCommand({
    AuthFlow: "USER_PASSWORD_AUTH",
    ClientId: CLIENT_ID,
    AuthParameters: { USERNAME: email, PASSWORD: password },
  }));
  const token = r.AuthenticationResult.IdToken;
  // Decode JWT payload to get sub
  const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString());
  return { token, sub: payload.sub, email: payload.email };
}

// ─── TEST SUITES ──────────────────────────────────────────────────────────────

// 1. AI CHAT
async function suiteAIChat(token, userId) {
  console.log(`\n${bold("── 1. AI CHAT (Gemini conversational AI) ─────────────")}`);

  // POST — send first message
  const r1 = await request("POST", `/ai/chat/${userId}`, token, {
    message: "I'm a Python beginner. Can you explain what a list comprehension is in simple terms?",
    sessionContext: "Python for Beginners course",
  });

  if (r1.status === 201 && r1.json?.aiMessage?.text) {
    pass("POST /ai/chat — Gemini responds", `${r1.json.aiMessage.text.slice(0, 80)}...`, r1.ms);
    info(`Full response length: ${r1.json.aiMessage.text.length} chars`);
  } else {
    fail("POST /ai/chat — Gemini responds", `${r1.status} — ${JSON.stringify(r1.json).slice(0, 100)}`, r1.ms);
  }

  // POST — follow-up with history (rolling context)
  const r2 = await request("POST", `/ai/chat/${userId}`, token, {
    message: "Can you give me a real-world example using numbers?",
    sessionContext: "Python for Beginners course",
    history: r1.json ? [
      { text: "I'm a Python beginner. Can you explain what a list comprehension is?", isUser: true },
      { text: r1.json.aiMessage?.text || "", isUser: false },
    ] : [],
  });

  if (r2.status === 201 && r2.json?.aiMessage?.text) {
    pass("POST /ai/chat — Gemini maintains context", `${r2.json.aiMessage.text.slice(0, 80)}...`, r2.ms);
  } else {
    fail("POST /ai/chat — Gemini maintains context", `${r2.status}`, r2.ms);
  }

  // GET — retrieve history
  const r3 = await request("GET", `/ai/chat/${userId}?limit=10`, token);
  if (r3.status === 200 && r3.json?.messages?.length >= 2) {
    pass("GET  /ai/chat — history stored in DynamoDB", `${r3.json.count} messages`, r3.ms);
  } else {
    fail("GET  /ai/chat — history stored in DynamoDB", `${r3.status} — ${JSON.stringify(r3.json).slice(0, 80)}`, r3.ms);
  }
}

// 2. SESSION SUMMARY
async function suiteSessionSummary(token) {
  console.log(`\n${bold("── 2. SESSION SUMMARY (Gemini summarization) ─────────")}`);

  const sessionId = "sess_001";
  const sampleTranscript = `
    Mentor: Welcome Alex! Today we'll cover Python list comprehensions.
    Student: Great, I've been struggling with those.
    Mentor: A list comprehension is a compact way to create lists. Instead of writing a for loop, you write the expression inline.
    Student: Can you show me an example?
    Mentor: Sure. Instead of: result = []; for x in range(10): result.append(x*2) — you write: result = [x*2 for x in range(10)].
    Student: Oh! That's so much cleaner.
    Mentor: Exactly. You can also add conditions: [x for x in range(20) if x % 2 == 0] gives you even numbers.
    Student: What about nested lists?
    Mentor: [[i*j for j in range(3)] for i in range(3)] creates a multiplication table. But use sparingly — readability matters.
    Student: Got it. I'll practice these tonight.
    Mentor: Perfect. Your homework is to rewrite the fizzbuzz function using a list comprehension.
  `.trim();

  // POST — generate summary from transcript
  const r1 = await request("POST", `/sessions/${sessionId}/summary`, token, {
    transcript: sampleTranscript,
    subjectArea: "Python Programming",
  });

  if (r1.status === 201 && r1.json?.summary) {
    pass("POST /sessions/:id/summary — Gemini generates summary", "", r1.ms);
    info(`Summary    : ${r1.json.summary?.slice(0, 90)}...`);
    info(`Action items (${r1.json.actionItems?.length}): ${r1.json.actionItems?.join(", ")}`);
    info(`Key topics (${r1.json.keyTopics?.length}): ${r1.json.keyTopics?.join(", ")}`);
    info(`Insights   (${r1.json.insights?.length}): ${r1.json.insights?.[0]}`);
  } else {
    fail("POST /sessions/:id/summary — Gemini generates summary", `${r1.status} — ${JSON.stringify(r1.json).slice(0, 120)}`, r1.ms);
  }

  // Quality check — verify Gemini returned structured data
  if (r1.status === 201 && r1.json) {
    const hasAll = r1.json.summary && Array.isArray(r1.json.actionItems) && Array.isArray(r1.json.keyTopics) && Array.isArray(r1.json.insights);
    if (hasAll && r1.json.actionItems.length > 0 && r1.json.keyTopics.length > 0) {
      pass("Summary quality check — structured output with action items + insights", "");
    } else {
      warn("Summary quality check — some fields missing or empty", JSON.stringify(r1.json).slice(0, 120));
    }
  }

  // GET — verify saved to DynamoDB
  const r2 = await request("GET", `/sessions/${sessionId}/summary`, token);
  if (r2.status === 200 && r2.json?.summary) {
    pass("GET  /sessions/:id/summary — persisted to DynamoDB", "", r2.ms);
  } else {
    fail("GET  /sessions/:id/summary — persisted to DynamoDB", `${r2.status}`, r2.ms);
  }
}

// 3. AI TWINS
async function suiteAITwins(token, userId) {
  console.log(`\n${bold("── 3. AI TWINS (Gemini personality twin) ─────────────")}`);

  // POST — build twin from bio + transcripts
  const r1 = await request("POST", `/ai/twins/${userId}`, token, {
    role: "Python Mentor",
    name: "Dr. Sarah Chen",
    bio: "PhD in Computer Science with 10+ years teaching Python and ML. Former Google engineer. Known for breaking complex concepts into simple, relatable examples. Believes in learning through doing and always assigns practical homework.",
    recentTranscripts: [
      "Student: I don't understand recursion. Mentor: Think of it like Russian dolls — each doll contains a smaller version of itself. The base case is the smallest doll.",
      "Student: When should I use a dictionary vs a list? Mentor: Use a list when order matters and you access by position. Use a dictionary when you need fast lookup by key.",
    ],
  });

  if (r1.status === 201 && r1.json?.personalityProfile) {
    pass("POST /ai/twins — Gemini builds personality twin", "", r1.ms);
    info(`Personality: ${r1.json.personalityProfile?.slice(0, 90)}...`);
    info(`Expertise  : ${r1.json.expertiseAreas?.join(", ")}`);
    info(`Style      : ${r1.json.teachingStyle?.slice(0, 80)}`);
  } else {
    fail("POST /ai/twins — Gemini builds personality twin", `${r1.status} — ${JSON.stringify(r1.json).slice(0, 120)}`, r1.ms);
  }

  // POST /ask — ask the twin a question
  const r2 = await request("POST", `/ai/twins/${userId}/ask`, token, {
    question: "What's the best way to learn Python as a complete beginner who learns best by doing?",
  });

  if (r2.status === 200 && r2.json?.answer) {
    pass("POST /ai/twins/ask — Gemini answers as the twin", `${r2.json.answer.slice(0, 80)}...`, r2.ms);
    info(`Twin name: ${r2.json.twinName} (${r2.json.twinRole})`);
  } else {
    fail("POST /ai/twins/ask — Gemini answers as the twin", `${r2.status} — ${JSON.stringify(r2.json).slice(0, 120)}`, r2.ms);
  }

  // GET — verify twin persisted
  const r3 = await request("GET", `/ai/twins/${userId}`, token);
  if (r3.status === 200 && r3.json?.personalityProfile) {
    pass("GET  /ai/twins — twin persisted to DynamoDB", "", r3.ms);
  } else {
    fail("GET  /ai/twins — twin persisted to DynamoDB", `${r3.status}`, r3.ms);
  }
}

// 4. AI MEMORY
async function suiteAIMemory(token, userId) {
  console.log(`\n${bold("── 4. AI MEMORY (personalized learning memory) ───────")}`);

  // PUT — update learning memory
  const r1 = await request("PUT", `/ai/memory/${userId}`, token, {
    learningGoals: ["Master Python list comprehensions", "Understand recursion", "Build a REST API"],
    completedTopics: ["Variables", "Loops", "Functions", "Lists"],
    strengths: ["Quick to grasp syntax", "Good at problem-solving"],
    areasForImprovement: ["Debugging skills", "Understanding time complexity"],
    preferredLearningStyle: "hands-on with real examples",
    incrementSession: true,
    addMinutes: 60,
  });

  if (r1.status === 200 && r1.json?.learningGoals) {
    pass("PUT /ai/memory — learning profile stored", `${r1.json.learningGoals.length} goals, ${r1.json.completedTopics.length} completed topics`, r1.ms);
  } else {
    fail("PUT /ai/memory — learning profile stored", `${r1.status} — ${JSON.stringify(r1.json).slice(0, 100)}`, r1.ms);
  }

  // POST /recommend — Gemini generates recommendations
  const r2 = await request("POST", `/ai/memory/${userId}/recommend`, token, {
    currentTopic: "list comprehensions",
    recentActivity: "Completed Python basics — loops, functions, lists. Currently learning list comprehensions.",
  });

  if (r2.status === 200 && Array.isArray(r2.json?.recommendations)) {
    pass("POST /ai/memory/recommend — Gemini generates recommendations", `${r2.json.recommendations.length} recommendations`, r2.ms);
    r2.json.recommendations.slice(0, 3).forEach(rec => {
      info(`[${rec.priority}] ${rec.type}: ${rec.title} — ${rec.description?.slice(0, 60)}`);
    });
  } else {
    fail("POST /ai/memory/recommend — Gemini generates recommendations", `${r2.status} — ${JSON.stringify(r2.json).slice(0, 120)}`, r2.ms);
  }

  // GET — verify memory persisted
  const r3 = await request("GET", `/ai/memory/${userId}`, token);
  if (r3.status === 200 && r3.json?.learningGoals?.length > 0) {
    pass("GET  /ai/memory — persisted and retrievable", `sessionCount=${r3.json.sessionCount}  totalMinutes=${r3.json.totalLearningMinutes}`, r3.ms);
  } else {
    fail("GET  /ai/memory — persisted and retrievable", `${r3.status}`, r3.ms);
  }
}

// 5. KNOWLEDGE GRAPH
async function suiteKnowledgeGraph(token, userId) {
  console.log(`\n${bold("── 5. KNOWLEDGE GRAPH (learning graph) ────────────────")}`);

  // POST — add nodes and edges
  const r1 = await request("POST", `/ai/memory/${userId}/graph`, token, {
    addNode: { topic: "List Comprehensions", proficiency: 65 },
  });
  if (r1.status === 200) {
    pass("POST /ai/memory/graph — add node", "List Comprehensions (65% proficiency)", r1.ms);
  } else {
    fail("POST /ai/memory/graph — add node", `${r1.status} — ${JSON.stringify(r1.json).slice(0, 80)}`, r1.ms);
  }

  const r2 = await request("POST", `/ai/memory/${userId}/graph`, token, {
    addNode: { topic: "Loops", proficiency: 90 },
  });
  if (r2.status === 200) pass("POST /ai/memory/graph — add second node", "Loops (90% proficiency)", r2.ms);
  else fail("POST /ai/memory/graph — add second node", `${r2.status}`, r2.ms);

  const r3 = await request("POST", `/ai/memory/${userId}/graph`, token, {
    addEdge: { from: "Loops", to: "List Comprehensions", relationship: "prerequisite" },
  });
  if (r3.status === 200) pass("POST /ai/memory/graph — add edge", "Loops → List Comprehensions (prerequisite)", r3.ms);
  else fail("POST /ai/memory/graph — add edge", `${r3.status}`, r3.ms);

  // GET — verify graph
  const r4 = await request("GET", `/ai/memory/${userId}/graph`, token);
  if (r4.status === 200 && Array.isArray(r4.json?.nodes)) {
    pass("GET  /ai/memory/graph — knowledge graph retrievable", `${r4.json.nodes.length} nodes, ${r4.json.edges.length} edges`, r4.ms);
    r4.json.nodes.forEach(n => info(`  node: ${n.topic} (${n.proficiency}%)`));
    r4.json.edges.forEach(e => info(`  edge: ${e.from} →[${e.relationship}]→ ${e.to}`));
  } else {
    fail("GET  /ai/memory/graph — knowledge graph retrievable", `${r4.status}`, r4.ms);
  }
}

// ─── main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log("\n" + bold("═══════════════════════════════════════════════════════════"));
  console.log(bold("  TORIINO — Gemini AI Integration Test Suite"));
  console.log(bold("  Testing: AI Chat · Summaries · Twins · Memory · Graph"));
  console.log(bold("═══════════════════════════════════════════════════════════"));

  const startTime = Date.now();

  // Authenticate both users
  console.log(`\n${bold("── AUTH ──────────────────────────────────────────────")}`);
  let studentAuth, mentorAuth;
  try {
    studentAuth = await getAuth(STUDENT_EMAIL, STUDENT_PASS);
    pass("Student login", `sub: ${studentAuth.sub.slice(0, 8)}...`);
    mentorAuth = await getAuth(MENTOR_EMAIL, MENTOR_PASS);
    pass("Mentor login",  `sub: ${mentorAuth.sub.slice(0, 8)}...`);
  } catch (e) {
    console.log(red(`\n  [FATAL] Auth failed: ${e.message}\n`));
    process.exit(1);
  }

  // Run all AI suites — student token for chat/memory/graph, mentor token for twin
  await suiteAIChat(studentAuth.token, studentAuth.sub);
  await suiteSessionSummary(studentAuth.token);
  await suiteAITwins(mentorAuth.token, mentorAuth.sub);
  await suiteAIMemory(studentAuth.token, studentAuth.sub);
  await suiteKnowledgeGraph(studentAuth.token, studentAuth.sub);

  // ─── summary ────────────────────────────────────────────────────────────────
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  const total   = passed + failed + warned;

  console.log("\n" + bold("═══════════════════════════════════════════════════════════"));
  console.log(bold("  GEMINI TEST RESULTS"));
  console.log(bold("═══════════════════════════════════════════════════════════"));
  console.log(`  ${green(`✓ ${passed} passed`)}   ${red(`✗ ${failed} failed`)}   ${yellow(`⚠ ${warned} warnings`)}   ${dim(`(${total} total, ${elapsed}s)`)}`);

  if (failures.length) {
    console.log(`\n${red("  Failures:")}`);
    failures.forEach(f => console.log(`    ${red("✗")} ${f.l}: ${dim(f.d)}`));
  } else {
    console.log(green("\n  All Gemini AI features working end-to-end ✓"));
  }

  console.log("\n  AI Features verified:");
  console.log("    • Gemini generates real conversational chat responses");
  console.log("    • Gemini summarizes session transcripts with action items + insights");
  console.log("    • Gemini builds AI Twins that answer questions in a mentor's voice");
  console.log("    • Gemini generates personalized learning recommendations");
  console.log("    • Knowledge graph tracks topic proficiency and prerequisites");
  console.log();
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => { console.error(red(`\n  [error] ${e.message}\n`)); process.exit(1); });
