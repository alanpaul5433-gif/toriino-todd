/**
 * auth Lambda — /auth/*  (Cognito authorizer on every route)
 *
 * Sign-up, sign-in, verification and password reset go straight from the app to
 * Cognito, so this Lambda only handles calls made by a signed-in user:
 *
 *   POST /auth/set-role   { role: Student | Teacher }
 *                         → Cognito custom:role (lowercase) + role on the users table.
 *                         Only once: allowed while the caller has no role yet (409 after).
 *                         Mentor and admin roles are never self-assigned (admins use the
 *                         Admins group; mentors are set by an admin).
 *   POST /auth/logout     global sign-out of the caller's access token (optional)
 *
 * Env: COGNITO_USER_POOL_ID, USERS_TABLE
 */
const {
  CognitoIdentityProviderClient,
  AdminGetUserCommand,
  AdminUpdateUserAttributesCommand,
  GlobalSignOutCommand,
} = require("@aws-sdk/client-cognito-identity-provider");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, UpdateCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const USERS_TABLE = process.env.USERS_TABLE;

const cognito = new CognitoIdentityProviderClient({ region: REGION });
const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

// Roles a user may pick for themselves. Mentor/admin are assigned by an admin only.
const ROLES = { student: "Student", teacher: "Teacher" };

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  if (!claims.sub) return response(401, { error: "Unauthorized" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  try {
    if (event.path === "/auth/set-role" && method === "POST") return await setRole(body, claims);
    if (event.path === "/auth/logout" && method === "POST") return await logout(event);
    if (["/auth/set-role", "/auth/logout"].includes(event.path)) {
      return { ...response(405, { error: "Method not allowed; use POST" }), headers: { ...headers, Allow: "POST, OPTIONS" } };
    }
    return response(404, { error: "Not found" });
  } catch (error) {
    log("ERROR", "Auth handler error", { error: error.message, path: event.path });
    return response(500, { error: "Auth request failed" });
  }
};

async function setRole({ role }, claims) {
  const key = String(role || "").toLowerCase();
  if (key === "admin") return response(403, { error: "The admin role cannot be self-assigned" });
  if (!ROLES[key]) return response(400, { error: "role must be Student or Teacher" });
  if (!USER_POOL_ID || !USERS_TABLE) return response(503, { error: "Auth service not configured" });

  const username = claims["cognito:username"] || claims.sub;

  // The role is chosen once, right after sign-up. Any existing role (including admin) is final
  // here; changing it later is an admin action. Cognito custom:role is the source of truth (the
  // app client cannot write it — see scripts/ensure-cognito-client.mjs).
  const user = await cognito.send(new AdminGetUserCommand({ UserPoolId: USER_POOL_ID, Username: username }));
  const current = (user.UserAttributes || []).find((a) => a.Name === "custom:role")?.Value;
  if (current === "admin") return response(403, { error: "Admin role cannot be changed" });
  if (current) return response(409, { error: "Role already set", role: current });

  await cognito.send(new AdminUpdateUserAttributesCommand({
    UserPoolId: USER_POOL_ID,
    Username: username,
    UserAttributes: [{ Name: "custom:role", Value: key }],
  }));

  try {
    await dynamodb.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId: claims.sub },
      // A brand-new user may not have a profile yet: fill the basics without overwriting.
      UpdateExpression: "SET #role = :role, updatedAt = :u, createdAt = if_not_exists(createdAt, :u), "
        + "email = if_not_exists(email, :e), #n = if_not_exists(#n, :n), #st = if_not_exists(#st, :active)",
      ExpressionAttributeNames: { "#role": "role", "#n": "name", "#st": "status" },
      ExpressionAttributeValues: {
        ":role": ROLES[key], ":u": new Date().toISOString(),
        ":e": claims.email || "", ":n": claims.name || "", ":active": "active",
      },
    }));
  } catch (err) {
    log("ERROR", "custom:role set but users table update failed", { userId: claims.sub, error: err.message });
    return response(500, { error: "Role saved in Cognito but the profile could not be updated; retry" });
  }

  log("INFO", "Role set", { userId: claims.sub, role: key });
  return response(200, { message: "Role set successfully", role: key });
}

async function logout(event) {
  const h = event.headers || {};
  const auth = h.Authorization || h.authorization || "";
  const accessToken = (event.body && JSON.parse(event.body).accessToken) || "";
  if (!accessToken) return response(400, { error: "accessToken is required in the body" });
  if (!auth) return response(401, { error: "Unauthorized" });
  await cognito.send(new GlobalSignOutCommand({ AccessToken: accessToken }));
  return response(200, { message: "Logged out" });
}
