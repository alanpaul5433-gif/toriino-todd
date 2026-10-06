const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-2";
const REVIEWS_TABLE = process.env.REVIEWS_TABLE || "toriino-reviews";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
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
    if (path === "/reviews" && method === "POST") {
      return await submitReview(userId, body);
    }

    const targetMatch = path.match(/^\/reviews\/([^/]+)$/);
    if (targetMatch && method === "GET") {
      return await getReviews(targetMatch[1]);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Reviews error:", error);
    return response(500, { error: error.message });
  }
};

// ── Get Reviews ────────────────────────────────────────────
async function getReviews(targetId) {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: REVIEWS_TABLE,
      KeyConditionExpression: "targetId = :targetId",
      ExpressionAttributeValues: { ":targetId": targetId },
      ScanIndexForward: false,
    })
  );

  return response(200, { reviews: result.Items, count: result.Count });
}

// ── Submit Review ──────────────────────────────────────────
async function submitReview(reviewerId, data) {
  if (!data.targetId || !data.rating) {
    return response(400, { error: "targetId and rating are required" });
  }

  if (data.rating < 1 || data.rating > 5) {
    return response(400, { error: "rating must be between 1 and 5" });
  }

  // One review per student per target (UNK09)
  const existing = await dynamodb.send(new QueryCommand({
    TableName: REVIEWS_TABLE,
    KeyConditionExpression: "targetId = :tid",
    FilterExpression: "reviewerId = :rid",
    ExpressionAttributeValues: { ":tid": data.targetId, ":rid": reviewerId },
  }));
  if (existing.Count > 0) {
    return response(409, { error: "You have already submitted a review for this." });
  }

  const reviewId = `${Date.now()}_${randomUUID().slice(0, 8)}`;
  const review = {
    targetId: data.targetId,
    reviewId,
    reviewerId,
    rating: data.rating,
    comment: data.comment || "",
    targetType: data.targetType || "mentor", // mentor, teacher, course
    createdAt: new Date().toISOString(),
  };

  await dynamodb.send(
    new PutCommand({ TableName: REVIEWS_TABLE, Item: review })
  );

  return response(201, review);
}
