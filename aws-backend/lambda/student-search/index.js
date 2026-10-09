/**
 * student-search Lambda — GET /students/search?q=  (Cognito authorizer)
 *
 * Mentors/teachers look up students by name or email when scheduling a 1-on-1.
 * Returns only userId, displayName and email.
 *
 * Env: USERS_TABLE
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const USERS_TABLE = process.env.USERS_TABLE;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

const ALLOWED_CALLERS = new Set(["mentor", "teacher", "admin"]);
const MAX_RESULTS = 20;

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  if (!claims.sub) return response(401, { error: "Unauthorized" });

  const callerRole = String(claims["custom:role"] || "").toLowerCase();
  if (!ALLOWED_CALLERS.has(callerRole)) {
    return response(403, { error: "Only mentors and teachers can search students" });
  }
  if (method !== "GET") return response(404, { error: "Route not found" });
  if (!USERS_TABLE) return response(503, { error: "Student search not configured (USERS_TABLE)" });

  const q = (event.queryStringParameters?.q || "").trim().toLowerCase();
  if (q.length < 2) return response(400, { error: "Query parameter 'q' must be at least 2 characters" });

  try {
    const students = [];
    let ExclusiveStartKey;
    do {
      const page = await dynamodb.send(new ScanCommand({
        TableName: USERS_TABLE,
        ProjectionExpression: "userId, #n, displayName, email, #r",
        ExpressionAttributeNames: { "#n": "name", "#r": "role" },
        ExclusiveStartKey,
      }));
      for (const item of page.Items || []) {
        if (String(item.role || "").toLowerCase() !== "student") continue;
        const name = String(item.name || item.displayName || "").toLowerCase();
        const email = String(item.email || "").toLowerCase();
        if (name.includes(q) || email.includes(q)) {
          students.push({
            userId: item.userId,
            displayName: item.name || item.displayName || item.email || "Unknown",
            email: item.email || "",
          });
        }
      }
      ExclusiveStartKey = page.LastEvaluatedKey;
    } while (ExclusiveStartKey && students.length < MAX_RESULTS);

    return response(200, { students: students.slice(0, MAX_RESULTS) });
  } catch (error) {
    console.error(JSON.stringify({ level: "ERROR", message: "Student search failed", error: error.message }));
    return response(500, { error: "Student search failed" });
  }
};
