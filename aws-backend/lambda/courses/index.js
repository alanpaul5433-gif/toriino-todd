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
const { randomUUID } = require("crypto");

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const REGION = process.env.AWS_REGION || "us-east-2";
const COURSES_TABLE = process.env.COURSES_TABLE || "toriino-courses";
const LESSONS_TABLE = process.env.LESSONS_TABLE || "toriino-course-lessons";
const ENROLLMENTS_TABLE =
  process.env.ENROLLMENTS_TABLE || "toriino-enrollments";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

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
  const pathParams = event.pathParameters || {};

  if (method === "OPTIONS") return response(200, {});
  if (!userId) return response(401, { error: "Unauthorized" });

  try {
    // ── Course CRUD ──
    if (path === "/courses" && method === "GET") {
      return await listCourses(event.queryStringParameters);
    }
    if (path === "/courses" && method === "POST") {
      return await createCourse(userId, body);
    }
    if (path === "/courses/my-courses" && method === "GET") {
      return await getMyEnrolledCourses(userId);
    }
    if (path === "/courses/my-created" && method === "GET") {
      return await getMyCreatedCourses(userId);
    }

    // Routes with courseId
    const courseIdMatch = path.match(/^\/courses\/([^/]+)$/);
    if (courseIdMatch) {
      const courseId = courseIdMatch[1];
      if (method === "GET") return await getCourse(courseId);
      if (method === "PUT") return await updateCourse(userId, courseId, body);
      if (method === "DELETE") return await deleteCourse(userId, courseId);
    }

    // ── Lessons ──
    const lessonsMatch = path.match(/^\/courses\/([^/]+)\/lessons$/);
    if (lessonsMatch) {
      const courseId = lessonsMatch[1];
      if (method === "GET") return await getLessons(courseId);
      if (method === "POST") return await addLesson(userId, courseId, body);
    }

    const lessonMatch = path.match(
      /^\/courses\/([^/]+)\/lessons\/([^/]+)$/
    );
    if (lessonMatch) {
      const [, courseId, lessonId] = lessonMatch;
      if (method === "PUT")
        return await updateLesson(userId, courseId, lessonId, body);
      if (method === "DELETE")
        return await deleteLesson(userId, courseId, lessonId);
    }

    // ── Enrollment ──
    const enrollMatch = path.match(/^\/courses\/([^/]+)\/enroll$/);
    if (enrollMatch && method === "POST") {
      return await enrollStudent(userId, enrollMatch[1]);
    }

    return response(404, { error: "Route not found" });
  } catch (error) {
    log('ERROR', 'Courses handler error', { error: error.message, path, method });
    return response(500, { error: error.message });
  }
};

// ── List Courses ───────────────────────────────────────────
async function listCourses(queryParams = {}) {
  const { category, limit = "20", lastKey } = queryParams || {};

  if (category) {
    const params = {
      TableName: COURSES_TABLE,
      IndexName: "category-index",
      KeyConditionExpression: "category = :cat",
      ExpressionAttributeValues: { ":cat": category },
      Limit: parseInt(limit, 10),
    };
    if (lastKey) {
      try { params.ExclusiveStartKey = JSON.parse(decodeURIComponent(lastKey)); } catch {}
    }
    const result = await dynamodb.send(new QueryCommand(params));
    return response(200, {
      courses: result.Items || [],
      count: result.Count || 0,
      lastKey: result.LastEvaluatedKey
        ? encodeURIComponent(JSON.stringify(result.LastEvaluatedKey))
        : null,
    });
  }

  const params = {
    TableName: COURSES_TABLE,
    Limit: parseInt(limit, 10),
  };
  if (lastKey) {
    try { params.ExclusiveStartKey = JSON.parse(decodeURIComponent(lastKey)); } catch {}
  }
  const result = await dynamodb.send(new ScanCommand(params));
  return response(200, {
    courses: result.Items || [],
    count: result.Count || 0,
    lastKey: result.LastEvaluatedKey
      ? encodeURIComponent(JSON.stringify(result.LastEvaluatedKey))
      : null,
  });
}

