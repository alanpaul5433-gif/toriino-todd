/**
 * sessions Lambda — /sessions  (Cognito authorizer on every route)
 *
 *   GET   /sessions?role=student|mentor|teacher  ONLY the caller's sessions
 *                                    student → sessions they booked (studentId)
 *                                    mentor/teacher → sessions they host (mentorId/teacherId)
 *   POST  /sessions                  book (student, with mentorId) or create (mentor/teacher)
 *   GET   /sessions/{id}             participants and admins only
 *   PUT   /sessions/{id}             participants only; whitelisted fields
 *   PATCH /sessions/{id}/status      participants only
 *
 * POST /sessions/token (Agora), /recording, /transcript and /summary have their own routes.
 *
 * Money is set by the server: a student booking is priced from the mentor's hourlyRate ×
 * duration (the client's price is ignored); only the host may change price/currency, and
 * never after payment. Responses add studentName / mentorName (display names only) and
 * `pricing` { currency, price, platformFeePercent, platformFee, teacherShare } from
 * PLATFORM_FEE_PERCENT (SSM String). The app never computes money.
 *
 * Env: SESSIONS_TABLE (PK sessionId), USERS_TABLE, MENTORS_TABLE, SSM_PREFIX
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  ScanCommand,
  BatchGetCommand,
} = require("@aws-sdk/lib-dynamodb");
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const SESSIONS_TABLE = process.env.SESSIONS_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;
const MENTORS_TABLE = process.env.MENTORS_TABLE;
const ssm = new SSMClient({ region: REGION });

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const STATUSES = new Set([
  "scheduled", "confirmed", "active", "in_progress", "completed", "cancelled", "payment_failed", "refunded",
]);
const EDITABLE = [
  "title", "topic", "description", "notes", "dateTime", "duration", "price", "currency",
  "meetingLink", "maxParticipants", "sessionType", "courseId",
];

function isAdmin(claims) {
  const g = claims["cognito:groups"];
  if (!g) return false;
  const list = Array.isArray(g) ? g : String(g).replace(/[[\]]/g, "").split(/[\s,]+/);
  return list.includes("Admins");
}

const isParticipant = (s, userId) => [s.studentId, s.mentorId, s.teacherId].includes(userId);

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!SESSIONS_TABLE) return response(503, { error: "Sessions service not configured (SESSIONS_TABLE)" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const seg = event.path.split("/").filter(Boolean);
  const sessionId = seg[1];
  try {
    if (seg.length === 1 && method === "GET") return await listSessions(userId, event.queryStringParameters || {});
    if (seg.length === 1 && method === "POST") return await createSession(userId, claims, body);
    if (seg.length === 2 && method === "GET") return await getSession(userId, claims, sessionId);
    if (seg.length === 2 && method === "PUT") return await updateSession(userId, sessionId, body);
    if (seg.length === 3 && seg[2] === "status" && (method === "PATCH" || method === "PUT")) {
      return await updateStatus(userId, sessionId, body);
    }
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Sessions handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Sessions request failed" });
  }
};

async function listSessions(userId, { role }) {
  const r = String(role || "").toLowerCase();
  let filter;
  if (r === "student") filter = "studentId = :u";
  else if (r === "mentor" || r === "teacher") filter = "mentorId = :u OR teacherId = :u";
  else filter = "studentId = :u OR mentorId = :u OR teacherId = :u";

  const sessions = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new ScanCommand({
      TableName: SESSIONS_TABLE,
      FilterExpression: filter,
      ExpressionAttributeValues: { ":u": userId },
      ExclusiveStartKey,
    }));
    sessions.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);

  sessions.sort((a, b) => String(b.dateTime || "").localeCompare(String(a.dateTime || "")));
  return response(200, { sessions: await decorate(sessions), count: sessions.length });
}

async function loadSession(sessionId) {
  const r = await dynamodb.send(new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } }));
  return r.Item || null;
}

async function getSession(userId, claims, sessionId) {
  const s = await loadSession(sessionId);
  if (!s) return response(404, { error: "Session not found" });
  if (!isParticipant(s, userId) && !isAdmin(claims)) return response(403, { error: "Not a participant of this session" });
  return response(200, (await decorate([s]))[0]);
}

async function createSession(userId, claims, input) {
  let data = input;
  if (!data.dateTime || Number.isNaN(Date.parse(data.dateTime))) {
    return response(400, { error: "dateTime (ISO 8601) is required" });
  }

  const role = String(claims["custom:role"] || "").toLowerCase();
  let mentorId;
  let studentId;
  if (data.mentorId && data.mentorId !== userId) {
    // A student booking a mentor: the student is always the caller.
    if (data.studentId && data.studentId !== userId) {
      return response(403, { error: "Students can only book sessions for themselves" });
    }
    mentorId = data.mentorId;
    studentId = userId;
    const { Item: mentor } = await dynamodb.send(new GetCommand({ TableName: MENTORS_TABLE, Key: { mentorId } }));
    if (!mentor || mentor.approved === false) return response(404, { error: "Mentor not found" });
    const minutes = data.duration === undefined ? 60 : Number(data.duration);
    if (!Number.isInteger(minutes) || minutes < 15 || minutes > 480) {
      return response(400, { error: "duration must be 15–480 minutes" });
    }
    // The client's price/currency are ignored for a student booking.
    data = { ...data, duration: minutes, price: Math.round(((Number(mentor.hourlyRate) || 0) * minutes) / 60 * 100) / 100, currency: "usd" };
  } else {
    // A mentor/teacher creating a 1-on-1 (with studentId) or a group session.
    if (!["mentor", "teacher"].includes(role) && !isAdmin(claims)) {
      return response(403, { error: "Only mentors and teachers can create sessions; students must pass mentorId" });
    }
    mentorId = userId;
    studentId = data.studentId || undefined;
    if (studentId === userId) return response(400, { error: "studentId cannot be the host" });
  }

  const session = { sessionId: `ses_${randomUUID()}`, mentorId, status: "scheduled" };
  if (studentId) session.studentId = studentId;
  for (const f of EDITABLE) if (data[f] !== undefined) session[f] = data[f];
  if (session.price !== undefined) session.price = Number(session.price) || 0;
  if (session.duration !== undefined) session.duration = Number(session.duration) || 0;
  session.createdAt = new Date().toISOString();

  await dynamodb.send(new PutCommand({
    TableName: SESSIONS_TABLE,
    Item: session,
    ConditionExpression: "attribute_not_exists(sessionId)",
  }));
  log("INFO", "Session created", { sessionId: session.sessionId, mentorId, studentId });
  return response(201, { message: "Session booked", sessionId: session.sessionId, session: (await decorate([session]))[0] });
}

async function updateSession(userId, sessionId, data) {
  const s = await loadSession(sessionId);
  if (!s) return response(404, { error: "Session not found" });
  if (!isParticipant(s, userId)) return response(403, { error: "Not a participant of this session" });

  const isHost = s.mentorId === userId || s.teacherId === userId;
  for (const f of ["price", "currency"]) {
    if (data[f] === undefined) continue;
    if (!isHost) return response(403, { error: "Only the host can change the price" });
    if (s.paymentStatus === "paid") return response(409, { error: "The price cannot change after payment" });
  }

  const sets = [];
  const names = {};
  const values = {};
  for (const f of EDITABLE) {
    if (data[f] === undefined) continue;
    sets.push(`#${f} = :${f}`);
    names[`#${f}`] = f;
    values[`:${f}`] = f === "price" || f === "duration" ? Number(data[f]) || 0 : data[f];
  }
  if (data.status !== undefined) {
    if (!STATUSES.has(data.status)) return response(400, { error: `status must be one of: ${[...STATUSES].join(", ")}` });
    sets.push("#status = :status");
    names["#status"] = "status";
    values[":status"] = data.status;
  }
  if (sets.length === 0) return response(400, { error: "No valid fields to update" });
  sets.push("updatedAt = :u");
  values[":u"] = new Date().toISOString();

  const result = await dynamodb.send(new UpdateCommand({
    TableName: SESSIONS_TABLE,
    Key: { sessionId },
    UpdateExpression: `SET ${sets.join(", ")}`,
    ConditionExpression: "attribute_exists(sessionId)",
    ExpressionAttributeNames: names,
    ExpressionAttributeValues: values,
    ReturnValues: "ALL_NEW",
  }));
  return response(200, { message: "Session updated", session: result.Attributes });
}

async function updateStatus(userId, sessionId, { status }) {
  if (!STATUSES.has(status)) return response(400, { error: `status must be one of: ${[...STATUSES].join(", ")}` });
  const s = await loadSession(sessionId);
  if (!s) return response(404, { error: "Session not found" });
  if (!isParticipant(s, userId)) return response(403, { error: "Not a participant of this session" });

  const now = new Date().toISOString();
  const extra = status === "completed" ? ", completedAt = :now" : "";
  await dynamodb.send(new UpdateCommand({
    TableName: SESSIONS_TABLE,
    Key: { sessionId },
    UpdateExpression: `SET #s = :s, updatedAt = :now${extra}`,
    ConditionExpression: "attribute_exists(sessionId)",
    ExpressionAttributeNames: { "#s": "status" },
    ExpressionAttributeValues: { ":s": status, ":now": now },
  }));
  return response(200, { message: "Status updated", sessionId, status });
}

// ── Response decoration: display names + server-computed pricing ──────────────
let feeCache;
async function platformFeePercent() {
  if (process.env.PLATFORM_FEE_PERCENT) return Number(process.env.PLATFORM_FEE_PERCENT);
  if (feeCache && Date.now() - feeCache.at < 5 * 60 * 1000) return feeCache.value;
  const out = await ssm.send(new GetParameterCommand({ Name: `${process.env.SSM_PREFIX}PLATFORM_FEE_PERCENT` }));
  const pct = Number(out.Parameter?.Value);
  if (!Number.isFinite(pct) || pct < 0 || pct > 100) throw new Error("invalid PLATFORM_FEE_PERCENT");
  feeCache = { value: pct, at: Date.now() };
  return pct;
}

async function batchNames(table, keyName, ids) {
  const names = {};
  if (!table || ids.length === 0) return names;
  for (let i = 0; i < ids.length; i += 100) {
    let request = { [table]: { Keys: ids.slice(i, i + 100).map((id) => ({ [keyName]: id })),
      ProjectionExpression: `${keyName}, #n`, ExpressionAttributeNames: { "#n": "name" } } };
    for (let attempt = 0; request && Object.keys(request).length && attempt < 5; attempt++) {
      const r = await dynamodb.send(new BatchGetCommand({ RequestItems: request }));
      for (const row of r.Responses?.[table] || []) if (row.name) names[row[keyName]] = row.name;
      request = r.UnprocessedKeys;
    }
  }
  return names;
}

async function decorate(sessions) {
  if (sessions.length === 0) return sessions;
  let names = {};
  try {
    const ids = [...new Set(sessions.flatMap((x) => [x.studentId, x.mentorId, x.teacherId]).filter(Boolean))];
    names = await batchNames(USERS_TABLE, "userId", ids);
    // Some mentors only have a mentor listing, not a profile row.
    const missing = ids.filter((id) => !names[id]);
    Object.assign(names, await batchNames(MENTORS_TABLE, "mentorId", missing));
  } catch (err) {
    log("WARN", "Session name lookup failed", { error: err.message });
  }
  let pct = null;
  try { pct = await platformFeePercent(); } catch (err) {
    log("WARN", "Platform fee unavailable — pricing omitted", { error: err.message });
  }
  return sessions.map((x) => {
    const out = { ...x };
    if (x.studentId && names[x.studentId]) out.studentName = names[x.studentId];
    const host = x.mentorId || x.teacherId;
    if (host && names[host]) out.mentorName = names[host];
    if (pct !== null && x.price !== undefined) {
      const cents = Math.round((Number(x.price) || 0) * 100);
      const fee = Math.round((cents * pct) / 100);
      out.pricing = { currency: (x.currency || "usd").toLowerCase(), price: cents / 100, platformFeePercent: pct,
        platformFee: fee / 100, teacherShare: (cents - fee) / 100 };
    }
    return out;
  });
}
