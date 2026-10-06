const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");
const { SNSClient, PublishCommand, CreatePlatformEndpointCommand } = require("@aws-sdk/client-sns");
const { randomUUID, createHmac } = require("crypto");

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const REGION = process.env.AWS_REGION || "us-east-1";
const SESSIONS_TABLE = process.env.SESSIONS_TABLE || "toriino-sessions";
const DEVICES_TABLE = process.env.DEVICES_TABLE || "toriino-devices";
const AGORA_APP_ID = process.env.AGORA_APP_ID || "";
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || "";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);
const snsClient = new SNSClient({ region: REGION });

async function sendPush(userId, title, body) {
  try {
    // Query all device tokens for the user, sorted by updatedAt desc
    const devicesResult = await dynamodb.send(new QueryCommand({
      TableName: DEVICES_TABLE,
      KeyConditionExpression: 'userId = :uid',
      ExpressionAttributeValues: { ':uid': userId },
    }));

    if (!devicesResult.Items || devicesResult.Items.length === 0) {
      log('INFO', 'sendPush: no device tokens found', { userId });
      return;
    }

    // Pick the most recently updated token
    const sorted = devicesResult.Items.slice().sort((a, b) => {
      const ta = a.updatedAt || '';
      const tb = b.updatedAt || '';
      return tb.localeCompare(ta);
    });
    const fcmToken = sorted[0].token;

    if (!process.env.SNS_PLATFORM_APP_ARN) {
      log('WARN', 'sendPush: SNS_PLATFORM_APP_ARN not set, skipping delivery', { userId, title });
      return;
    }

    // Create/get platform endpoint for this token
    const endpointRes = await snsClient.send(new CreatePlatformEndpointCommand({
      PlatformApplicationArn: process.env.SNS_PLATFORM_APP_ARN,
      Token: fcmToken,
    }));

    // Publish the notification
    await snsClient.send(new PublishCommand({
      TargetArn: endpointRes.EndpointArn,
      MessageStructure: 'json',
      Message: JSON.stringify({
        GCM: JSON.stringify({
          notification: { title, body },
          data: {},
        }),
      }),
    }));

    log('INFO', 'sendPush: notification sent', { userId, title });
  } catch (e) {
    log('ERROR', 'sendPush error', { error: e.message });
  }
}

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function getUserId(event) {
  return event.requestContext?.authorizer?.claims?.sub;
}

exports.handler = async (event) => {
  const path = event.path;
  const method = event.httpMethod;
  const body = event.body ? JSON.parse(event.body) : {};
  const userId = getUserId(event);

  if (method === "OPTIONS") return response(200, {});
  if (!userId) return response(401, { error: "Unauthorized" });

  try {
    if (path === "/sessions" && method === "GET") {
      return await listSessions(userId, event.queryStringParameters);
    }
    if (path === "/sessions" && method === "POST") {
      return await bookSession(userId, body);
    }

    const sessionIdMatch = path.match(/^\/sessions\/([^/]+)$/);
    if (sessionIdMatch) {
      const sessionId = sessionIdMatch[1];
      if (method === "GET") return await getSession(sessionId);
      if (method === "PUT") return await updateSession(userId, sessionId, body);
    }

    const statusMatch = path.match(/^\/sessions\/([^/]+)\/status$/);
    if (statusMatch && method === "PATCH") {
      return await updateSessionStatus(userId, statusMatch[1], body);
    }

    if (path === "/sessions/token" && method === "POST") {
      return generateAgoraToken(body);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    log('ERROR', 'Sessions handler error', { error: error.message, path, method });
    return response(500, { error: error.message });
  }
};

// ── List Sessions ──────────────────────────────────────────
async function listSessions(userId, queryParams = {}) {
  const { role = "student" } = queryParams || {};
  const indexName = role === "mentor" ? "mentor-index" : "student-index";
  const keyField = role === "mentor" ? "mentorId" : "studentId";

  const result = await dynamodb.send(
    new QueryCommand({
      TableName: SESSIONS_TABLE,
      IndexName: indexName,
      KeyConditionExpression: `${keyField} = :userId`,
      ExpressionAttributeValues: { ":userId": userId },
      ScanIndexForward: false,
    })
  );

  return response(200, { sessions: result.Items, count: result.Count });
}

// ── Get Session ────────────────────────────────────────────
async function getSession(sessionId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } })
  );
  if (!result.Item) return response(404, { error: "Session not found" });
  return response(200, result.Item);
}

