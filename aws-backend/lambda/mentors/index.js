/**
 * mentors Lambda — /mentors  (Cognito authorizer on every route)
 *
 *   GET /mentors?expertise=            approved mentors (filter matches expertise or specialties)
 *   GET /mentors/{id}
 *   GET /mentors/{id}/availability     { availability: [...] }
 *   PUT /mentors/availability          caller (a mentor) replaces their own availability
 *
 * Intro videos are uploaded through GET /upload-url?folder=intro-videos.
 *
 * Env: MENTORS_TABLE (PK mentorId)
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  UpdateCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const MENTORS_TABLE = process.env.MENTORS_TABLE;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,PUT,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const MAX_SLOTS = 200;

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!MENTORS_TABLE) return response(503, { error: "Mentors service not configured (MENTORS_TABLE)" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const seg = event.path.split("/").filter(Boolean);
  try {
    if (seg.length === 1 && method === "GET") return await listMentors(event.queryStringParameters || {});
    if (seg.length === 2 && seg[1] === "availability" && method === "PUT") return await setAvailability(userId, claims, body);
    if (seg.length === 2 && seg[1] === "intro-video") {
      return response(410, { error: "Use GET /upload-url?folder=intro-videos to upload an intro video" });
    }
    if (seg.length === 2 && method === "GET") return await getMentor(seg[1]);
    if (seg.length === 3 && seg[2] === "availability" && method === "GET") return await getAvailability(seg[1]);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Mentors handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Mentors request failed" });
  }
};

async function listMentors({ expertise }) {
  const mentors = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new ScanCommand({ TableName: MENTORS_TABLE, ExclusiveStartKey }));
    mentors.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);

  let items = mentors.filter((m) => m.approved !== false);
  if (expertise) {
    const want = String(expertise).toLowerCase();
    items = items.filter((m) => [...(m.expertise || []), ...(m.specialties || [])]
      .some((x) => String(x).toLowerCase() === want));
  }
  return response(200, { mentors: items, count: items.length });
}

async function getMentor(mentorId) {
  const r = await dynamodb.send(new GetCommand({ TableName: MENTORS_TABLE, Key: { mentorId } }));
  if (!r.Item || r.Item.approved === false) return response(404, { error: "Mentor not found" });
  return response(200, r.Item);
}

async function getAvailability(mentorId) {
  const r = await dynamodb.send(new GetCommand({
    TableName: MENTORS_TABLE,
    Key: { mentorId },
    ProjectionExpression: "availability",
  }));
  return response(200, { mentorId, availability: r.Item?.availability || [] });
}

async function setAvailability(userId, claims, { availability }) {
  if (String(claims["custom:role"] || "").toLowerCase() !== "mentor") {
    return response(403, { error: "Only mentors can set availability" });
  }
  if (!Array.isArray(availability)) return response(400, { error: "availability must be an array" });
  if (availability.length > MAX_SLOTS) return response(400, { error: `At most ${MAX_SLOTS} availability slots` });
  if (availability.some((s) => s === null || typeof s !== "object")) {
    return response(400, { error: "Each availability slot must be an object" });
  }

  const now = new Date().toISOString();
  await dynamodb.send(new UpdateCommand({
    TableName: MENTORS_TABLE,
    Key: { mentorId: userId },
    UpdateExpression: "SET availability = :a, updatedAt = :u, createdAt = if_not_exists(createdAt, :u)",
    ExpressionAttributeValues: { ":a": availability, ":u": now },
  }));
  return response(200, { message: "Availability updated", availability });
}
