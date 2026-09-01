const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const TWINS_TABLE = process.env.TWINS_TABLE || "toriino-ai-twins";
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
    // GET/POST /ai/twins/{userId}
    const twinMatch = path.match(/^\/ai\/twins\/([^/]+)$/);
    if (twinMatch) {
      const targetUserId = twinMatch[1];
      if (method === "GET") return await getTwin(targetUserId);
      if (method === "POST") return await buildOrUpdateTwin(userId, targetUserId, body);
    }

    // POST /ai/twins/{userId}/ask
    const askMatch = path.match(/^\/ai\/twins\/([^/]+)\/ask$/);
    if (askMatch && method === "POST") {
      return await askTwin(askMatch[1], body);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Twins error:", error);
    return response(500, { error: error.message });
  }
};

async function getTwin(targetUserId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: TWINS_TABLE, Key: { userId: targetUserId } })
  );
  if (!result.Item) return response(404, { error: "AI Twin not found" });
  return response(200, result.Item);
}

async function buildOrUpdateTwin(requestorId, targetUserId, data) {
  const { role, name, bio, recentTranscripts = [] } = data;
  if (!role || !name || !bio) return response(400, { error: "role, name, and bio are required" });

  const transcriptBlock = recentTranscripts.length > 0
    ? `\nRecent session transcripts:\n${recentTranscripts.slice(-3).join("\n---\n")}`
    : "";

  const prompt = `You are building an AI Twin persona. Analyze the following bio and transcripts to create a detailed personality profile.
Return a JSON object with exactly these fields:
{
  "personalityProfile": "2-3 sentences describing teaching style, personality, communication patterns",
  "expertiseAreas": ["area1", "area2", "area3"],
  "teachingStyle": "1-2 sentences on how they explain concepts",
  "knowledgeMemory": ["key insight 1", "key insight 2", "key insight 3"]
}

Name: ${name}
Role: ${role}
Bio: ${bio}${transcriptBlock}

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
  const twin = {
    userId: targetUserId,
    builtBy: requestorId,
    role,
    name,
    bio,
    personalityProfile: parsed.personalityProfile || "",
    expertiseAreas: parsed.expertiseAreas || [],
    teachingStyle: parsed.teachingStyle || "",
    knowledgeMemory: parsed.knowledgeMemory || [],
    lastUpdated: now,
    createdAt: now,
  };

  await dynamodb.send(new PutCommand({ TableName: TWINS_TABLE, Item: twin }));
  return response(201, twin);
}

async function askTwin(targetUserId, data) {
  const { question, history = [] } = data;
  if (!question) return response(400, { error: "question is required" });

  const twinResult = await dynamodb.send(
    new GetCommand({ TableName: TWINS_TABLE, Key: { userId: targetUserId } })
  );
  if (!twinResult.Item) return response(404, { error: "AI Twin not found — build it first" });

  const twin = twinResult.Item;
  const systemPrompt = `You are an AI Twin of ${twin.name}, a ${twin.role}.
Personality: ${twin.personalityProfile}
Teaching style: ${twin.teachingStyle}
Expertise: ${twin.expertiseAreas.join(", ")}
Knowledge: ${twin.knowledgeMemory.join("; ")}
Respond exactly as ${twin.name} would, staying fully in character.`;

  const contents = history.slice(-10).map((h) => ({
    role: h.isUser ? "user" : "model",
    parts: [{ text: h.text }],
  }));
  contents.push({ role: "user", parts: [{ text: question }] });

  const geminiResponse = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemPrompt }] },
      contents,
    }),
  });

  if (!geminiResponse.ok) throw new Error(`Gemini API error: ${geminiResponse.status}`);
  const geminiData = await geminiResponse.json();
  const answer = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "I couldn't respond right now. Please try again.";

  return response(200, { answer, twinName: twin.name, twinRole: twin.role });
}