// ── Book Session ───────────────────────────────────────────
async function bookSession(studentId, data) {
  if (!data.mentorId || !data.dateTime) {
    return response(400, {
      error: "mentorId and dateTime are required",
    });
  }

  const sessionId = randomUUID();
  const now = new Date().toISOString();

  const session = {
    sessionId,
    studentId,
    mentorId: data.mentorId,
    dateTime: data.dateTime,
    duration: data.duration || 60,
    topic: data.topic || "",
    notes: data.notes || "",
    status: "scheduled",
    meetingLink: "",
    createdAt: now,
    updatedAt: now,
  };

  await dynamodb.send(
    new PutCommand({ TableName: SESSIONS_TABLE, Item: session })
  );

  log('INFO', 'Session booked', { sessionId, studentId, mentorId: data.mentorId, dateTime: data.dateTime });

  // Non-fatal push notification
  try { await sendPush(studentId, 'Session Booked', `Your session is confirmed.`); } catch {}

  return response(201, session);
}

// ── Update Session (reschedule) ────────────────────────────
async function updateSession(userId, sessionId, data) {
  const existing = await dynamodb.send(
    new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } })
  );
  if (!existing.Item) return response(404, { error: "Session not found" });
  if (
    existing.Item.studentId !== userId &&
    existing.Item.mentorId !== userId
  ) {
    return response(403, { error: "Not authorized" });
  }

  const parts = [];
  const values = {};
  const names = {};

  for (const field of ["dateTime", "duration", "topic", "notes"]) {
    if (data[field] !== undefined) {
      parts.push(`#${field} = :${field}`);
      values[`:${field}`] = data[field];
      names[`#${field}`] = field;
    }
  }
  parts.push("#updatedAt = :updatedAt");
  values[":updatedAt"] = new Date().toISOString();
  names["#updatedAt"] = "updatedAt";

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: SESSIONS_TABLE,
      Key: { sessionId },
      UpdateExpression: `SET ${parts.join(", ")}`,
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Generate Agora RTC Token ───────────────────────────────
// Implements Agora AccessToken v1 (006) using only Node.js built-ins.
function generateAgoraToken({ channelName, uid = 0, role = "publisher", expireSeconds = 3600 }) {
  if (!channelName) return response(400, { error: "channelName is required" });
  if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
    return response(500, { error: "Agora credentials not configured" });
  }

  const ROLE_PUBLISHER = 1;
  const uidStr = uid === 0 ? "" : String(uid);
  const salt = (Math.random() * 0xFFFFFFFF) >>> 0;
  const ts = (Math.floor(Date.now() / 1000) + expireSeconds) >>> 0;

  const privs = [[1, ts]]; // kJoinChannel
  if (role === "publisher") privs.push([2, ts], [3, ts], [4, ts]); // audio/video/data

  function pu16(n) { const b = Buffer.alloc(2); b.writeUInt16LE(n >>> 0); return b; }
  function pu32(n) { const b = Buffer.alloc(4); b.writeUInt32LE(n >>> 0); return b; }

  const privParts = [pu16(privs.length)];
  for (const [k, v] of privs) { privParts.push(pu16(k), pu32(v)); }
  const msgBuf = Buffer.concat([pu32(salt), pu32(ts), ...privParts]);

  const sig = createHmac("sha256", AGORA_APP_CERTIFICATE)
    .update(Buffer.concat([
      Buffer.from(AGORA_APP_ID),
      Buffer.from(channelName),
      Buffer.from(uidStr),
      msgBuf,
    ]))
    .digest();

  // Inline CRC32 (IEEE 802.3 polynomial)
  function crc32(buf) {
    let c = 0xFFFFFFFF;
    for (const byte of buf) {
      let x = (c ^ byte) & 0xFF;
      for (let i = 0; i < 8; i++) x = (x & 1) ? 0xEDB88320 ^ (x >>> 1) : x >>> 1;
      c = x ^ (c >>> 8);
    }
    return (c ^ 0xFFFFFFFF) >>> 0;
  }

  const content = Buffer.concat([
    pu16(sig.length), sig,
    pu32(crc32(Buffer.from(channelName))),
    pu32(crc32(Buffer.from(uidStr))),
    pu16(msgBuf.length), msgBuf,
  ]);

  const token = "006" + AGORA_APP_ID + content.toString("base64");
  return response(200, { token, channelName, uid, appId: AGORA_APP_ID });
}

// ── Update Session Status ──────────────────────────────────
async function updateSessionStatus(userId, sessionId, { status }) {
  const validStatuses = [
    "scheduled",
    "in_progress",
    "completed",
    "cancelled",
  ];
  if (!status || !validStatuses.includes(status)) {
    return response(400, {
      error: `status must be one of: ${validStatuses.join(", ")}`,
    });
  }

  const existing = await dynamodb.send(
    new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } })
  );
  if (!existing.Item) return response(404, { error: "Session not found" });
  if (
    existing.Item.studentId !== userId &&
    existing.Item.mentorId !== userId
  ) {
    return response(403, { error: "Not authorized" });
  }

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: SESSIONS_TABLE,
      Key: { sessionId },
      UpdateExpression:
        "SET #status = :status, #updatedAt = :updatedAt",
      ExpressionAttributeNames: {
        "#status": "status",
        "#updatedAt": "updatedAt",
      },
      ExpressionAttributeValues: {
        ":status": status,
        ":updatedAt": new Date().toISOString(),
      },
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}
