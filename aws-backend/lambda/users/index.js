/**
 * users Lambda — /users/*  (Cognito authorizer on every route)
 *
 *   GET    /users/profile   caller's profile (stub created from JWT claims on first call)
 *   PUT    /users/profile   update allowed profile fields
 *   PUT    /users/role      set role (Student | Teacher | Mentor) on the profile record
 *   POST   /users/avatar    legacy: pre-signed avatar upload (app now uses GET /upload-url)
 *   DELETE /users/account   delete the Cognito user, then the profile record
 *
 *   GET    /users/{id}      another user's profile, safe fields only:
 *            - teacher/mentor: public profile (name, avatar, bio, title, expertise, rating,
 *              intro video, published courses) for any signed-in user
 *            - student: only for a teacher/mentor who shares a session with them or teaches
 *              a course they are enrolled in (403 otherwise); returns name, avatar, bio and
 *              the shared courses/sessions. Never email, phone, wallet, earnings, tokens…
 *
 * Profile field introVideoUrl must be a CloudFront URL from an upload to folder
 * intro-videos (GET /upload-url); for mentors it is mirrored onto the mentor record.
 *
 * Env: USERS_TABLE, MENTORS_TABLE, SESSIONS_TABLE, COURSES_TABLE, ENROLLMENTS_TABLE,
 *      COGNITO_USER_POOL_ID, CDN_BASE
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const {
  CognitoIdentityProviderClient,
  AdminDeleteUserCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const REGION = process.env.AWS_REGION || "us-east-1";
const TABLE = process.env.USERS_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const MENTORS_TABLE = process.env.MENTORS_TABLE;
const CDN_BASE = process.env.CDN_BASE || "";
const SESSIONS_TABLE = process.env.SESSIONS_TABLE;
const COURSES_TABLE = process.env.COURSES_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

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
  "educationLevel", "title", "skills", "industry", "introVideoUrl",
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
    if (path === "/users/profile" && method === "PUT" && body.introVideoUrl !== undefined) {
      const url = String(body.introVideoUrl || "");
      if (url && !(CDN_BASE && url.startsWith(`${CDN_BASE}/intro-videos/${userId}/`))) {
        return response(400, { error: "introVideoUrl must be the URL returned by an intro-videos upload" });
      }
    }
    if (path === "/users/profile" && method === "GET") return await getProfile(userId, claims);
    if (path === "/users/profile" && method === "PUT") return await updateProfile(userId, body);
    if (path === "/users/role" && method === "PUT") return await updateRole(userId, body);
    if (path === "/users/avatar" && method === "POST") {
      return response(410, { error: "Use GET /upload-url?folder=profiles to upload an avatar" });
    }
    if (path === "/users/account" && method === "DELETE") return await deleteAccount(userId, claims);
    const other = path.match(/^\/users\/([^/]+)$/);
    if (other && method === "GET") {
      let targetId = other[1];
      try { targetId = decodeURIComponent(targetId); } catch { /* keep raw */ }
      return await viewProfile(userId, claims, targetId);
    }
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

  // Students see a mentor's intro video on GET /mentors/{id}, so mirror it there.
  if (data.introVideoUrl !== undefined && MENTORS_TABLE
      && String(result.Attributes?.role || "").toLowerCase() === "mentor") {
    try {
      await dynamodb.send(new UpdateCommand({
        TableName: MENTORS_TABLE,
        Key: { mentorId: userId },
        UpdateExpression: "SET introVideoUrl = :v, updatedAt = :u",
        ConditionExpression: "attribute_exists(mentorId)",
        ExpressionAttributeValues: { ":v": data.introVideoUrl, ":u": values[":updatedAt"] },
      }));
    } catch (err) {
      if (err.name !== "ConditionalCheckFailedException") {
        log("ERROR", "Intro video saved on profile but mentor record update failed", { userId, error: err.message });
        return response(500, { error: "Intro video saved on your profile but not on your mentor listing; please retry" });
      }
    }
  }
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

// ── View another user's profile (GET /users/{id}) ──────────
// Whitelists only: a stored field is returned only if it is listed here.
const PUBLIC_TEACHER_FIELDS = ["name", "avatarUrl", "bio", "title", "expertise", "specialties", "language", "introVideoUrl"];
const STUDENT_FIELDS = ["name", "avatarUrl", "bio"];
const INACTIVE_ENROLLMENT = new Set(["refunded", "cancelled"]);
const HIDDEN_COURSE = new Set(["deleted", "draft"]);
const pick = (obj, fields) => Object.fromEntries(fields.filter((f) => obj?.[f] !== undefined).map((f) => [f, obj[f]]));

