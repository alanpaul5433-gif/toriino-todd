const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = "us-east-1";
const USERS_TABLE = process.env.USERS_TABLE || "toriino-users";

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
  const method = event.httpMethod;

  if (method === "OPTIONS") return response(200, {});

  const userId = getUserId(event);
  if (!userId) return response(401, { error: "Unauthorized" });

  // Verify caller role from Cognito claims
  const callerRole = event.requestContext?.authorizer?.claims?.["custom:role"];
  if (!callerRole) return response(403, { error: "Forbidden: no role claim" });

  if (method === "GET") {
    const q = (event.queryStringParameters?.q || "").trim().toLowerCase();
    if (!q || q.length < 2) {
      return response(400, { error: "Query parameter 'q' must be at least 2 characters" });
    }

    try {
      const result = await dynamodb.send(
        new ScanCommand({
          TableName: USERS_TABLE,
          FilterExpression: "#role = :role",
          ExpressionAttributeNames: { "#role": "role" },
          ExpressionAttributeValues: { ":role": "student" },
        })
      );

      const students = (result.Items || [])
        .filter((item) => {
          const name = (item.name || item.displayName || "").toLowerCase();
          const email = (item.email || "").toLowerCase();
          return name.includes(q) || email.includes(q);
        })
        .map((item) => ({
          userId: item.userId,
          displayName: item.name || item.displayName || item.email || "Unknown",
          email: item.email || "",
        }));

      return response(200, { students });
    } catch (error) {
      console.error("Student search error:", error);
      return response(500, { error: error.message });
    }
  }

  return response(404, { error: "Route not found" });
};
