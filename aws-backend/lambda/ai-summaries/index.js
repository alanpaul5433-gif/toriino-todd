const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const SUMMARIES_TABLE = process.env.SUMMARIES_TABLE || "toriino-session-summaries";
const TRANSCRIPTS_TABLE = process.env.TRANSCRIPTS_TABLE || "toriino-transcripts";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = "gemini-1.5-flash-latest";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

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
    const match = path.match(/^\/sessions\/([^/]+)\/summary$/);
    if (!match) return response(404, { error: "Route not found" });
    const sessionId = match[1];

    if (method === "GET") return await getSummary(sessionId);
    if (method === "POST") return await createSummary(userId, sessionId, body);

    return response(405, { error: "Method not allowed" });
  } catch (error) {
    console.error("Summaries error:", error);
    return response(500, { error: error.message });
  }
};

async function getSummary(sessionId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: SUMMARIES_TABLE, Key: { sessionId } })
  );
  if (!result.Item) return response(404, { error: "Summary not found" });
  return response(200, result.Item);
}

async function createSummary(userId, sessionId, data) {
  let { transcript, subjectArea } = data;

  // If no transcript provided, fetch it from the transcripts table
  if (!transcript) {
    const transcriptResult = await dynamodb.send(
      new GetCommand({ TableName: TRANSCRIPTS_TABLE, Key: { sessionId } })
    );
    if (!transcriptResult.Item) return response(404, { error: "No transcript found for session" });
    transcript = transcriptResult.Item.plainText;
  }

  const prompt = `You are an expert educational AI. Analyze this session transcript and return a JSON object with exactly these fields:
{
  "summary": "2-3 paragraph summary of the session",
  "actionItems": ["action 1", "action 2"],
  "keyTopics": ["topic 1", "topic 2"],
  "insights": ["insight 1", "insight 2"]
}
${subjectArea ? `Subject area: ${subjectArea}` : ""}
Transcript:
${transcript}
Return ONLY valid JSON.`;

  const geminiResponse = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
  });

  if (!geminiResponse.ok) throw new Error(`Gemini API error: ${geminiResponse.status}`);

  const geminiData = await geminiResponse.json();
  const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
  const cleaned = rawText.replace(/```json\n?|\n?```/g, "").trim();
  const parsed = JSON.parse(cleaned);

  const now = new Date().toISOString();
  const summary = {
    sessionId,
    savedBy: userId,
    summary: parsed.summary || "",
    actionItems: parsed.actionItems || [],
    keyTopics: parsed.keyTopics || [],
    insights: parsed.insights || [],
    subjectArea: subjectArea || null,
    generatedAt: now,
    createdAt: now,
  };

  await dynamodb.send(new PutCommand({ TableName: SUMMARIES_TABLE, Item: summary }));
  return response(201, summary);
}