// ── Get Course ─────────────────────────────────────────────
async function getCourse(courseId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!result.Item) return response(404, { error: "Course not found" });
  return response(200, result.Item);
}

// ── Create Course ──────────────────────────────────────────
async function createCourse(teacherId, data) {
  const courseId = randomUUID();
  const now = new Date().toISOString();

  const course = {
    courseId,
    teacherId,
    title: data.title,
    description: data.description || "",
    category: data.category || "General",
    duration: data.duration || "",
    price: data.price || 0,
    imageUrl: data.imageUrl || "",
    level: data.level || "Beginner",
    rating: 0,
    enrollmentCount: 0,
    status: "draft",
    createdAt: now,
    updatedAt: now,
  };

  await dynamodb.send(
    new PutCommand({ TableName: COURSES_TABLE, Item: course })
  );

  log('INFO', 'Course created', { courseId, teacherId, title: data.title });
  return response(201, course);
}

// ── Update Course ──────────────────────────────────────────
async function updateCourse(teacherId, courseId, data) {
  // Verify ownership
  const existing = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!existing.Item) return response(404, { error: "Course not found" });
  if (existing.Item.teacherId !== teacherId) {
    return response(403, { error: "Not authorized to edit this course" });
  }

  const allowedFields = [
    "title",
    "description",
    "category",
    "duration",
    "price",
    "imageUrl",
    "level",
    "status",
  ];
  const parts = [];
  const values = {};
  const names = {};

  for (const field of allowedFields) {
    if (data[field] !== undefined) {
      parts.push(`#${field} = :${field}`);
      values[`:${field}`] = data[field];
      names[`#${field}`] = field;
    }
  }
  parts.push("#updatedAt = :updatedAt");
  values[":updatedAt"] = new Date().toISOString();
  names["#updatedAt"] = "updatedAt";

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: COURSES_TABLE,
      Key: { courseId },
      UpdateExpression: `SET ${parts.join(", ")}`,
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Delete Course ──────────────────────────────────────────
async function deleteCourse(teacherId, courseId) {
  // 1. Verify ownership
  const existing = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!existing.Item) return response(404, { error: "Course not found" });
  if (existing.Item.teacherId !== teacherId) {
    return response(403, { error: "Not authorized" });
  }

  // 2. Block delete if students are enrolled
  const enrollments = await dynamodb.send(
    new ScanCommand({
      TableName: ENROLLMENTS_TABLE,
      FilterExpression: "courseId = :cid",
      ExpressionAttributeValues: { ":cid": courseId },
    })
  );
  if ((enrollments.Items || []).length > 0) {
    return response(409, { error: "Cannot delete a course with enrolled students" });
  }

  // 3. Cascade-delete all lessons
  const lessons = await dynamodb.send(
    new QueryCommand({
      TableName: LESSONS_TABLE,
      KeyConditionExpression: "courseId = :courseId",
      ExpressionAttributeValues: { ":courseId": courseId },
    })
  );
  for (const lesson of (lessons.Items || [])) {
    await dynamodb.send(
      new DeleteCommand({
        TableName: LESSONS_TABLE,
        Key: { courseId: lesson.courseId, lessonId: lesson.lessonId },
      })
    );
  }

  // 4. Delete the course
  await dynamodb.send(
    new DeleteCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );

  log('INFO', 'Course deleted', { courseId, teacherId });
  return response(200, { message: "Course deleted" });
}

// ── Get Lessons ────────────────────────────────────────────
async function getLessons(courseId) {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: LESSONS_TABLE,
      KeyConditionExpression: "courseId = :courseId",
      ExpressionAttributeValues: { ":courseId": courseId },
    })
  );
  return response(200, { lessons: result.Items });
}

