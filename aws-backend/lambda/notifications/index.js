/**
 * notifications Lambda — /notifications  (Cognito authorizer on every route)
 *
 *   GET   /notifications                  caller's notifications, newest first (+ unreadCount)
 *   PATCH /notifications/{sortKey}/read   mark one as read (sortKey URL-encoded by the app)
 *   PATCH /notifications/read-all         mark all of the caller's notifications as read
 *
 * (POST /notifications/fcm-token is routed to the register-device Lambda.)
 *
 * Env: NOTIFICATIONS_TABLE (PK userId, SK sortKey)
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  QueryCommand,
  UpdateCommand,
} = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const NOTIFICATIONS_TABLE = process.env.NOTIFICATIONS_TABLE;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,PATCH,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const userId = event.requestContext?.authorizer?.claims?.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!NOTIFICATIONS_TABLE) return response(503, { error: "Notifications service not configured" });

  // The sortKey contains '#' and ':', so it arrives percent-encoded.
  const seg = event.path.split("/").filter(Boolean).map((s) => {
    try { return decodeURIComponent(s); } catch { return s; }
  });

  try {
    if (seg.length === 1 && method === "GET") return await list(userId);
    if (seg.length === 2 && seg[1] === "read-all" && method === "PATCH") return await markAllRead(userId);
    if (seg.length === 3 && seg[2] === "read" && method === "PATCH") return await markRead(userId, seg[1]);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Notifications handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Notifications request failed" });
  }
};

async function queryAll(userId) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new QueryCommand({
      TableName: NOTIFICATIONS_TABLE,
      KeyConditionExpression: "userId = :u",
      ExpressionAttributeValues: { ":u": userId },
      ScanIndexForward: false,
      ExclusiveStartKey,
    }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
  return items;
}

// Older rows use `read`/`body`/`type`, newer ones `isRead`/`message`/`notifType`: return both.
function normalize(n) {
  const isRead = (n.isRead ?? n.read) === true;
  return {
    ...n,
    isRead,
    read: isRead,
    message: n.message ?? n.body ?? "",
    body: n.body ?? n.message ?? "",
    type: n.type ?? n.notifType ?? "general",
  };
}

async function list(userId) {
  const notifications = (await queryAll(userId)).map(normalize);
  const unreadCount = notifications.filter((n) => !n.isRead).length;
  return response(200, { notifications, count: notifications.length, unreadCount });
}

async function markRead(userId, sortKey) {
  if (!sortKey) return response(400, { error: "sortKey is required" });
  try {
    await dynamodb.send(new UpdateCommand({
      TableName: NOTIFICATIONS_TABLE,
      Key: { userId, sortKey },
      UpdateExpression: "SET isRead = :t, #read = :t, readAt = :now",
      ConditionExpression: "attribute_exists(sortKey)",
      ExpressionAttributeNames: { "#read": "read" },
      ExpressionAttributeValues: { ":t": true, ":now": new Date().toISOString() },
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return response(404, { error: "Notification not found" });
    throw err;
  }
  return response(200, { message: "Marked as read", sortKey });
}

async function markAllRead(userId) {
  const unread = (await queryAll(userId)).filter((n) => (n.isRead ?? n.read) !== true);
  const now = new Date().toISOString();
  for (const n of unread) {
    await dynamodb.send(new UpdateCommand({
      TableName: NOTIFICATIONS_TABLE,
      Key: { userId, sortKey: n.sortKey },
      UpdateExpression: "SET isRead = :t, #read = :t, readAt = :now",
      ExpressionAttributeNames: { "#read": "read" },
      ExpressionAttributeValues: { ":t": true, ":now": now },
    }));
  }
  return response(200, { message: "All marked as read", updated: unread.length });
}
