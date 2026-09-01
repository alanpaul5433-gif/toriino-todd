const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand } = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const TRANSCRIPTS_TABLE = process.env.TRANSCRIPTS_TABLE || "toriino-transcripts";

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
    // POST /sessions/{id}/transcript
    const saveMatch = path.match(/^\/sessions\/([^/]+)\/transcript$/);
    if (saveMatch && method === "POST") {
      return await saveTranscript(userId, saveMatch[1], body);
    }

    // GET /sessions/{id}/transcript
    if (saveMatch && method === "GET") {
      return await getTranscript(saveMatch[1]);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Transcripts error:", error);
    return response(500, { error: error.message });
  }
};

async function saveTranscript(userId, sessionId, data) {
  const { segments = [], totalDurationSeconds = 0 } = data;
  const now = new Date().toISOString();

  const transcript = {
    sessionId,
    savedBy: userId,
    segments,
    totalDurationSeconds,
    segmentCount: segments.length,
    plainText: segments.map((s) => `[${s.speakerName}]: ${s.text}`).join("\n"),
    createdAt: now,
    updatedAt: now,
  };

  await dynamodb.send(new PutCommand({ TableName: TRANSCRIPTS_TABLE, Item: transcript }));
  return response(201, { message: "Transcript saved", sessionId });
}

async function getTranscript(sessionId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: TRANSCRIPTS_TABLE, Key: { sessionId } })
  );
  if (!result.Item) return response(404, { error: "Transcript not found" });
  return response(200, result.Item);
}
