const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const CHAT_TABLE = process.env.CHAT_TABLE || "toriino-ai-chat";
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

  const geminiResponse = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemInstruction }] },
      contents,
    }),
  });

  if (!geminiResponse.ok) throw new Error(`Gemini API error: ${geminiResponse.status}`);
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
