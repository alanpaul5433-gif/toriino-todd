const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
} = require("@aws-sdk/lib-dynamodb");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const REGION = process.env.AWS_REGION || "us-east-2";
const TABLE = process.env.USERS_TABLE || "toriino-users";
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
    if (path === "/users/profile" && method === "GET") {
      return await getProfile(userId);
    }
    if (path === "/users/profile" && method === "PUT") {
      return await updateProfile(userId, body);
    }
    if (path === "/users/role" && method === "PUT") {
      return await updateRole(userId, body);
    }
    if (path === "/users/avatar" && method === "POST") {
      return await getAvatarUploadUrl(userId, body);
    }
    if (path === "/users/account" && method === "DELETE") {
      return await deleteAccount(userId);
    }
    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Users error:", error);
    return response(500, { error: error.message });
  }
};

// ── Get Profile ────────────────────────────────────────────
async function getProfile(userId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: TABLE, Key: { userId } })
  );

  if (!result.Item) {
    return response(404, { error: "User not found" });
  }

  return response(200, result.Item);
}

// ── Update Profile ─────────────────────────────────────────
async function updateProfile(userId, data) {
  const allowedFields = [
    "name",
    "phone",
    "bio",
    "interests",
    "avatarUrl",
    "dateOfBirth",
    "location",
  ];

  const expressionParts = [];
  const expressionValues = {};
  const expressionNames = {};

  for (const field of allowedFields) {
    if (data[field] !== undefined) {
      expressionParts.push(`#${field} = :${field}`);
      expressionValues[`:${field}`] = data[field];
      expressionNames[`#${field}`] = field;
    }
  }

  if (expressionParts.length === 0) {
    return response(400, { error: "No valid fields to update" });
  }

  // Always update the updatedAt timestamp
  expressionParts.push("#updatedAt = :updatedAt");
  expressionValues[":updatedAt"] = new Date().toISOString();
  expressionNames["#updatedAt"] = "updatedAt";

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { userId },
      UpdateExpression: `SET ${expressionParts.join(", ")}`,
      ExpressionAttributeNames: expressionNames,
      ExpressionAttributeValues: expressionValues,
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Update Role ────────────────────────────────────────────
async function updateRole(userId, { role }) {
  if (!role || !["Student", "Teacher", "Mentor"].includes(role)) {
    return response(400, {
      error: "role must be Student, Teacher, or Mentor",
    });
  }

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { userId },
      UpdateExpression: "SET #role = :role, #updatedAt = :updatedAt",
      ExpressionAttributeNames: { "#role": "role", "#updatedAt": "updatedAt" },
      ExpressionAttributeValues: {
        ":role": role,
        ":updatedAt": new Date().toISOString(),
      },
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Get Avatar Upload URL (Presigned S3) ───────────────────
async function getAvatarUploadUrl(userId, { fileType }) {
  if (!fileType) {
    return response(400, { error: "fileType is required (e.g. image/jpeg)" });
  }

  const extension = fileType.split("/")[1] || "jpg";
  const key = `avatars/${userId}/avatar.${extension}`;

  const command = new PutObjectCommand({
    Bucket: S3_BUCKET,
    Key: key,
    ContentType: fileType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

  return response(200, {
    uploadUrl,
    key,
    publicUrl: `https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/${key}`,
  });
}

// ── Delete Account ─────────────────────────────────────────
async function deleteAccount(userId) {
  await dynamodb.send(
    new DeleteCommand({ TableName: TABLE, Key: { userId } })
  );

  return response(200, { message: "Account deleted" });
}
