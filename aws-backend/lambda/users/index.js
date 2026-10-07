/**
 * users Lambda — /users/*  (Cognito authorizer on every route)
 *
 *   GET    /users/profile   caller's profile (stub created from JWT claims on first call)
 *   PUT    /users/profile   update allowed profile fields
 *   PUT    /users/role      set role (Student | Teacher | Mentor) on the profile record
 *   POST   /users/avatar    legacy: pre-signed avatar upload (app now uses GET /upload-url)
 *   DELETE /users/account   delete the Cognito user, then the profile record
 *
 * Env: USERS_TABLE, COGNITO_USER_POOL_ID
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  CognitoIdentityProviderClient,
  AdminDeleteUserCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const REGION = process.env.AWS_REGION || "us-east-1";
const TABLE = process.env.USERS_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const cognito = new CognitoIdentityProviderClient({ region: REGION });

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const ROLES = { student: "Student", teacher: "Teacher", mentor: "Mentor" };

const PROFILE_FIELDS = [
  "name", "phone", "bio", "interests", "avatarUrl", "dateOfBirth", "location",
  "experience", "language", "hourlyRate", "expertise", "specialties", "goals",
  "educationLevel", "title", "skills", "industry",
];

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!TABLE) return response(503, { error: "Users service not configured (USERS_TABLE)" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const path = event.path;
  try {
    if (path === "/users/profile" && method === "GET") return await getProfile(userId, claims);
    if (path === "/users/profile" && method === "PUT") return await updateProfile(userId, body);
    if (path === "/users/role" && method === "PUT") return await updateRole(userId, body);
    if (path === "/users/avatar" && method === "POST") {
      return response(410, { error: "Use GET /upload-url?folder=profiles to upload an avatar" });
    }
    if (path === "/users/account" && method === "DELETE") return await deleteAccount(userId, claims);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Users handler error", { error: error.message, path, method });
    return response(500, { error: "Users request failed" });
  }
};

async function getProfile(userId, claims) {
  const result = await dynamodb.send(new GetCommand({ TableName: TABLE, Key: { userId } }));
  if (result.Item) return response(200, result.Item);

  // First call after sign-up: create the profile from the verified token claims.
  const role = ROLES[String(claims["custom:role"] || "").toLowerCase()] || "Student";
  const stub = {
    userId,
    email: claims.email || "",
    name: claims.name || "",
    role,
    status: "active",
    createdAt: new Date().toISOString(),
  };
  try {
    await dynamodb.send(new PutCommand({
      TableName: TABLE,
      Item: stub,
      ConditionExpression: "attribute_not_exists(userId)",
    }));
  } catch (err) {
    if (err.name !== "ConditionalCheckFailedException") throw err;
    const again = await dynamodb.send(new GetCommand({ TableName: TABLE, Key: { userId } }));
    return response(200, again.Item);
  }
  return response(200, stub);
}

async function updateProfile(userId, data) {
  const sets = [];
  const values = {};
  const names = {};
  for (const field of PROFILE_FIELDS) {
    if (data[field] !== undefined) {
      sets.push(`#${field} = :${field}`);
      values[`:${field}`] = data[field];
      names[`#${field}`] = field;
    }
  }
  if (sets.length === 0) return response(400, { error: "No valid fields to update" });

  sets.push("#updatedAt = :updatedAt");
  values[":updatedAt"] = new Date().toISOString();
  names["#updatedAt"] = "updatedAt";

  const result = await dynamodb.send(new UpdateCommand({
    TableName: TABLE,
    Key: { userId },
    UpdateExpression: `SET ${sets.join(", ")}`,
    ExpressionAttributeNames: names,
    ExpressionAttributeValues: values,
    ReturnValues: "ALL_NEW",
  }));
  return response(200, result.Attributes);
}

async function updateRole(userId, { role }) {
  const normalized = ROLES[String(role || "").toLowerCase()];
  if (!normalized) return response(400, { error: "role must be Student, Teacher, or Mentor" });

  const result = await dynamodb.send(new UpdateCommand({
    TableName: TABLE,
    Key: { userId },
    UpdateExpression: "SET #role = :role, #updatedAt = :updatedAt",
    ExpressionAttributeNames: { "#role": "role", "#updatedAt": "updatedAt" },
    ExpressionAttributeValues: { ":role": normalized, ":updatedAt": new Date().toISOString() },
    ReturnValues: "ALL_NEW",
  }));
  return response(200, result.Attributes);
}

async function deleteAccount(userId, claims) {
  if (!USER_POOL_ID) return response(503, { error: "Account deletion not configured (COGNITO_USER_POOL_ID)" });
  const username = claims["cognito:username"] || userId;

  // Cognito first: if that fails nothing is deleted and the user can retry.
  try {
    await cognito.send(new AdminDeleteUserCommand({ UserPoolId: USER_POOL_ID, Username: username }));
  } catch (err) {
    if (err.name !== "UserNotFoundException") {
      log("ERROR", "Cognito delete failed", { userId, error: err.message });
      return response(502, { error: "Could not delete the sign-in account; nothing was deleted" });
    }
  }
  try {
    await dynamodb.send(new DeleteCommand({ TableName: TABLE, Key: { userId } }));
  } catch (err) {
    log("ERROR", "Profile delete failed after Cognito delete", { userId, error: err.message });
    return response(500, { error: "Sign-in account deleted but the profile record could not be removed" });
  }
  log("INFO", "Account deleted", { userId });
  return response(200, { message: "Account deleted" });
}
