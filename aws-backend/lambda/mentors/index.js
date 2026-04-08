const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-2";
const MENTORS_TABLE = process.env.MENTORS_TABLE || "toriino-mentors";
const AVAILABILITY_TABLE =
  process.env.AVAILABILITY_TABLE || "toriino-availability";
const S3_BUCKET = process.env.S3_BUCKET || "toriino-uploads";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);
const s3 = new S3Client({ region: REGION });

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
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
    // ── Mentor Profiles ──
    if (path === "/mentors" && method === "GET") {
      return await listMentors(event.queryStringParameters);
    }

    const mentorIdMatch = path.match(/^\/mentors\/([^/]+)$/);
    if (mentorIdMatch && method === "GET") {
      return await getMentor(mentorIdMatch[1]);
    }

    // ── Availability ──
    const availMatch = path.match(/^\/mentors\/([^/]+)\/availability$/);
    if (availMatch && method === "GET") {
      return await getAvailability(availMatch[1]);
    }

    if (path === "/mentors/availability" && method === "PUT") {
      return await updateAvailability(userId, body);
    }

    // ── Intro Video ──
    if (path === "/mentors/intro-video" && method === "POST") {
      return await getVideoUploadUrl(userId, body);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Mentors error:", error);
    return response(500, { error: error.message });
  }
};

// ── List Mentors ───────────────────────────────────────────
async function listMentors(queryParams = {}) {
  const { expertise, limit = "20" } = queryParams || {};

  let result;
  if (expertise) {
    result = await dynamodb.send(
      new ScanCommand({
        TableName: MENTORS_TABLE,
        FilterExpression: "contains(expertise, :exp)",
        ExpressionAttributeValues: { ":exp": expertise },
        Limit: parseInt(limit),
      })
    );
  } else {
    result = await dynamodb.send(
      new ScanCommand({
        TableName: MENTORS_TABLE,
        Limit: parseInt(limit),
      })
    );
  }

  return response(200, { mentors: result.Items, count: result.Count });
}

// ── Get Mentor Profile ─────────────────────────────────────
async function getMentor(mentorId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: MENTORS_TABLE, Key: { userId: mentorId } })
  );
  if (!result.Item) return response(404, { error: "Mentor not found" });
  return response(200, result.Item);
}

// ── Get Availability ───────────────────────────────────────
async function getAvailability(mentorId) {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: AVAILABILITY_TABLE,
      KeyConditionExpression: "mentorId = :mentorId",
      ExpressionAttributeValues: { ":mentorId": mentorId },
    })
  );
  return response(200, { slots: result.Items });
}

// ── Update Availability ────────────────────────────────────
async function updateAvailability(mentorId, { slots }) {
  if (!slots || !Array.isArray(slots)) {
    return response(400, { error: "slots array is required" });
  }

  // Delete existing slots and replace
  const existing = await dynamodb.send(
    new QueryCommand({
      TableName: AVAILABILITY_TABLE,
      KeyConditionExpression: "mentorId = :mentorId",
      ExpressionAttributeValues: { ":mentorId": mentorId },
    })
  );

  for (const slot of existing.Items) {
    await dynamodb.send(
      new DeleteCommand({
        TableName: AVAILABILITY_TABLE,
        Key: { mentorId, slotId: slot.slotId },
      })
    );
  }

  // Add new slots
  const savedSlots = [];
  for (const slot of slots) {
    const slotId = randomUUID();
    const item = {
      mentorId,
      slotId,
      dayOfWeek: slot.dayOfWeek,
      startTime: slot.startTime,
      endTime: slot.endTime,
      isRecurring: slot.isRecurring ?? true,
      date: slot.date || null,
    };
    await dynamodb.send(
      new PutCommand({ TableName: AVAILABILITY_TABLE, Item: item })
    );
    savedSlots.push(item);
  }

  return response(200, { slots: savedSlots });
}

// ── Get Video Upload URL ───────────────────────────────────
async function getVideoUploadUrl(mentorId, { fileType }) {
  if (!fileType) {
    return response(400, { error: "fileType is required (e.g. video/mp4)" });
  }

  const extension = fileType.split("/")[1] || "mp4";
  const key = `intro-videos/${mentorId}/intro.${extension}`;

  const command = new PutObjectCommand({
    Bucket: S3_BUCKET,
    Key: key,
    ContentType: fileType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 600 });

  return response(200, {
    uploadUrl,
    key,
    publicUrl: `https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/${key}`,
  });
}
