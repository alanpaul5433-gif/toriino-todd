const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const SUMMARIES_TABLE = process.env.SUMMARIES_TABLE || "toriino-session-summaries";
const TRANSCRIPTS_TABLE = process.env.TRANSCRIPTS_TABLE || "toriino-transcripts";
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
// ── Premium gate (configurable, no redeploy) ─────────────────────────────────
// SSM String PREMIUM_FEATURES (JSON list of feature keys) says which features need an
// active subscription. Empty list → nothing gated. The subscription record is written only
// by the Stripe webhook (SUBSCRIPTIONS_TABLE, PK userId); the app's view is never trusted.
const { GetCommand: GateGetCommand } = require("@aws-sdk/lib-dynamodb");
let premiumFeaturesCache;
async function premiumFeatures() {
  if (premiumFeaturesCache && Date.now() - premiumFeaturesCache.at < 5 * 60 * 1000) return premiumFeaturesCache.value;
  let value = [];
  try {
    const out = await ssm.send(new GetParameterCommand({ Name: `${process.env.SSM_PREFIX}PREMIUM_FEATURES` }));
    const parsed = JSON.parse(out.Parameter?.Value || "[]");
    value = Array.isArray(parsed) ? parsed.map(String) : [];
  } catch (err) {
    if (err.name !== "ParameterNotFound") console.error(JSON.stringify({ level: "ERROR", message: "PREMIUM_FEATURES unreadable", error: err.message }));
  }
  premiumFeaturesCache = { value, at: Date.now() };
  return value;
}
// Returns an HTTP response to send when the caller may not use `feature`, else null.
async function requirePremium(userId, feature) {
  if (!(await premiumFeatures()).includes(feature)) return null;
  const table = process.env.SUBSCRIPTIONS_TABLE;
  if (!table) return response(503, { error: "Subscriptions not configured" });
  const { Item: r } = await dynamodb.send(new GateGetCommand({ TableName: table, Key: { userId } }));
  const active = r && r.premium === true && ["active", "trialing"].includes(r.status)
    && (!r.currentPeriodEnd || Date.parse(r.currentPeriodEnd) > Date.now());
  return active ? null : response(402, { error: "premium required", feature });
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
    const match = path.match(/^\/sessions\/([^/]+)\/summary$/);
    if (!match) return response(404, { error: "Route not found" });
    const sessionId = match[1];

    if (method === "GET") return await getSummary(sessionId);
    if (method === "POST") {
      const gate = await requirePremium(userId, "ai_summary");
      if (gate) return gate;
      return await createSummary(userId, sessionId, body);
    }

    return response(405, { error: "Method not allowed" });
  } catch (error) {
    console.error("Summaries error:", error);
    if (error.code === "NOT_CONFIGURED") return response(503, { error: error.message });
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
