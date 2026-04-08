const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  UpdateCommand,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-2";
const TABLE = process.env.NOTIFICATIONS_TABLE || "toriino-notifications";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PATCH,OPTIONS",
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
    if (path === "/notifications" && method === "GET") {
      return await getNotifications(userId, event.queryStringParameters);
    }

    if (path === "/notifications/fcm-token" && method === "POST") {
      return await registerFcmToken(userId, body);
    }

    const readMatch = path.match(/^\/notifications\/([^/]+)\/read$/);
    if (readMatch && method === "PATCH") {
      return await markAsRead(userId, readMatch[1]);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Notifications error:", error);
    return response(500, { error: error.message });
  }
};

// ── Get Notifications ──────────────────────────────────────
async function getNotifications(userId, queryParams = {}) {
  const { limit = "50" } = queryParams || {};

  const result = await dynamodb.send(
    new QueryCommand({
      TableName: TABLE,
      KeyConditionExpression: "userId = :userId",
      ExpressionAttributeValues: { ":userId": userId },
      ScanIndexForward: false,
      Limit: parseInt(limit),
    })
  );

  return response(200, {
    notifications: result.Items,
    count: result.Count,
  });
}

// ── Mark as Read ───────────────────────────────────────────
async function markAsRead(userId, sortKey) {
  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { userId, sortKey },
      UpdateExpression: "SET #read = :read",
      ExpressionAttributeNames: { "#read": "isRead" },
      ExpressionAttributeValues: { ":read": true },
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Register FCM Token ─────────────────────────────────────
async function registerFcmToken(userId, { fcmToken }) {
  if (!fcmToken) {
    return response(400, { error: "fcmToken is required" });
  }

  // Store FCM token for push notifications (Phase 6)
  // For now, just acknowledge receipt
  return response(200, {
    message: "FCM token registered",
    userId,
  });
}

// ── Create Notification (called by other Lambdas) ──────────
// Export for internal use
exports.createNotification = async function (
  userId,
  { title, message, type, data }
) {
  const sortKey = `${new Date().toISOString()}#${randomUUID().slice(0, 8)}`;

  const notification = {
    userId,
    sortKey,
    title,
    message,
    type: type || "general",
    data: data || {},
    isRead: false,
    createdAt: new Date().toISOString(),
  };

  await dynamodb.send(new PutCommand({ TableName: TABLE, Item: notification }));

  return notification;
};