async function scanAll(params) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new ScanCommand({ ...params, ExclusiveStartKey }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
  return items;
}

async function viewProfile(callerId, claims, targetId) {
  if (!MENTORS_TABLE || !SESSIONS_TABLE || !COURSES_TABLE || !ENROLLMENTS_TABLE) {
    return response(503, { error: "Profile view not configured" });
  }
  const [userRes, mentorRes] = await Promise.all([
    dynamodb.send(new GetCommand({ TableName: TABLE, Key: { userId: targetId } })),
    dynamodb.send(new GetCommand({ TableName: MENTORS_TABLE, Key: { mentorId: targetId } })),
  ]);
  const user = userRes.Item;
  const mentor = mentorRes.Item;
  const role = String(user?.role || (mentor ? "mentor" : "")).toLowerCase();
  if (!user && !mentor) return response(404, { error: "User not found" });

  if (role === "teacher" || role === "mentor") {
    if (mentor && mentor.approved === false && callerId !== targetId) return response(404, { error: "User not found" });
    return response(200, await teacherPublicProfile(targetId, role, user, mentor));
  }
  if (role === "student") return await studentProfileForEducator(callerId, claims, targetId, user);
  return response(404, { error: "User not found" });
}

async function teacherPublicProfile(targetId, role, user, mentor) {
  const courses = (await scanAll({
    TableName: COURSES_TABLE,
    FilterExpression: "teacherId = :t OR mentorId = :t",
    ExpressionAttributeValues: { ":t": targetId },
  }))
    .filter((c) => !HIDDEN_COURSE.has(c.status))
    .map((c) => pick(c, ["courseId", "title", "price", "thumbnail", "rating", "category", "level", "duration"]));
  return {
    userId: targetId,
    role: role === "mentor" ? "Mentor" : "Teacher",
    // Prefer the profile; fall back to the mentor listing (some mentors have no profile row).
    ...pick(mentor, [...PUBLIC_TEACHER_FIELDS, "rating", "reviewCount", "hourlyRate", "totalSessions"]),
    ...pick(user, PUBLIC_TEACHER_FIELDS),
    courses,
  };
}

// Allowed only for a teacher/mentor who shares a session with the student, or whose course
// the student is (actively) enrolled in. Anything else is 403 — including other students.
async function studentProfileForEducator(callerId, claims, studentId, student) {
  const callerRole = String(claims["custom:role"] || "").toLowerCase();
  if (callerId === studentId) return response(200, { userId: studentId, role: "Student", ...pick(student, STUDENT_FIELDS), sharedCourses: [], sharedSessions: [] });
  if (!["teacher", "mentor"].includes(callerRole)) {
    return response(403, { error: "Only teachers and mentors can view a student's profile" });
  }

  const [sessions, myCourses, enrollments] = await Promise.all([
    scanAll({
      TableName: SESSIONS_TABLE,
      FilterExpression: "studentId = :s AND (mentorId = :c OR teacherId = :c)",
      ExpressionAttributeValues: { ":s": studentId, ":c": callerId },
    }),
    scanAll({
      TableName: COURSES_TABLE,
      FilterExpression: "teacherId = :c OR mentorId = :c",
      ExpressionAttributeValues: { ":c": callerId },
    }),
    scanAll({
      TableName: ENROLLMENTS_TABLE,
      FilterExpression: "userId = :s OR studentId = :s",
      ExpressionAttributeValues: { ":s": studentId },
    }),
  ]);

  const mine = new Map(myCourses.filter((c) => c.status !== "deleted").map((c) => [c.courseId, c]));
  const seen = new Set();
  const sharedCourses = enrollments
    .filter((e) => mine.has(e.courseId) && !INACTIVE_ENROLLMENT.has(e.status))
    .filter((e) => !seen.has(e.courseId) && seen.add(e.courseId))
    .map((e) => ({
      ...pick(mine.get(e.courseId), ["courseId", "title", "thumbnail"]),
      enrollmentStatus: e.status || "active",
      progress: Number(e.progress) || 0,
      enrolledAt: e.enrolledAt,
    }));
  const sharedSessions = sessions
    .map((x) => pick(x, ["sessionId", "title", "topic", "dateTime", "duration", "status", "sessionType"]))
    .sort((a, b) => String(b.dateTime || "").localeCompare(String(a.dateTime || "")));

  if (sharedCourses.length === 0 && sharedSessions.length === 0) {
    log("WARN", "Student profile view refused", { callerId, studentId });
    return response(403, { error: "You can only view students you teach or have a session with" });
  }
  return response(200, { userId: studentId, role: "Student", ...pick(student, STUDENT_FIELDS), sharedCourses, sharedSessions });
}
