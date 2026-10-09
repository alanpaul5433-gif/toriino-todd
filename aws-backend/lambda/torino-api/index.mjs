import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, ScanCommand, QueryCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import Stripe from "stripe";
import crypto from "crypto";
import https from "https";
import agoraToken from "agora-token";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

const { RtcTokenBuilder, RtcRole } = agoraToken;

// Secrets come from SSM SecureStrings under SSM_PREFIX (cached 5 min); the
// placeholder NOT_SET means "not configured" → HTTP 503. No secret env copies.
const ssm = new SSMClient({ region: "us-east-1" });
const secretCache = {};
async function getSecret(name) {
  const prefix = process.env.SSM_PREFIX;
  if (!prefix) return null;
  const hit = secretCache[name];
  if (hit && Date.now() - hit.at < 5 * 60 * 1000) return hit.value;
  let value = null;
  try {
    const out = await ssm.send(new GetParameterCommand({ Name: `${prefix}${name}`, WithDecryption: true }));
    const raw = out.Parameter?.Value;
    value = raw && raw !== "NOT_SET" ? raw : null;
  } catch (err) {
    if (err.name !== "ParameterNotFound") throw err;
  }
  secretCache[name] = { value, at: Date.now() };
  return value;
}

const s3Client = new S3Client({ region: "us-east-1" });
const COURSE_MATERIALS_BUCKET = "toriino-recordings-888245942659";

const stripe = process.env.STRIPE_SECRET_KEY
  ? new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: "2024-06-20" })
  : null;

const client = new DynamoDBClient({ region: "us-east-1" });
const db = DynamoDBDocumentClient.from(client);

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS,PATCH"
};

const res = (statusCode, body) => ({
  statusCode,
  headers: { ...CORS, "Content-Type": "application/json" },
  body: JSON.stringify(body)
});

// Extract Cognito userId (sub) from the Authorization Bearer token.
// API Gateway / Cognito Authorizer already verified the signature â€"
// we just decode the payload to get the sub claim.
function getUserIdFromToken(event) {
  try {
    const authHeader = event.headers?.Authorization || event.headers?.authorization || "";
    if (!authHeader.startsWith("Bearer ")) return null;
    const token = authHeader.slice(7);
    const payloadB64 = token.split(".")[1];
    if (!payloadB64) return null;
    const decoded = JSON.parse(Buffer.from(payloadB64, "base64url").toString("utf8"));
    return decoded.sub || null;
  } catch {
    return null;
  }
}

// Return a zero-earnings summary object
function emptyEarnings(userId) {
  return {
    currentMonth: { userId, periodKey: new Date().toISOString().slice(0, 7), amount: 0, sessions: 0 },
    totalEarnings: 0,
    monthlyBreakdown: []
  };
}

// â"€â"€ Agora Cloud Recording helpers â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
async function agoraCloudRequest(method, path, body, customerId, customerSecret) {
  const auth = Buffer.from(`${customerId}:${customerSecret}`).toString("base64");
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : undefined;
    const req = https.request(
      { hostname: "api.agora.io", path, method, headers: {
          "Authorization": `Basic ${auth}`,
          "Content-Type": "application/json",
          ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}),
        }
      },
      (res) => {
        let buf = "";
        res.on("data", c => buf += c);
        res.on("end", () => { try { resolve(JSON.parse(buf)); } catch { resolve(buf); } });
      }
    );
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