// ── Add Lesson ─────────────────────────────────────────────
async function addLesson(teacherId, courseId, data) {
  // Verify course ownership
  const course = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!course.Item || course.Item.teacherId !== teacherId) {
    return response(403, { error: "Not authorized" });
  }

  const lessonId = randomUUID();
  const lesson = {
    courseId,
    lessonId,
    title: data.title,
    description: data.description || "",
    videoUrl: data.videoUrl || "",
    duration: data.duration || "",
    order: data.order || 0,
    createdAt: new Date().toISOString(),
  };

  await dynamodb.send(
    new PutCommand({ TableName: LESSONS_TABLE, Item: lesson })
  );

  return response(201, lesson);
}

// ── Update Lesson ──────────────────────────────────────────
async function updateLesson(teacherId, courseId, lessonId, data) {
  const course = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!course.Item || course.Item.teacherId !== teacherId) {
    return response(403, { error: "Not authorized" });
  }

  const parts = [];
  const values = {};
  const names = {};

  for (const field of ["title", "description", "videoUrl", "duration", "order"]) {
    if (data[field] !== undefined) {
      parts.push(`#${field} = :${field}`);
      values[`:${field}`] = data[field];
      names[`#${field}`] = field;
    }
  }

  if (parts.length === 0) return response(400, { error: "Nothing to update" });

  const result = await dynamodb.send(
    new UpdateCommand({
      TableName: LESSONS_TABLE,
      Key: { courseId, lessonId },
      UpdateExpression: `SET ${parts.join(", ")}`,
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      ReturnValues: "ALL_NEW",
    })
  );

  return response(200, result.Attributes);
}

// ── Delete Lesson ──────────────────────────────────────────
async function deleteLesson(teacherId, courseId, lessonId) {
  const course = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!course.Item || course.Item.teacherId !== teacherId) {
    return response(403, { error: "Not authorized" });
  }

  await dynamodb.send(
    new DeleteCommand({
      TableName: LESSONS_TABLE,
      Key: { courseId, lessonId },
    })
  );

  return response(200, { message: "Lesson deleted" });
}

// ── Enroll Student ─────────────────────────────────────────
async function enrollStudent(studentId, courseId) {
  const course = await dynamodb.send(
    new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } })
  );
  if (!course.Item) return response(404, { error: "Course not found" });

  const enrollment = {
    studentId,
    courseId,
    enrolledAt: new Date().toISOString(),
    progress: 0,
    status: "active",
  };

  await dynamodb.send(
    new PutCommand({ TableName: ENROLLMENTS_TABLE, Item: enrollment })
  );

  log('INFO', 'Student enrolled', { studentId, courseId });

  // Increment enrollment count
  await dynamodb.send(
    new UpdateCommand({
      TableName: COURSES_TABLE,
      Key: { courseId },
      UpdateExpression: "SET enrollmentCount = enrollmentCount + :inc",
      ExpressionAttributeValues: { ":inc": 1 },
    })
  );

  return response(201, enrollment);
}

// ── My Enrolled Courses ────────────────────────────────────
async function getMyEnrolledCourses(studentId) {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: ENROLLMENTS_TABLE,
      KeyConditionExpression: "studentId = :studentId",
      ExpressionAttributeValues: { ":studentId": studentId },
    })
  );

  // Fetch course details for each enrollment
  const courses = [];
  for (const enrollment of result.Items) {
    const course = await dynamodb.send(
      new GetCommand({
        TableName: COURSES_TABLE,
        Key: { courseId: enrollment.courseId },
      })
    );
    if (course.Item) {
      courses.push({ ...course.Item, enrollment });
    }
  }

  return response(200, { courses, count: courses.length });
}

// ── My Created Courses (Teacher) ───────────────────────────
async function getMyCreatedCourses(teacherId) {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: COURSES_TABLE,
      IndexName: "teacher-index",
      KeyConditionExpression: "teacherId = :teacherId",
      ExpressionAttributeValues: { ":teacherId": teacherId },
    })
  );

  return response(200, { courses: result.Items, count: result.Count });
}
