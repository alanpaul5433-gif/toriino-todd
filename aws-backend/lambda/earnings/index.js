const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-2";
const TABLE = process.env.EARNINGS_TABLE || "toriino-earnings";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
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
  const userId = getUserId(event);

  if (method === "OPTIONS") return response(200, {});
  if (!userId) return response(401, { error: "Unauthorized" });

  try {
    if (path === "/earnings" && method === "GET") {
      return await getEarningsSummary(userId);
    }
    if (path === "/earnings/history" && method === "GET") {
      return await getEarningsHistory(userId, event.queryStringParameters);
    }
    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Earnings error:", error);
    return response(500, { error: error.message });
  }
};

// ── Earnings Summary ───────────────────────────────────────
async function getEarningsSummary(userId) {
  const now = new Date();
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

  const result = await dynamodb.send(
    new QueryCommand({
      TableName: TABLE,
      KeyConditionExpression: "userId = :userId",
      ExpressionAttributeValues: { ":userId": userId },
      ScanIndexForward: false,
      Limit: 12,
    })
  );

  const allEarnings = result.Items || [];
  const currentMonthData = allEarnings.find(
    (e) => e.periodKey === currentMonth
  );
  const totalEarnings = allEarnings.reduce(
    (sum, e) => sum + (e.amount || 0),
    0
  );

  return response(200, {
    currentMonth: currentMonthData || { amount: 0, sessions: 0 },
    totalEarnings,
    monthlyBreakdown: allEarnings,
  });
}

// ── Earnings History ───────────────────────────────────────
async function getEarningsHistory(userId, queryParams = {}) {
  const { limit = "12" } = queryParams || {};

  const result = await dynamodb.send(
    new QueryCommand({
      TableName: TABLE,
      KeyConditionExpression: "userId = :userId",
      ExpressionAttributeValues: { ":userId": userId },
      ScanIndexForward: false,
      Limit: parseInt(limit),
    })
  );

  return response(200, { history: result.Items, count: result.Count });
}
