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
 * Env: SESSIONS_TABLE (PK sessionId)
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const SESSIONS_TABLE = process.env.SESSIONS_TABLE;

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
  return response(200, { sessions, count: sessions.length });
}

async function loadSession(sessionId) {
  const r = await dynamodb.send(new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } }));
  return r.Item || null;
}

async function getSession(userId, claims, sessionId) {
  const s = await loadSession(sessionId);
  if (!s) return response(404, { error: "Session not found" });
  if (!isParticipant(s, userId) && !isAdmin(claims)) return response(403, { error: "Not a participant of this session" });
  return response(200, s);
}

async function createSession(userId, claims, data) {
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
  return response(201, { message: "Session booked", sessionId: session.sessionId, session });
}

async function updateSession(userId, sessionId, data) {
  const s = await loadSession(sessionId);
  if (!s) return response(404, { error: "Session not found" });
  if (!isParticipant(s, userId)) return response(403, { error: "Not a participant of this session" });

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
