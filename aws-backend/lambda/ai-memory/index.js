const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const MEMORY_TABLE = process.env.MEMORY_TABLE || "toriino-ai-memory";
const KNOWLEDGE_GRAPH_TABLE = process.env.KNOWLEDGE_GRAPH_TABLE || "toriino-knowledge-graph";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = "gemini-1.5-flash-latest";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,OPTIONS",
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
    // GET/PUT /ai/memory/{userId}
    const memoryMatch = path.match(/^\/ai\/memory\/([^/]+)$/);
    if (memoryMatch) {
      const targetUserId = memoryMatch[1];
      if (targetUserId !== userId) return response(403, { error: "Forbidden" });
      if (method === "GET") return await getMemory(userId);
      if (method === "PUT" || method === "POST") return await updateMemory(userId, body);
    }

    // POST /ai/memory/{userId}/recommend
    const recommendMatch = path.match(/^\/ai\/memory\/([^/]+)\/recommend$/);
    if (recommendMatch && method === "POST") {
      if (recommendMatch[1] !== userId) return response(403, { error: "Forbidden" });
      return await getRecommendations(userId, body);
    }

    // GET/POST /ai/memory/{userId}/graph
    const graphMatch = path.match(/^\/ai\/memory\/([^/]+)\/graph$/);
    if (graphMatch) {
      if (graphMatch[1] !== userId) return response(403, { error: "Forbidden" });
      if (method === "GET") return await getKnowledgeGraph(userId);
      if (method === "POST") return await updateKnowledgeGraph(userId, body);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Memory error:", error);
    return response(500, { error: error.message });
  }
};

async function getMemory(userId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: MEMORY_TABLE, Key: { userId } })
  );
  if (!result.Item) {
    // Return empty memory scaffold for new users
    return response(200, {
      userId,
      learningGoals: [],
      completedTopics: [],
      strengths: [],
      areasForImprovement: [],
      preferredLearningStyle: null,
      sessionCount: 0,
      totalLearningMinutes: 0,
      lastActiveAt: null,
    });
  }
  return response(200, result.Item);
}

async function updateMemory(userId, data) {
  const now = new Date().toISOString();
  const existing = await dynamodb.send(
    new GetCommand({ TableName: MEMORY_TABLE, Key: { userId } })
  );

  const current = existing.Item || { userId, sessionCount: 0, totalLearningMinutes: 0, createdAt: now };
  const updated = {
    ...current,
    learningGoals: data.learningGoals ?? current.learningGoals ?? [],
    completedTopics: data.completedTopics ?? current.completedTopics ?? [],
    strengths: data.strengths ?? current.strengths ?? [],
    areasForImprovement: data.areasForImprovement ?? current.areasForImprovement ?? [],
    preferredLearningStyle: data.preferredLearningStyle ?? current.preferredLearningStyle ?? null,
    sessionCount: (current.sessionCount || 0) + (data.incrementSession ? 1 : 0),
    totalLearningMinutes: (current.totalLearningMinutes || 0) + (data.addMinutes || 0),
    lastActiveAt: now,
    updatedAt: now,
  };

  await dynamodb.send(new PutCommand({ TableName: MEMORY_TABLE, Item: updated }));
  return response(200, updated);
}

async function getRecommendations(userId, data) {
  const memoryResult = await dynamodb.send(
    new GetCommand({ TableName: MEMORY_TABLE, Key: { userId } })
  );
  const memory = memoryResult.Item || {};

  const graphResult = await dynamodb.send(
    new GetCommand({ TableName: KNOWLEDGE_GRAPH_TABLE, Key: { userId } })
  );
  const graph = graphResult.Item || {};

  const { currentTopic, recentActivity } = data;

  const prompt = `You are a personalized learning AI. Based on this learner's profile, suggest 3-5 specific next learning steps.
Return a JSON object: { "recommendations": [{ "title": "...", "description": "...", "type": "topic|practice|review", "priority": "high|medium|low" }] }

Learner Profile:
- Goals: ${(memory.learningGoals || []).join(", ") || "Not specified"}
- Completed Topics: ${(memory.completedTopics || []).join(", ") || "None yet"}
- Strengths: ${(memory.strengths || []).join(", ") || "Unknown"}
- Areas to Improve: ${(memory.areasForImprovement || []).join(", ") || "Unknown"}
- Preferred Style: ${memory.preferredLearningStyle || "Unknown"}
- Sessions Completed: ${memory.sessionCount || 0}
- Knowledge Nodes: ${(graph.nodes || []).slice(0, 10).map((n) => n.topic).join(", ") || "None"}
${currentTopic ? `- Currently studying: ${currentTopic}` : ""}
${recentActivity ? `- Recent activity: ${recentActivity}` : ""}

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

  return response(200, { recommendations: parsed.recommendations || [], generatedAt: new Date().toISOString() });
}

async function getKnowledgeGraph(userId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: KNOWLEDGE_GRAPH_TABLE, Key: { userId } })
  );
  if (!result.Item) return response(200, { userId, nodes: [], edges: [] });
  return response(200, result.Item);
}

async function updateKnowledgeGraph(userId, data) {
  const now = new Date().toISOString();
  const existing = await dynamodb.send(
    new GetCommand({ TableName: KNOWLEDGE_GRAPH_TABLE, Key: { userId } })
  );

  const current = existing.Item || { userId, nodes: [], edges: [], createdAt: now };
  const { addNode, addEdge } = data;

  if (addNode) {
    const nodeExists = current.nodes.find((n) => n.topic === addNode.topic);
    if (!nodeExists) {
      current.nodes.push({ topic: addNode.topic, proficiency: addNode.proficiency || 0, addedAt: now });
    } else {
      nodeExists.proficiency = Math.min(100, (nodeExists.proficiency || 0) + (addNode.proficiencyDelta || 5));
    }
  }

  if (addEdge) {
    const edgeKey = `${addEdge.from}→${addEdge.to}`;
    const edgeExists = current.edges.find((e) => `${e.from}→${e.to}` === edgeKey);
    if (!edgeExists) {
      current.edges.push({ from: addEdge.from, to: addEdge.to, relationship: addEdge.relationship || "related", addedAt: now });
    }
  }

  current.updatedAt = now;
  await dynamodb.send(new PutCommand({ TableName: KNOWLEDGE_GRAPH_TABLE, Item: current }));
  return response(200, current);
}
