const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-2";
const SESSIONS_TABLE = process.env.SESSIONS_TABLE || "toriino-sessions";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

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

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Sessions error:", error);
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