// â"€â"€ Gemini helper (model-agnostic faÃ§ade) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
async function callGemini(prompt) {
  const apiKey = await getSecret("GEMINI_API_KEY");
  if (!apiKey) {
    const err = new Error("Gemini not configured");
    err.code = "NOT_CONFIGURED";
    throw err;
  }
  const body = JSON.stringify({
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.3, maxOutputTokens: 2048 }
  });
  return new Promise((resolve, reject) => {
    const path = `/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
    const req = https.request(
      { hostname: "generativelanguage.googleapis.com", path, method: "POST",
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) }
      },
      (res) => {
        let buf = "";
        res.on("data", c => buf += c);
        res.on("end", () => {
          try {
            const json = JSON.parse(buf);
            resolve(json.candidates?.[0]?.content?.parts?.[0]?.text || "");
          } catch { resolve(""); }
        });
      }
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

export const handler = async (event) => {
  const method = event.httpMethod;
  const path = event.path;
  const body = event.body ? JSON.parse(event.body) : {};
  const segments = path.split("/").filter(Boolean);
  const qs = event.queryStringParameters || {};

  if (method === "OPTIONS") return res(200, {});

  try {

    // â"€â"€ USERS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "users") {

      // GET /users/profile  â€" returns the authenticated caller's profile
      if (method === "GET" && segments[1] === "profile") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });

        const result = await db.send(new GetCommand({ TableName: "torino-users", Key: { userId } }));
        if (result.Item) return res(200, result.Item);

        // First login: create a stub profile from the JWT claims
        try {
          const token = (event.headers?.Authorization || event.headers?.authorization || "").slice(7);
          const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));
          const stub = {
            userId,
            email: payload.email || "",
            name: payload.name || payload["cognito:username"] || "",
            role: payload["custom:role"] || "Student",
            createdAt: new Date().toISOString(),
          };
          await db.send(new PutCommand({ TableName: "torino-users", Item: stub }));
          return res(200, stub);
        } catch {
          return res(200, { userId, name: "", email: "", role: "Student" });
        }
      }

      // PUT /users/profile  â€" update the authenticated caller's profile
      if (method === "PUT" && segments[1] === "profile") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        await db.send(new PutCommand({
          TableName: "torino-users",
          Item: { ...body, userId, updatedAt: new Date().toISOString() }
        }));
        return res(200, { message: "Profile updated" });
      }

      // GET /users/{userId}
      if (method === "GET" && segments[1]) {
        const result = await db.send(new GetCommand({ TableName: "torino-users", Key: { userId: segments[1] } }));
        return result.Item ? res(200, result.Item) : res(404, { message: "User not found" });
      }

      // GET /users
      if (method === "GET") {
        const result = await db.send(new ScanCommand({ TableName: "torino-users" }));
        return res(200, result.Items || []);
      }

      // POST /users
      if (method === "POST") {
        await db.send(new PutCommand({ TableName: "torino-users", Item: { ...body, createdAt: new Date().toISOString() } }));
        return res(201, { message: "User created", userId: body.userId });
      }

      // PUT /users/{userId}
      if (method === "PUT" && segments[1]) {
        await db.send(new PutCommand({
          TableName: "torino-users",
          Item: { ...body, userId: segments[1], updatedAt: new Date().toISOString() }
        }));
        return res(200, { message: "User updated" });
      }
    }

    // â"€â"€ COURSES â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "courses") {
      const courseId = segments[1];

      // GET /courses/my-courses  â€" student's enrolled courses
      if (method === "GET" && courseId === "my-courses") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        try {
          const enrollResult = await db.send(new ScanCommand({ TableName: "torino-enrollments" }));
          const enrolled = (enrollResult.Items || []).filter(e => e.studentId === userId);
          const courseIds = enrolled.map(e => e.courseId);
          const courseResult = await db.send(new ScanCommand({ TableName: "torino-courses" }));
          const courses = (courseResult.Items || []).filter(c => courseIds.includes(c.courseId));
          return res(200, { courses, count: courses.length });
        } catch {
          return res(200, { courses: [], count: 0 });
        }
      }

      // GET /courses/my-created  â€" teacher's own courses
      if (method === "GET" && courseId === "my-created") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        const result = await db.send(new ScanCommand({ TableName: "torino-courses" }));
        const courses = (result.Items || []).filter(c => c.teacherId === userId);
        return res(200, { courses, count: courses.length });
      }

      // GET /courses/upload-url  — presigned S3 PUT URL for lesson material upload
      if (method === "GET" && courseId === "upload-url") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        const { fileName, contentType, courseId: cId } = qs;
        if (!fileName || !contentType) return res(400, { message: "fileName and contentType are required" });
        const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
        const key = `courses/${cId || "uncategorized"}/${Date.now()}_${safeName}`;
        const command = new PutObjectCommand({
          Bucket: COURSE_MATERIALS_BUCKET,
          Key: key,
          ContentType: contentType,
        });
        const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
        const url = `https://${COURSE_MATERIALS_BUCKET}.s3.us-east-1.amazonaws.com/${key}`;
        return res(200, { uploadUrl, url, key });
      }

      // GET /courses/{courseId}/lessons  — list lessons for a course
      if (method === "GET" && segments[2] === "lessons") {
        const result = await db.send(new ScanCommand({ TableName: "torino-lessons" }));
        const lessons = (result.Items || []).filter(l => l.courseId === courseId);
        lessons.sort((a, b) => (parseInt(a.order) || 0) - (parseInt(b.order) || 0));
        return res(200, { lessons, count: lessons.length });
      }

      // POST /courses/{courseId}/lessons  — add a lesson to a course
      if (method === "POST" && segments[2] === "lessons") {
        const userId = getUserIdFromToken(event);
        const lesson = {
          ...body,
          lessonId: body.lessonId || `les_${Date.now()}`,
          courseId,
          createdAt: new Date().toISOString(),
        };
        try {
          await db.send(new PutCommand({ TableName: "torino-lessons", Item: lesson }));
        } catch (e) {
          return res(500, { message: "Failed to save lesson", detail: e.message });
        }
        return res(201, { message: "Lesson added", lessonId: lesson.lessonId });
      }

      // PUT /courses/{courseId}/lessons/{lessonId}
      if (method === "PUT" && segments[2] === "lessons" && segments[3]) {
        const lessonId = segments[3];
        const updated = { ...body, lessonId, courseId, updatedAt: new Date().toISOString() };
        await db.send(new PutCommand({ TableName: "torino-lessons", Item: updated }));
        return res(200, { message: "Lesson updated" });
      }

      // DELETE /courses/{courseId}/lessons/{lessonId}
      if (method === "DELETE" && segments[2] === "lessons" && segments[3]) {
        const lessonId = segments[3];
        await db.send(new DeleteCommand({ TableName: "torino-lessons", Key: { lessonId } }));
        return res(200, { message: "Lesson deleted" });
      }

      // POST /courses/{courseId}/enroll  — enroll in a course
      if (method === "POST" && segments[2] === "enroll") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        const enrollment = {
          enrollmentId: `enr_${Date.now()}`,
          studentId: userId,
          courseId,
          enrolledAt: new Date().toISOString(),
          progress: 0,
          status: "active",
        };
        try {
          await db.send(new PutCommand({ TableName: "torino-enrollments", Item: enrollment }));
        } catch { /* table may not exist yet */ }
        return res(201, enrollment);
      }

      // GET /courses/{courseId}
      if (method === "GET" && courseId && !["my-courses", "my-created"].includes(courseId)) {
        const result = await db.send(new GetCommand({ TableName: "torino-courses", Key: { courseId } }));
        return result.Item ? res(200, result.Item) : res(404, { message: "Course not found" });
      }

      // GET /courses
      if (method === "GET") {
        const result = await db.send(new ScanCommand({ TableName: "torino-courses" }));
        let items = result.Items || [];
        if (qs.category) items = items.filter(c => c.category === qs.category);
        return res(200, { courses: items, count: items.length });
      }

      // POST /courses
      if (method === "POST") {
        const userId = getUserIdFromToken(event);
        const newCourse = { ...body, teacherId: userId, createdAt: new Date().toISOString() };
        await db.send(new PutCommand({ TableName: "torino-courses", Item: newCourse }));
        return res(201, { message: "Course created", courseId: body.courseId });
      }

      // PUT /courses/{courseId}
      if (method === "PUT" && courseId) {
        await db.send(new PutCommand({
          TableName: "torino-courses",
          Item: { ...body, courseId, updatedAt: new Date().toISOString() }
        }));
        return res(200, { message: "Course updated" });
      }

      // DELETE /courses/{courseId}
      if (method === "DELETE" && courseId) {
        await db.send(new DeleteCommand({ TableName: "torino-courses", Key: { courseId } }));
        return res(200, { message: "Course deleted" });
      }
    }

    // â"€â"€ SESSIONS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "sessions") {
      const sessionId = segments[1];

      // POST /sessions/token  â€" Agora RTC token (must come before generic session routes)
      if (method === "POST" && sessionId === "token") {
        const appId = process.env.AGORA_APP_ID;
        const appCert = await getSecret("AGORA_APP_CERTIFICATE"); // SSM SecureString, cached
        if (!appId || !appCert) return res(503, { message: "Agora not configured" });
        const { channelName, uid = 0, role = "publisher" } = body;
        if (!channelName) return res(400, { message: "channelName required" });
        // Official Agora AccessToken2 ("007") builder. The previous hand-written generator put the
        // legacy 006 layout behind a 007 prefix, which Agora rejects with error 110 (invalid token).
        const ttl = 3600;
        const token = RtcTokenBuilder.buildTokenWithUid(appId, appCert, String(channelName), Number(uid) || 0,
          role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER, ttl, ttl);
        return res(200, { token, expireTs: Math.floor(Date.now() / 1000) + ttl });
      }

      // GET /sessions/{sessionId}
      if (method === "GET" && sessionId) {
        const result = await db.send(new GetCommand({ TableName: "torino-sessions", Key: { sessionId } }));
        return result.Item ? res(200, result.Item) : res(404, { message: "Session not found" });
      }

      // GET /sessions
      if (method === "GET") {
        const userId = getUserIdFromToken(event);
        const result = await db.send(new ScanCommand({ TableName: "torino-sessions" }));
        let items = result.Items || [];
        const role = qs.role;
        if (userId && role === "mentor") items = items.filter(s => s.mentorId === userId);
        if (userId && role === "student") items = items.filter(s => s.studentId === userId);
        return res(200, { sessions: items, count: items.length });
      }

      // POST /sessions
      if (method === "POST") {
        const userId = getUserIdFromToken(event);
        const isMentorCreating = !!body.studentId; // mentor provides studentId; student booking provides mentorId
        const newSession = {
          ...body,
          mentorId: body.mentorId || (isMentorCreating ? userId : undefined),
          studentId: body.studentId || (!isMentorCreating ? userId : undefined),
          sessionId: body.sessionId || `ses_${Date.now()}`,
          status: body.status || "scheduled",
          createdAt: new Date().toISOString()
        };
        await db.send(new PutCommand({ TableName: "torino-sessions", Item: newSession }));
        return res(201, { message: "Session booked", sessionId: newSession.sessionId });
      }

      // PUT /sessions/{sessionId}
      if (method === "PUT" && sessionId) {
        await db.send(new PutCommand({
          TableName: "torino-sessions",
          Item: { ...body, sessionId, updatedAt: new Date().toISOString() }
        }));
        return res(200, { message: "Session updated" });
      }

      // PATCH /sessions/{sessionId}/status
      if (method === "PATCH" && sessionId && segments[2] === "status") {
        await db.send(new UpdateCommand({
          TableName: "torino-sessions",
          Key: { sessionId },
          UpdateExpression: "SET #s = :s, updatedAt = :u",
          ExpressionAttributeNames: { "#s": "status" },
          ExpressionAttributeValues: { ":s": body.status, ":u": new Date().toISOString() }
        }));
        return res(200, { message: "Status updated" });
      }

      // POST /sessions/{sessionId}/recording/start
      if (method === "POST" && sessionId && segments[2] === "recording" && segments[3] === "start") {
        const appId = process.env.AGORA_APP_ID;
        const customerId = process.env.AGORA_CUSTOMER_ID;
        const customerSecret = process.env.AGORA_CUSTOMER_SECRET;
        const s3Bucket = process.env.AGORA_S3_BUCKET;
        const s3Region = process.env.AGORA_S3_REGION || "us-east-1";
        const s3AccessKey = process.env.AGORA_S3_ACCESS_KEY;
        const s3SecretKey = process.env.AGORA_S3_SECRET_KEY;
        if (!appId || !customerId || !customerSecret || !s3Bucket) {
          return res(503, { message: "Cloud recording not configured" });
        }
        const { uid = 0 } = body;
        // Step 1: acquire resourceId
        const acquired = await agoraCloudRequest(
          "POST", `/v1/apps/${appId}/cloud_recording/acquire`,
          { cname: sessionId, uid: String(uid), clientRequest: { resourceExpiredHour: 1 } },
          customerId, customerSecret
        );
        if (!acquired.resourceId) return res(502, { message: "Failed to acquire recording resource", detail: acquired });
        // Step 2: start recording
        const started = await agoraCloudRequest(
          "POST", `/v1/apps/${appId}/cloud_recording/resourceid/${acquired.resourceId}/mode/mix/start`,
          {
            cname: sessionId, uid: String(uid),
            clientRequest: {
              token: body.agoraToken || "",
              recordingConfig: { streamTypes: 2, channelType: 1, videoStreamType: 0 },
              storageConfig: {
                vendor: 1, region: 0, bucket: s3Bucket,
                accessKey: s3AccessKey, secretKey: s3SecretKey,
                fileNamePrefix: ["recordings", sessionId]
              }
            }
          },
          customerId, customerSecret
        );
        if (!started.sid) return res(502, { message: "Failed to start recording", detail: started });
        // Store recording metadata on the session
        await db.send(new UpdateCommand({
          TableName: "torino-sessions",
          Key: { sessionId },
          UpdateExpression: "SET recordingResourceId = :r, recordingSid = :s, recordingStartedAt = :t, recordingStatus = :st",
          ExpressionAttributeValues: {
            ":r": acquired.resourceId, ":s": started.sid,
            ":t": new Date().toISOString(), ":st": "active"
          }
        }));
        return res(200, { resourceId: acquired.resourceId, sid: started.sid, status: "recording" });
      }

      // POST /sessions/{sessionId}/recording/stop
      if (method === "POST" && sessionId && segments[2] === "recording" && segments[3] === "stop") {
        const appId = process.env.AGORA_APP_ID;
        const customerId = process.env.AGORA_CUSTOMER_ID;
        const customerSecret = process.env.AGORA_CUSTOMER_SECRET;
        if (!appId || !customerId || !customerSecret) {
          return res(503, { message: "Cloud recording not configured" });
        }
        // Fetch resourceId and sid stored at start
        const sessionItem = await db.send(new GetCommand({ TableName: "torino-sessions", Key: { sessionId } }));
        const { recordingResourceId, recordingSid } = sessionItem.Item || {};
        if (!recordingResourceId || !recordingSid) return res(400, { message: "No active recording found" });
        const { uid = 0 } = body;
        const stopped = await agoraCloudRequest(
          "POST", `/v1/apps/${appId}/cloud_recording/resourceid/${recordingResourceId}/sid/${recordingSid}/mode/mix/stop`,
          { cname: sessionId, uid: String(uid), clientRequest: {} },
          customerId, customerSecret
        );
        await db.send(new UpdateCommand({
          TableName: "torino-sessions",
          Key: { sessionId },
          UpdateExpression: "SET recordingStatus = :st, recordingStoppedAt = :t, recordingFiles = :f",
          ExpressionAttributeValues: {
            ":st": "stopped", ":t": new Date().toISOString(),
            ":f": stopped.serverResponse?.fileList || []
          }
        }));
        return res(200, { status: "stopped", files: stopped.serverResponse?.fileList || [] });
      }

      // POST /sessions/{sessionId}/transcript  â€" store Flutter-accumulated transcript
      if (method === "POST" && sessionId && segments[2] === "transcript") {
        const userId = getUserIdFromToken(event);
        const { segments: transcriptSegments, totalDurationSeconds, recordedAt } = body;
        const item = {
          sessionId, userId,
          segments: transcriptSegments || [],
          totalDurationSeconds: totalDurationSeconds || 0,
          recordedAt: recordedAt || new Date().toISOString(),
          createdAt: new Date().toISOString(),
        };
        await db.send(new PutCommand({ TableName: "toriino-transcripts", Item: item }));
        return res(201, { message: "Transcript saved", sessionId });
      }

      // GET /sessions/{sessionId}/transcript
      if (method === "GET" && sessionId && segments[2] === "transcript") {
        try {
          const result = await db.send(new GetCommand({ TableName: "toriino-transcripts", Key: { sessionId } }));
          return result.Item ? res(200, result.Item) : res(404, { message: "Transcript not found" });
        } catch { return res(404, { message: "Transcript not found" }); }
      }

      // POST /sessions/{sessionId}/summary  â€" generate AI summary from stored transcript
      if (method === "POST" && sessionId && segments[2] === "summary") {
        const { transcript, subjectArea = "general" } = body;
        if (!transcript || transcript.trim().length === 0) {
          return res(400, { message: "transcript text required" });
        }
        const prompt = `You are an AI education assistant. Analyze this tutoring session transcript and respond ONLY with valid JSON (no markdown, no code fences).

Transcript:
${transcript.slice(0, 8000)}

Respond with this exact JSON structure:
{
  "summary": "2-3 sentence overview of what was covered",
  "actionItems": ["action 1", "action 2"],
  "keyTopics": ["topic 1", "topic 2"],
  "insights": ["insight 1", "insight 2"]
}`;
        let summaryData = { summary: "", actionItems: [], keyTopics: [], insights: [] };
        try {
          const raw = await callGemini(prompt);
          const cleaned = raw.replace(/```json\n?|\n?```/g, "").trim();
          summaryData = JSON.parse(cleaned);
        } catch (e) {
          if (e.code === "NOT_CONFIGURED") return res(503, { message: "Gemini not configured" });
          return res(502, { message: "Summary generation failed; nothing was saved" });
        }
        const item = {
          sessionId, subjectArea,
          ...summaryData,
          transcript,
          generatedAt: new Date().toISOString(),
        };
        await db.send(new PutCommand({ TableName: "toriino-session-summaries", Item: item }));
        return res(201, item);
      }

      // GET /sessions/{sessionId}/summary
      if (method === "GET" && sessionId && segments[2] === "summary") {
        try {
          const result = await db.send(new GetCommand({ TableName: "toriino-session-summaries", Key: { sessionId } }));
          return result.Item ? res(200, result.Item) : res(404, { message: "Summary not found" });
        } catch { return res(404, { message: "Summary not found" }); }
      }
    }

    // â"€â"€ AI MEMORY & TWINS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "ai") {
      const userId = getUserIdFromToken(event);
      if (!userId) return res(401, { message: "Unauthorized" });

      // GET /ai/memory/{targetUserId}
      if (method === "GET" && segments[1] === "memory" && segments[2]) {
        try {
          const result = await db.send(new GetCommand({ TableName: "toriino-ai-memory", Key: { userId: segments[2] } }));
          return res(200, result.Item || { userId: segments[2], events: [], preferences: {}, topicMastery: {} });
        } catch { return res(200, { userId: segments[2], events: [], preferences: {}, topicMastery: {} }); }
      }

      // POST /ai/memory/{userId}  â€" append a memory event
      if (method === "POST" && segments[1] === "memory" && segments[2]) {
        const targetUserId = segments[2];
        const { event: memEvent } = body; // { type, data, sessionId }
        const existing = await db.send(new GetCommand({ TableName: "toriino-ai-memory", Key: { userId: targetUserId } }));
        const current = existing.Item || { userId: targetUserId, events: [], preferences: {}, topicMastery: {} };
        current.events = [...(current.events || []).slice(-99), { ...memEvent, timestamp: new Date().toISOString() }];
        current.updatedAt = new Date().toISOString();
        if (body.preferences) current.preferences = { ...current.preferences, ...body.preferences };
        if (body.topicMastery) current.topicMastery = { ...current.topicMastery, ...body.topicMastery };
        await db.send(new PutCommand({ TableName: "toriino-ai-memory", Item: current }));
        return res(200, { message: "Memory updated" });
      }

      // GET /ai/twins/{userId}
      if (method === "GET" && segments[1] === "twins" && segments[2]) {
        try {
          const result = await db.send(new GetCommand({ TableName: "toriino-ai-twins", Key: { userId: segments[2] } }));
          return result.Item ? res(200, result.Item) : res(404, { message: "AI Twin not found" });
        } catch { return res(404, { message: "AI Twin not found" }); }
      }

      // POST /ai/twins/{userId}  â€" create or update AI Twin
      if (method === "POST" && segments[1] === "twins" && segments[2]) {
        const twin = { ...body, userId: segments[2], updatedAt: new Date().toISOString() };
        await db.send(new PutCommand({ TableName: "toriino-ai-twins", Item: twin }));
        return res(200, { message: "AI Twin saved", userId: segments[2] });
      }
    }

    // â"€â"€ MENTORS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "mentors") {
      const mentorId = segments[1];

      // GET /mentors/{mentorId}/availability
      if (method === "GET" && mentorId && segments[2] === "availability") {
        const result = await db.send(new GetCommand({ TableName: "torino-mentors", Key: { mentorId } }));
        return res(200, { availability: result.Item?.availability || [] });
      }

      // GET /mentors/{mentorId}
      if (method === "GET" && mentorId) {
        const result = await db.send(new GetCommand({ TableName: "torino-mentors", Key: { mentorId } }));
        return result.Item ? res(200, result.Item) : res(404, { message: "Mentor not found" });
      }

      // GET /mentors
      if (method === "GET") {
        const result = await db.send(new ScanCommand({ TableName: "torino-mentors" }));
        let items = result.Items || [];
        if (qs.expertise) items = items.filter(m => (m.expertise || []).includes(qs.expertise));
        return res(200, { mentors: items, count: items.length });
      }

      // POST /mentors
      if (method === "POST") {
        await db.send(new PutCommand({ TableName: "torino-mentors", Item: { ...body, createdAt: new Date().toISOString() } }));
        return res(201, { message: "Mentor created" });
      }

      // PUT /mentors/availability
      if (method === "PUT" && mentorId === "availability") {
        const userId = getUserIdFromToken(event);
        if (!userId) return res(401, { message: "Unauthorized" });
        await db.send(new UpdateCommand({
          TableName: "torino-mentors",
          Key: { mentorId: userId },
          UpdateExpression: "SET availability = :a, updatedAt = :u",
          ExpressionAttributeValues: { ":a": body.availability, ":u": new Date().toISOString() }
        }));
        return res(200, { message: "Availability updated" });
      }

      // POST /mentors/intro-video
      if (method === "POST" && mentorId === "intro-video") {
        return res(200, { uploadUrl: "https://s3.amazonaws.com/torino-media/intro-video-upload", key: `intro/${Date.now()}` });
      }
    }

    // â"€â"€ EARNINGS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "earnings") {
      const userId = getUserIdFromToken(event);
      if (!userId) return res(401, { message: "Unauthorized" });

      // GET /earnings
      if (method === "GET" && !segments[1]) {
        try {
          const result = await db.send(new ScanCommand({ TableName: "torino-earnings" }));
          const records = (result.Items || []).filter(r => r.userId === userId);
          if (records.length > 0) {
            const currentPeriod = new Date().toISOString().slice(0, 7);
            const currentRec = records.find(r => r.periodKey === currentPeriod) || records[records.length - 1];
            const totalEarnings = records.reduce((sum, r) => sum + (Number(r.totalAmount) || 0), 0);
            const breakdown = records.map(r => ({
              userId: r.userId,
              periodKey: r.periodKey,
              amount: Number(r.totalAmount) || 0,
              sessions: Number(r.sessionCount) || 0,
              createdAt: r.createdAt,
            }));
            return res(200, {
              currentMonth: {
                userId,
                periodKey: currentRec.periodKey,
                amount: Number(currentRec.totalAmount) || 0,
                sessions: Number(currentRec.sessionCount) || 0,
              },
              totalEarnings,
              monthlyBreakdown: breakdown,
            });
          }
        } catch { /* table may not exist */ }
        return res(200, emptyEarnings(userId));
      }

      // GET /earnings/history
      if (method === "GET" && segments[1] === "history") {
        try {
          const result = await db.send(new ScanCommand({ TableName: "torino-earnings" }));
          const records = (result.Items || []).filter(r => r.userId === userId);
          const history = records.map(r => ({
            userId: r.userId,
            periodKey: r.periodKey,
            amount: Number(r.totalAmount) || 0,
            sessions: Number(r.sessionCount) || 0,
            createdAt: r.createdAt,
          }));
          return res(200, { history });
        } catch {
          return res(200, { history: [] });
        }
      }

      // POST /earnings/withdraw
      if (method === "POST" && segments[1] === "withdraw") {
        const { amount, bankDetails, requestedAt } = body;
        if (!amount || Number(amount) <= 0) {
          return res(400, { message: "amount must be greater than 0" });
        }
        const withdrawal = {
          withdrawalId: `wd_${Date.now()}`,
          userId,
          amount: Number(amount),
          bankDetails: bankDetails || {},
          status: "pending",
          requestedAt: requestedAt || new Date().toISOString(),
          createdAt: new Date().toISOString(),
        };
        try {
          await db.send(new PutCommand({ TableName: "torino-withdrawals", Item: withdrawal }));
        } catch { /* table may not exist yet – best effort */ }
        return res(201, {
          message: "Withdrawal request submitted. Processing in 2–3 business days.",
          withdrawalId: withdrawal.withdrawalId,
          status: "pending",
        });
      }

      // POST /earnings
      if (method === "POST") {
        await db.send(new PutCommand({ TableName: "torino-earnings", Item: { ...body, userId, updatedAt: new Date().toISOString() } }));
        return res(201, { message: "Earnings updated" });
      }
    }

    // â"€â"€ PAYMENTS (Stripe) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "payments") {
      if (!stripe) return res(500, { message: "Stripe not configured. Set STRIPE_SECRET_KEY env var." });

      if (method === "POST" && segments[1] === "create-intent") {
        const { amount, currency = "usd", description = "" } = body;
        if (!amount || amount <= 0) return res(400, { message: "Invalid amount" });
        const intent = await stripe.paymentIntents.create({
          amount, currency, description,
          automatic_payment_methods: { enabled: true },
        });
        return res(200, { clientSecret: intent.client_secret });
      }

      if (method === "POST" && segments[1] === "webhook") {
        const sig = event.headers?.["stripe-signature"];
        const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
        let stripeEvent;
        try {
          stripeEvent = webhookSecret
            ? stripe.webhooks.constructEvent(event.body, sig, webhookSecret)
            : JSON.parse(event.body);
        } catch (err) {
          return res(400, { message: `Webhook signature error: ${err.message}` });
        }
        if (stripeEvent.type === "payment_intent.succeeded") {
          const pi = stripeEvent.data.object;
          console.log("Payment succeeded:", pi.id, pi.amount, pi.currency);
        }
        return res(200, { received: true });
      }
    }

    // â"€â"€ NOTIFICATIONS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "notifications") {
      const userId = getUserIdFromToken(event);
      if (!userId) return res(401, { message: "Unauthorized" });

      if (method === "GET") {
        try {
          const result = await db.send(new ScanCommand({ TableName: "torino-notifications" }));
          const items = (result.Items || []).filter(n => n.userId === userId);
          return res(200, { notifications: items, count: items.length });
        } catch {
          return res(200, { notifications: [], count: 0 });
        }
      }

      // POST /notifications/fcm-token
      if (method === "POST" && segments[1] === "fcm-token") {
        try {
          await db.send(new UpdateCommand({
            TableName: "torino-users",
            Key: { userId },
            UpdateExpression: "SET fcmToken = :t",
            ExpressionAttributeValues: { ":t": body.fcmToken }
          }));
        } catch { /* best effort */ }
        return res(200, { message: "FCM token saved" });
      }
    }

    // â"€â"€ REVIEWS â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
    if (segments[0] === "reviews") {
      const targetId = segments[1];

      if (method === "GET" && targetId) {
        try {
          const result = await db.send(new ScanCommand({ TableName: "torino-reviews" }));
          const items = (result.Items || []).filter(r => r.targetId === targetId);
          return res(200, { reviews: items, count: items.length });
        } catch {
          return res(200, { reviews: [], count: 0 });
        }
      }

      if (method === "POST") {
        const userId = getUserIdFromToken(event);
        const review = { ...body, reviewId: `rev_${Date.now()}`, authorId: userId, createdAt: new Date().toISOString() };
        try {
          await db.send(new PutCommand({ TableName: "torino-reviews", Item: review }));
        } catch { /* best effort */ }
        return res(201, review);
      }
    }

    return res(404, { message: "Route not found" });

  } catch (error) {
    console.error("Error:", error);
    return res(500, { message: "Internal server error", error: error.message });
  }
};
