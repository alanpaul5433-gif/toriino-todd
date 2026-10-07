const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const TWINS_TABLE = process.env.TWINS_TABLE || "toriino-ai-twins";
const GEMINI_MODEL = "gemini-flash-latest";

// ── Secrets: SSM SecureString under SSM_PREFIX (e.g. /torino/prod/), cached 5 min.
// The placeholder NOT_SET (or a missing parameter) means "not configured" → HTTP 503.
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const ssm = new SSMClient({ region: process.env.AWS_REGION || "us-east-1" });
const SECRET_TTL_MS = 5 * 60 * 1000;
const secretCache = {};
async function getSecret(name) {
  const prefix = process.env.SSM_PREFIX;
  if (!prefix) return null;
  const hit = secretCache[name];
  if (hit && Date.now() - hit.at < SECRET_TTL_MS) return hit.value;
  let value = null;
  try {
    const out = await ssm.send(new GetParameterCommand({ Name: `${prefix}${name}`, WithDecryption: true }));
    const raw = out.Parameter?.Value;
    value = raw && raw !== "NOT_SET" ? raw : null;
  } catch (err) {
    if (err.name !== "ParameterNotFound") throw err;
  }
  secretCache[name] = { value, at: Date.now() };
  return value;
}
function notConfigured(message) {
  const err = new Error(message);
  err.code = "NOT_CONFIGURED";
  return err;
}

async function geminiUrl() {
  const key = await getSecret("GEMINI_API_KEY");
  if (!key) throw notConfigured("Gemini not configured");
  return `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${key}`;
}

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
  const sub = event.requestContext?.authorizer?.claims?.sub;
  if (sub) return sub;
  try {
    const auth = event.headers?.Authorization || event.headers?.authorization || '';
    const token = auth.replace(/^Bearer\s+/i, '');
    if (!token) return null;
    return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()).sub || null;
  } catch { return null; }
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
    if (error.code === "NOT_CONFIGURED") return response(503, { error: error.message });
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

  const geminiResponse = await fetch(await geminiUrl(), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
  });

  if (!geminiResponse.ok) {
    const errBody = await geminiResponse.text().catch(() => '');
    throw new Error(`Gemini API error: ${geminiResponse.status} — ${errBody}`);
  }
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

  const geminiResponse = await fetch(await geminiUrl(), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemPrompt }] },
      contents,
    }),
  });

  if (!geminiResponse.ok) {
    const errBody = await geminiResponse.text().catch(() => '');
    throw new Error(`Gemini API error: ${geminiResponse.status} — ${errBody}`);
  }
  const geminiData = await geminiResponse.json();
  const answer = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "I couldn't respond right now. Please try again.";

  return response(200, { answer, twinName: twin.name, twinRole: twin.role });
}
