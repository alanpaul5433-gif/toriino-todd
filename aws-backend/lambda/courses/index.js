/**
 * courses Lambda — /courses/*  (Cognito authorizer on every route)
 *
 *   GET    /courses?category=&limit=&lastKey=   paginated list (soft-deleted courses hidden)
 *   POST   /courses                             create (teacher/mentor/admin)
 *   GET    /courses/my-courses                  caller's enrolled courses
 *   GET    /courses/my-created                  caller's own courses
 *   GET    /courses/{id}
 *   PUT    /courses/{id}                        owner/admin only
 *   DELETE /courses/{id}                        soft delete; blocked while students are enrolled;
 *                                               cascades a soft delete to the course's lessons
 *   GET    /courses/{id}/lessons
 *   POST   /courses/{id}/lessons                owner/admin only
 *   PUT    /courses/{id}/lessons/{lessonId}     owner/admin only
 *   DELETE /courses/{id}/lessons/{lessonId}     owner/admin only
 *   POST   /courses/{id}/enroll                 idempotent per (student, course)
 *
 * (GET /courses/upload-url is routed to the upload-url Lambda.)
 *
 * Env: COURSES_TABLE (PK courseId), LESSONS_TABLE (PK courseId, SK lessonId),
 *      ENROLLMENTS_TABLE (PK enrollmentId; userId, courseId attributes)
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

const REGION = process.env.AWS_REGION || "us-east-1";
const COURSES_TABLE = process.env.COURSES_TABLE;
const LESSONS_TABLE = process.env.LESSONS_TABLE;
const ENROLLMENTS_TABLE = process.env.ENROLLMENTS_TABLE;

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
const COURSE_FIELDS = [
  "title", "description", "category", "duration", "price", "thumbnail", "imageUrl",
  "level", "language", "tags", "materials", "totalDuration", "totalLessons", "status",
];
const LESSON_FIELDS = ["title", "description", "videoUrl", "duration", "order", "materials", "content", "type"];

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
    if (seg.length === 4 && sub === "lessons") {
      if (method === "PUT") return await updateLesson(userId, claims, courseId, lessonId, body);
      if (method === "DELETE") return await deleteLesson(userId, claims, courseId, lessonId);
    }
    if (seg.length === 3 && sub === "enroll" && method === "POST") return await enroll(userId, courseId);
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
  const values = { ":deleted": DELETED };
  let filter = "(attribute_not_exists(#s) OR #s <> :deleted)";
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
