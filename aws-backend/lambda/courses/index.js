/**
 * courses Lambda — /courses/*  (Cognito authorizer on every route)
 *
 *   GET    /courses?category=&limit=&lastKey=   paginated public catalog (deleted and draft courses hidden;
 *                                               owners see their drafts under /courses/my-created)
 *   POST   /courses                             create (teacher/mentor/admin)
 *   GET    /courses/my-courses                  caller's enrolled courses
 *   GET    /courses/my-created                  caller's own courses
 *   GET    /courses/{id}
 *   PUT    /courses/{id}                        owner/admin only
 *   DELETE /courses/{id}                        soft delete; blocked while students are enrolled;
 *                                               cascades a soft delete to the course's lessons
 *   GET    /courses/{id}/lessons                lesson metadata only (videoKey/materialKey, never URLs)
 *   POST   /courses/{id}/lessons                owner/admin only
 *   PUT    /courses/{id}/lessons/{lessonId}     owner/admin only
 *   DELETE /courses/{id}/lessons/{lessonId}     owner/admin only
 *   GET    /courses/{id}/lessons/{lessonId}/media
 *                                               5-minute pre-signed GET URLs for the lesson's
 *                                               private S3 objects; paid courses require an
 *                                               active enrollment (402 otherwise)
 *   POST   /courses/{id}/complete               marks the caller's own active enrollment completed
 *   POST   /courses/{id}/enroll                 FREE courses only (idempotent per student);
 *                                               paid courses → 402 "payment required": only the
 *                                               Stripe webhook enrolls a student in a paid course
 *
 * (GET /courses/upload-url is routed to the upload-url Lambda.)
 *
 * Env: COURSES_TABLE (PK courseId) — torino-courses, the table holding the live courses
 *      (see docs/ARCHITECTURE.md), LESSONS_TABLE (PK courseId, SK lessonId),
 *      ENROLLMENTS_TABLE (PK enrollmentId; userId, courseId attributes),
 *      MEDIA_BUCKET (private bucket holding lessons/ and course-materials/ objects)
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  ScanCommand,
  BatchGetCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const REGION = process.env.AWS_REGION || "us-east-1";
const COURSES_TABLE = process.env.COURSES_TABLE;
const LESSONS_TABLE = process.env.LESSONS_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;
const MEDIA_BUCKET = process.env.MEDIA_BUCKET;
const MEDIA_URL_TTL = 300; // seconds

const s3 = new S3Client({ region: REGION });

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

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

const DELETED = "deleted";
const DRAFT = "draft"; // unpublished: not in the public catalog
const COURSE_FIELDS = [
  "title", "description", "category", "duration", "price", "thumbnail", "imageUrl",
  "level", "language", "tags", "materials", "totalDuration", "totalLessons", "status",
];
// `url` is only for link-type lessons (an external https page, not our private media).
const LESSON_FIELDS = ["title", "description", "videoKey", "materialKey", "url", "duration", "order", "content", "type"];
// Lesson media lives in the private bucket; a lesson may only point at keys under these prefixes.
const MEDIA_PREFIX = { videoKey: "lessons/", materialKey: "course-materials/" };
const isPaid = (course) => (Number(course.price) || 0) > 0;
const INACTIVE_ENROLLMENT = new Set(["refunded", "cancelled"]);

function isAdmin(claims) {
  const g = claims["cognito:groups"];
  if (!g) return false;
  const list = Array.isArray(g) ? g : String(g).replace(/[[\]]/g, "").split(/[\s,]+/);
  return list.includes("Admins");
}

function ownsCourse(course, userId, claims) {
  return course.teacherId === userId || course.mentorId === userId || isAdmin(claims);
}

async function scanAll(params, max = Infinity) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new ScanCommand({ ...params, ExclusiveStartKey }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey && items.length < max);
  return items;
}

async function getCourseItem(courseId) {
  const r = await dynamodb.send(new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } }));
  return r.Item && r.Item.status !== DELETED ? r.Item : null;
}

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!COURSES_TABLE || !LESSONS_TABLE || !ENROLLMENTS_TABLE) {
    return response(503, { error: "Courses service not configured (table env vars)" });
  }

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const seg = event.path.split("/").filter(Boolean).map((s) => {
    try { return decodeURIComponent(s); } catch { return s; }
  });
  const [, courseId, sub, lessonId] = seg;

  try {
    if (seg.length === 1) {
      if (method === "GET") return await listCourses(event.queryStringParameters || {});
      if (method === "POST") return await createCourse(userId, claims, body);
    }
    if (seg.length === 2 && courseId === "my-courses" && method === "GET") return await myEnrolledCourses(userId);
    if (seg.length === 2 && courseId === "my-created" && method === "GET") return await myCreatedCourses(userId);
    if (seg.length === 2) {
      if (method === "GET") return await getCourse(courseId);
      if (method === "PUT") return await updateCourse(userId, claims, courseId, body);
      if (method === "DELETE") return await deleteCourse(userId, claims, courseId);
    }
    if (seg.length === 3 && sub === "lessons") {
      if (method === "GET") return await getLessons(courseId);
      if (method === "POST") return await addLesson(userId, claims, courseId, body);
    }
    if (seg.length === 5 && sub === "lessons" && seg[4] === "media" && method === "GET") {
      return await lessonMedia(userId, claims, courseId, lessonId);
    }
    if (seg.length === 4 && sub === "lessons") {
      if (method === "PUT") return await updateLesson(userId, claims, courseId, lessonId, body);
      if (method === "DELETE") return await deleteLesson(userId, claims, courseId, lessonId);
    }
    if (seg.length === 3 && sub === "enroll" && method === "POST") return await enroll(userId, courseId);
    if (seg.length === 3 && sub === "complete" && method === "POST") return await completeCourse(userId, courseId);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Courses handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Courses request failed" });
  }
};

// ── Courses ────────────────────────────────────────────────
async function listCourses({ category, limit, lastKey }) {
  const pageSize = Math.min(Math.max(parseInt(limit || "50", 10) || 50, 1), 100);
  let ExclusiveStartKey;
  if (lastKey) {
    try { ExclusiveStartKey = JSON.parse(decodeURIComponent(lastKey)); } catch {
      return response(400, { error: "Invalid lastKey" });
    }
  }

  const names = { "#s": "status" };
  const values = { ":deleted": DELETED, ":draft": DRAFT };
  let filter = "(attribute_not_exists(#s) OR (#s <> :deleted AND #s <> :draft))";
  if (category) {
    filter += " AND category = :cat";
    values[":cat"] = category;
  }

  // Keep reading until the page is full or the table ends (filters can thin a page).
  const courses = [];
  do {
    const page = await dynamodb.send(new ScanCommand({
      TableName: COURSES_TABLE,
      FilterExpression: filter,
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      Limit: pageSize,
      ExclusiveStartKey,
    }));
    courses.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey && courses.length < pageSize);

  return response(200, {
    courses,
    count: courses.length,
    lastKey: ExclusiveStartKey ? encodeURIComponent(JSON.stringify(ExclusiveStartKey)) : null,
  });
}

async function getCourse(courseId) {
  const course = await getCourseItem(courseId);
  return course ? response(200, course) : response(404, { error: "Course not found" });
}

async function createCourse(userId, claims, data) {
  const role = String(claims["custom:role"] || "").toLowerCase();
  if (!["teacher", "mentor"].includes(role) && !isAdmin(claims)) {
    return response(403, { error: "Only teachers and mentors can create courses" });
  }
  if (!data.title || !String(data.title).trim()) return response(400, { error: "title is required" });

  const now = new Date().toISOString();
  const course = { courseId: `crs_${randomUUID()}`, teacherId: userId };
  for (const f of COURSE_FIELDS) if (data[f] !== undefined) course[f] = data[f];
  if (course.status === DELETED) delete course.status;
  Object.assign(course, {
    title: String(data.title).trim(),
    description: data.description || "",
    category: data.category || "General",
    price: Number(data.price) || 0,
    status: course.status || "published",
    enrollments: 0,
    rating: 0,
    createdAt: now,
    updatedAt: now,
  });

  await dynamodb.send(new PutCommand({
    TableName: COURSES_TABLE,
    Item: course,
    ConditionExpression: "attribute_not_exists(courseId)",
  }));
  log("INFO", "Course created", { courseId: course.courseId, teacherId: userId });
  return response(201, { message: "Course created", ...course });
}

async function updateCourse(userId, claims, courseId, data) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  if (!ownsCourse(course, userId, claims)) return response(403, { error: "Not authorized to edit this course" });

  const sets = [];
  const values = {};
  const names = {};
  for (const f of COURSE_FIELDS) {
    if (data[f] === undefined) continue;
    if (f === "status" && data[f] === DELETED) return response(400, { error: "Use DELETE to delete a course" });
    sets.push(`#${f} = :${f}`);
    values[`:${f}`] = f === "price" ? Number(data[f]) || 0 : data[f];
    names[`#${f}`] = f;
  }
  if (sets.length === 0) return response(400, { error: "No valid fields to update" });
  sets.push("#updatedAt = :updatedAt");
  values[":updatedAt"] = new Date().toISOString();
  names["#updatedAt"] = "updatedAt";

  const result = await dynamodb.send(new UpdateCommand({
    TableName: COURSES_TABLE,
    Key: { courseId },
    UpdateExpression: `SET ${sets.join(", ")}`,
    ConditionExpression: "attribute_exists(courseId)",
    ExpressionAttributeNames: names,
    ExpressionAttributeValues: values,
    ReturnValues: "ALL_NEW",
  }));
  return response(200, result.Attributes);
}

async function deleteCourse(userId, claims, courseId) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  if (!ownsCourse(course, userId, claims)) return response(403, { error: "Not authorized to delete this course" });

  // 1. Guard: never delete a course students are enrolled in.
  const enrolled = await scanAll({
    TableName: ENROLLMENTS_TABLE,
    FilterExpression: "courseId = :cid",
    ExpressionAttributeValues: { ":cid": courseId },
    ProjectionExpression: "enrollmentId",
  }, 1);
  if (enrolled.length > 0) {
    return response(409, { error: "Cannot delete a course with enrolled students" });
  }

  // 2. Cascade: soft-delete every lesson of the course.
  const now = new Date().toISOString();
  const lessons = await queryLessons(courseId, true);
  for (const lesson of lessons) {
    await dynamodb.send(new UpdateCommand({
      TableName: LESSONS_TABLE,
      Key: { courseId, lessonId: lesson.lessonId },
      UpdateExpression: "SET #s = :d, deletedAt = :now",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: { ":d": DELETED, ":now": now },
    }));
  }

  // 3. Soft-delete the course itself.
  await dynamodb.send(new UpdateCommand({
    TableName: COURSES_TABLE,
    Key: { courseId },
    UpdateExpression: "SET #s = :d, deletedAt = :now, deletedBy = :by, updatedAt = :now",
    ConditionExpression: "attribute_exists(courseId)",
    ExpressionAttributeNames: { "#s": "status" },
    ExpressionAttributeValues: { ":d": DELETED, ":now": now, ":by": userId },
  }));

  log("INFO", "Course soft-deleted", { courseId, userId, lessons: lessons.length });
  return response(200, { message: "Course deleted", courseId, lessonsDeleted: lessons.length });
}

// ── Lessons ────────────────────────────────────────────────
// videoKey/materialKey must be objects the caller uploaded through GET /upload-url
// (keys look like lessons/<sub>/<uuid>.<ext>); admins may reference any key under the prefix.
function invalidMediaKey(data, userId, claims) {
  if (data.url !== undefined && data.url !== null && data.url !== "") {
    if (typeof data.url !== "string" || !/^https:\/\/[^\s]+$/.test(data.url)) return "url must be an https link";
  }
  for (const [field, prefix] of Object.entries(MEDIA_PREFIX)) {
    const key = data[field];
    if (key === undefined || key === null || key === "") continue;
    if (typeof key !== "string" || key.includes("..") || !key.startsWith(prefix)) {
      return `${field} must be an S3 key under ${prefix} returned by GET /upload-url`;
    }
    if (!isAdmin(claims) && !key.startsWith(`${prefix}${userId}/`)) {
      return `${field} must be a file you uploaded`;
    }
  }
  return null;
}

async function queryLessons(courseId, includeDeleted = false) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new QueryCommand({
      TableName: LESSONS_TABLE,
      KeyConditionExpression: "courseId = :c",
      ExpressionAttributeValues: { ":c": courseId },
      ExclusiveStartKey,
    }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
  return includeDeleted ? items : items.filter((l) => l.status !== DELETED);
}

async function getLessons(courseId) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  const lessons = await queryLessons(courseId);
  lessons.sort((a, b) => (Number(a.order) || 0) - (Number(b.order) || 0));
  return response(200, { lessons, count: lessons.length });
}

async function addLesson(userId, claims, courseId, data) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  if (!ownsCourse(course, userId, claims)) return response(403, { error: "Not authorized to add lessons to this course" });
  if (!data.title || !String(data.title).trim()) return response(400, { error: "title is required" });
  const badKey = invalidMediaKey(data, userId, claims);
  if (badKey) return response(400, { error: badKey });

  const lesson = { courseId, lessonId: `les_${randomUUID()}` };
  for (const f of LESSON_FIELDS) if (data[f] !== undefined) lesson[f] = data[f];
  lesson.title = String(data.title).trim();
  lesson.order = Number(data.order) || 0;
  lesson.createdAt = new Date().toISOString();

  await dynamodb.send(new PutCommand({
    TableName: LESSONS_TABLE,
    Item: lesson,
    ConditionExpression: "attribute_not_exists(lessonId)",
  }));
  return response(201, { message: "Lesson added", ...lesson });
}

async function updateLesson(userId, claims, courseId, lessonId, data) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  if (!ownsCourse(course, userId, claims)) return response(403, { error: "Not authorized to edit this lesson" });
  const badKey = invalidMediaKey(data, userId, claims);
  if (badKey) return response(400, { error: badKey });

  const sets = [];
  const values = {};
  const names = {};
  for (const f of LESSON_FIELDS) {
    if (data[f] === undefined) continue;
    sets.push(`#${f} = :${f}`);
    values[`:${f}`] = f === "order" ? Number(data[f]) || 0 : data[f];
    names[`#${f}`] = f;
  }
  if (sets.length === 0) return response(400, { error: "No valid fields to update" });
  sets.push("updatedAt = :u");
  values[":u"] = new Date().toISOString();

  try {
    const result = await dynamodb.send(new UpdateCommand({
      TableName: LESSONS_TABLE,
      Key: { courseId, lessonId },
      UpdateExpression: `SET ${sets.join(", ")}`,
      ConditionExpression: "attribute_exists(lessonId)",
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      ReturnValues: "ALL_NEW",
    }));
    return response(200, result.Attributes);
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return response(404, { error: "Lesson not found" });
    throw err;
  }
}

async function deleteLesson(userId, claims, courseId, lessonId) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });
  if (!ownsCourse(course, userId, claims)) return response(403, { error: "Not authorized to delete this lesson" });
  try {
    await dynamodb.send(new DeleteCommand({
      TableName: LESSONS_TABLE,
      Key: { courseId, lessonId },
      ConditionExpression: "attribute_exists(lessonId)",
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return response(404, { error: "Lesson not found" });
    throw err;
  }
  return response(200, { message: "Lesson deleted" });
}

async function hasActiveEnrollment(userId, courseId) {
  const rows = await findEnrollments(
    "courseId = :c AND (userId = :u OR studentId = :u)",
    { ":c": courseId, ":u": userId },
  );
  return rows.some((e) => !INACTIVE_ENROLLMENT.has(e.status));
}

// Paid lesson videos are never public: they are served only through short-lived
// pre-signed GET URLs, issued after checking the caller may watch the course.
async function lessonMedia(userId, claims, courseId, lessonId) {
  if (!MEDIA_BUCKET) return response(503, { error: "Lesson media not configured (MEDIA_BUCKET)" });
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });

  const { Item: lesson } = await dynamodb.send(new GetCommand({ TableName: LESSONS_TABLE, Key: { courseId, lessonId } }));
  if (!lesson || lesson.status === DELETED) return response(404, { error: "Lesson not found" });
  if (!lesson.videoKey && !lesson.materialKey) return response(404, { error: "This lesson has no media" });

  const allowed = ownsCourse(course, userId, claims) || !isPaid(course) || await hasActiveEnrollment(userId, courseId);
  if (!allowed) return response(402, { error: "payment required", price: Number(course.price) || 0 });

  const sign = (Key) => getSignedUrl(s3, new GetObjectCommand({ Bucket: MEDIA_BUCKET, Key }), { expiresIn: MEDIA_URL_TTL });
  const body = { expiresIn: MEDIA_URL_TTL };
  if (lesson.videoKey) body.videoUrl = await sign(lesson.videoKey);
  if (lesson.materialKey) body.materialUrl = await sign(lesson.materialKey);
  log("INFO", "Lesson media URL issued", { userId, courseId, lessonId });
  return response(200, body);
}

// ── Enrollment ─────────────────────────────────────────────
async function findEnrollments(filter, values) {
  return scanAll({ TableName: ENROLLMENTS_TABLE, FilterExpression: filter, ExpressionAttributeValues: values });
}

async function enroll(userId, courseId) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });

  const existing = await findEnrollments(
    "courseId = :c AND (userId = :u OR studentId = :u)",
    { ":c": courseId, ":u": userId },
  );
  if (existing.length > 0) return response(200, { message: "Already enrolled", ...existing[0] });

  // Paid courses are enrolled only by the Stripe webhook after payment succeeds.
  if (isPaid(course)) {
    return response(402, { error: "payment required", price: Number(course.price) || 0, courseId });
  }

  const enrollment = {
    enrollmentId: `enr_${courseId}_${userId}`,
    userId,
    studentId: userId,
    courseId,
    enrolledAt: new Date().toISOString(),
    progress: 0,
    completedLessons: 0,
    status: "active",
  };
  try {
    await dynamodb.send(new PutCommand({
      TableName: ENROLLMENTS_TABLE,
      Item: enrollment,
      ConditionExpression: "attribute_not_exists(enrollmentId)",
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") return response(200, { message: "Already enrolled", ...enrollment });
    throw err;
  }

  try {
    await dynamodb.send(new UpdateCommand({
      TableName: COURSES_TABLE,
      Key: { courseId },
      UpdateExpression: "ADD enrollments :one",
      ExpressionAttributeValues: { ":one": 1 },
    }));
  } catch (err) {
    // The enrollment is saved; the counter is cosmetic.
    log("WARN", "Enrollment counter update failed", { courseId, error: err.message });
  }

  log("INFO", "Student enrolled", { userId, courseId });
  return response(201, { message: "Enrolled", ...enrollment });
}

// Idempotent: a completed enrollment stays completed. There is no certificate system.
async function completeCourse(userId, courseId) {
  const course = await getCourseItem(courseId);
  if (!course) return response(404, { error: "Course not found" });

  const rows = await findEnrollments(
    "courseId = :c AND (userId = :u OR studentId = :u)",
    { ":c": courseId, ":u": userId },
  );
  const enrollment = rows.find((e) => !INACTIVE_ENROLLMENT.has(e.status));
  if (!enrollment) return response(404, { error: "You are not enrolled in this course" });

  const completedAt = enrollment.completedAt || new Date().toISOString();
  if (enrollment.status !== "completed") {
    await dynamodb.send(new UpdateCommand({
      TableName: ENROLLMENTS_TABLE,
      Key: { enrollmentId: enrollment.enrollmentId },
      UpdateExpression: "SET #s = :c, completedAt = :at, progress = :p, updatedAt = :now",
      ConditionExpression: "attribute_exists(enrollmentId)",
      ExpressionAttributeNames: { "#s": "status" },
      ExpressionAttributeValues: { ":c": "completed", ":at": completedAt, ":p": 100, ":now": new Date().toISOString() },
    }));
    log("INFO", "Course completed", { userId, courseId });
  }
  return response(200, { message: "Course marked as completed", courseId, status: "completed", completedAt });
}

async function myEnrolledCourses(userId) {
  const enrollments = await findEnrollments("userId = :u OR studentId = :u", { ":u": userId });
  const ids = [...new Set(enrollments.map((e) => e.courseId).filter(Boolean))];

  const byId = {};
  for (let i = 0; i < ids.length; i += 100) {
    let request = { [COURSES_TABLE]: { Keys: ids.slice(i, i + 100).map((courseId) => ({ courseId })) } };
    for (let attempt = 0; request && Object.keys(request).length && attempt < 5; attempt++) {
      const r = await dynamodb.send(new BatchGetCommand({ RequestItems: request }));
      for (const c of r.Responses?.[COURSES_TABLE] || []) byId[c.courseId] = c;
      request = r.UnprocessedKeys;
    }
  }

  // One entry per course even if legacy data holds duplicate enrollments.
  const seen = new Set();
  const courses = enrollments
    .filter((e) => byId[e.courseId] && byId[e.courseId].status !== DELETED)
    .filter((e) => !seen.has(e.courseId) && seen.add(e.courseId))
    .map((e) => ({ ...byId[e.courseId], enrollment: e }));
  return response(200, { courses, count: courses.length });
}

async function myCreatedCourses(userId) {
  const courses = await scanAll({
    TableName: COURSES_TABLE,
    FilterExpression: "(teacherId = :u OR mentorId = :u) AND (attribute_not_exists(#s) OR #s <> :d)",
    ExpressionAttributeNames: { "#s": "status" },
    ExpressionAttributeValues: { ":u": userId, ":d": DELETED },
  });
  return response(200, { courses, count: courses.length });
}
