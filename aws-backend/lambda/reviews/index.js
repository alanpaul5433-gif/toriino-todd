/**
 * reviews Lambda — /reviews  (Cognito authorizer on every route)
 *
 *   POST /reviews               { targetId, targetType: course|mentor|teacher, rating 1-5, comment }
 *                               one review per reviewer per target (409 on a second one);
 *                               course reviews require an enrollment in that course
 *   GET  /reviews/{targetId}    newest first
 *
 * Env: REVIEWS_TABLE (PK targetId, SK reviewId), ENROLLMENTS_TABLE
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const REVIEWS_TABLE = process.env.REVIEWS_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const TARGET_TYPES = new Set(["course", "mentor", "teacher"]);
const ALREADY_REVIEWED = "You have already submitted a review for this";

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const userId = event.requestContext?.authorizer?.claims?.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!REVIEWS_TABLE || !ENROLLMENTS_TABLE) return response(503, { error: "Reviews service not configured" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const seg = event.path.split("/").filter(Boolean).map((s) => {
    try { return decodeURIComponent(s); } catch { return s; }
  });
  try {
    if (seg.length === 1 && method === "POST") return await submitReview(userId, body);
    if (seg.length === 2 && method === "GET") return await listReviews(seg[1]);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Reviews handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Reviews request failed" });
  }
};

async function queryTarget(targetId, extra = {}) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new QueryCommand({
      TableName: REVIEWS_TABLE,
      KeyConditionExpression: "targetId = :t",
      ExpressionAttributeValues: { ":t": targetId, ...(extra.values || {}) },
      FilterExpression: extra.filter,
      ExclusiveStartKey,
    }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
  return items;
}

async function submitReview(userId, { targetId, targetType, rating, comment }) {
  const type = String(targetType || "").toLowerCase();
  const stars = Number(rating);
  if (!targetId || typeof targetId !== "string") return response(400, { error: "targetId is required" });
  if (!TARGET_TYPES.has(type)) return response(400, { error: "targetType must be course, mentor or teacher" });
  if (!Number.isInteger(stars) || stars < 1 || stars > 5) return response(400, { error: "rating must be an integer from 1 to 5" });
  if (targetId === userId) return response(400, { error: "You cannot review yourself" });

  // Older reviews have random reviewIds, so check by reviewer as well as by the new key.
  const mine = await queryTarget(targetId, {
    filter: "reviewerId = :r OR authorId = :r",
    values: { ":r": userId },
  });
  if (mine.length > 0) return response(409, { error: `${ALREADY_REVIEWED} ${type}` });

  if (type === "course") {
    const enrolled = await dynamodb.send(new ScanCommand({
      TableName: ENROLLMENTS_TABLE,
      FilterExpression: "courseId = :c AND (userId = :u OR studentId = :u)",
      ExpressionAttributeValues: { ":c": targetId, ":u": userId },
      ProjectionExpression: "enrollmentId",
    }));
    let found = (enrolled.Items || []).length > 0;
    let key = enrolled.LastEvaluatedKey;
    while (!found && key) {
      const page = await dynamodb.send(new ScanCommand({
        TableName: ENROLLMENTS_TABLE,
        FilterExpression: "courseId = :c AND (userId = :u OR studentId = :u)",
        ExpressionAttributeValues: { ":c": targetId, ":u": userId },
        ProjectionExpression: "enrollmentId",
        ExclusiveStartKey: key,
      }));
      found = (page.Items || []).length > 0;
      key = page.LastEvaluatedKey;
    }
    if (!found) return response(403, { error: "Only students enrolled in this course can review it" });
  }

  const review = {
    targetId,
    reviewId: `rev_${userId}`, // deterministic: a second write for the same reviewer fails
    reviewerId: userId,
    targetType: type,
    rating: stars,
    comment: typeof comment === "string" ? comment.slice(0, 2000) : "",
    createdAt: new Date().toISOString(),
  };
  try {
    await dynamodb.send(new PutCommand({
      TableName: REVIEWS_TABLE,
      Item: review,
      ConditionExpression: "attribute_not_exists(reviewId)",
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return response(409, { error: `${ALREADY_REVIEWED} ${type}` });
    throw err;
  }
  log("INFO", "Review created", { targetId, reviewerId: userId });
  return response(201, review);
}

async function listReviews(targetId) {
  const reviews = await queryTarget(targetId);
  reviews.sort((a, b) => String(b.createdAt || "").localeCompare(String(a.createdAt || "")));
  const avg = reviews.length ? reviews.reduce((s, r) => s + (Number(r.rating) || 0), 0) / reviews.length : 0;
  return response(200, { reviews, count: reviews.length, averageRating: Math.round(avg * 10) / 10 });
}
