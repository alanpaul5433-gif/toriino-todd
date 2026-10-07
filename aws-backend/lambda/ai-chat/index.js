const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const CHAT_TABLE = process.env.CHAT_TABLE || "toriino-ai-chat";
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
    const match = path.match(/^\/ai\/chat\/([^/]+)$/);
    if (!match) return response(404, { error: "Route not found" });
    const targetUserId = match[1];

    // Users can only access their own chat history
    if (targetUserId !== userId) return response(403, { error: "Forbidden" });

    if (method === "GET") return await getChatHistory(userId, event.queryStringParameters);
    if (method === "POST") return await sendChatMessage(userId, body);

    return response(405, { error: "Method not allowed" });
  } catch (error) {
    console.error("Chat error:", error);
    if (error.code === "NOT_CONFIGURED") return response(503, { error: error.message });
    return response(500, { error: error.message });
  }
};

async function getChatHistory(userId, params) {
  const limit = parseInt(params?.limit || "50");
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: CHAT_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
      ScanIndexForward: false,
      Limit: limit,
    })
  );
  return response(200, { messages: result.Items || [], count: result.Count });
}

async function sendChatMessage(userId, data) {
  const { message, sessionContext, history = [] } = data;
  if (!message) return response(400, { error: "message is required" });

  const now = new Date().toISOString();
  const userMsgId = randomUUID();

  // Build conversation turns from history
  const contents = history.slice(-20).map((h) => ({
    role: h.isUser ? "user" : "model",
    parts: [{ text: h.text }],
  }));
  contents.push({ role: "user", parts: [{ text: message }] });

  const systemInstruction = sessionContext
    ? `You are Toriino AI, an educational assistant. The user is currently in a session about: ${sessionContext}. Help them learn effectively.`
    : "You are Toriino AI, an educational assistant. Help the user learn effectively with clear, encouraging responses.";

  const geminiResponse = await fetch(await geminiUrl(), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemInstruction }] },
      contents,
    }),
  });

  if (!geminiResponse.ok) {
    const errBody = await geminiResponse.text().catch(() => '');
    throw new Error(`Gemini API error: ${geminiResponse.status} — ${errBody}`);
  }
  const geminiData = await geminiResponse.json();
  const aiText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || "I couldn't process that. Please try again.";

  // Save both user message and AI response
  const userMsg = { userId, messageId: userMsgId, text: message, isUser: true, sessionContext: sessionContext || null, timestamp: now };
  const aiMsgId = randomUUID();
  const aiMsg = { userId, messageId: aiMsgId, text: aiText, isUser: false, sessionContext: sessionContext || null, timestamp: new Date().toISOString() };

  await Promise.all([
    dynamodb.send(new PutCommand({ TableName: CHAT_TABLE, Item: userMsg })),
    dynamodb.send(new PutCommand({ TableName: CHAT_TABLE, Item: aiMsg })),
  ]);

  return response(201, { userMessage: userMsg, aiMessage: aiMsg });
}
