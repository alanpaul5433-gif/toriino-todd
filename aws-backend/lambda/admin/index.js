const { DynamoDBClient, ScanCommand, GetItemCommand, UpdateItemCommand, DeleteItemCommand, QueryCommand } = require('@aws-sdk/client-dynamodb');
const { CognitoIdentityProviderClient, ListUsersCommand, AdminUpdateUserAttributesCommand, AdminDisableUserCommand, AdminEnableUserCommand, AdminAddUserToGroupCommand, AdminListGroupsForUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
const { marshall, unmarshall } = require('@aws-sdk/util-dynamodb');

const db = new DynamoDBClient({ region: 'us-east-1' });
const cognito = new CognitoIdentityProviderClient({ region: 'us-east-1' });

const COGNITO_USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

function res(status, body) {
  return { statusCode: status, headers: { ...cors, 'Content-Type': 'application/json' }, body: JSON.stringify(body) };
}

async function scanAll(TableName, FilterExpression, ExpressionAttributeValues) {
  const items = [];
  let LastEvaluatedKey;
  do {
    const params = { TableName, ExclusiveStartKey: LastEvaluatedKey };
    if (FilterExpression) { params.FilterExpression = FilterExpression; params.ExpressionAttributeValues = marshall(ExpressionAttributeValues); }
    const r = await db.send(new ScanCommand(params));
    items.push(...(r.Items || []).map(i => unmarshall(i)));
    LastEvaluatedKey = r.LastEvaluatedKey;
  } while (LastEvaluatedKey);
  return items;
}

// Dashboard aggregate stats
async function getDashboardStats() {
  const [users, courses, sessions, enrollments, earnings, reviews] = await Promise.all([
    scanAll('toriino-users'),
    scanAll('toriino-courses'),
    scanAll('toriino-sessions'),
    scanAll('toriino-enrollments'),
    scanAll('toriino-earnings'),
    scanAll('toriino-reviews'),
  ]);

  const now = new Date();
  const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const monthEarnings = earnings.filter(e => e.periodKey === monthKey);
  const totalRevenue = monthEarnings.reduce((s, e) => s + (e.totalAmount || 0), 0);

  const activeSessions = sessions.filter(s => s.status === 'in_progress').length;
  const completedSessions = sessions.filter(s => s.status === 'completed').length;

  const byRole = { Student: 0, Teacher: 0, Mentor: 0 };
  users.forEach(u => { if (u.role && byRole[u.role] !== undefined) byRole[u.role]++; });

  const avgRating = reviews.length ? (reviews.reduce((s, r) => s + (r.rating || 0), 0) / reviews.length).toFixed(1) : 0;

  // New users last 7 days
  const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
  const newUsers = users.filter(u => u.createdAt && new Date(u.createdAt).getTime() > weekAgo).length;

  return {
    totalUsers: users.length,
    usersByRole: byRole,
    newUsersThisWeek: newUsers,
    totalCourses: courses.length,
    publishedCourses: courses.filter(c => c.status === 'published').length,
    totalSessions: sessions.length,
    activeSessions,
    completedSessions,
    totalEnrollments: enrollments.length,
    monthlyRevenue: totalRevenue,
    totalReviews: reviews.length,
    averageRating: Number(avgRating),
  };
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});

  const method = event.httpMethod;
  const path = event.path || event.resource || '';
  const pathParts = path.replace(/^\/admin\/?/, '').split('/').filter(Boolean);
  const body = event.body ? JSON.parse(event.body) : {};
  const qs = event.queryStringParameters || {};

  try {
    // GET /admin/stats
    if (method === 'GET' && pathParts[0] === 'stats') {
      const stats = await getDashboardStats();
      return res(200, stats);
    }

    // GET /admin/users
    if (method === 'GET' && pathParts[0] === 'users' && !pathParts[1]) {
      const users = await scanAll('toriino-users');
      const roleFilter = qs.role;
      const search = qs.search?.toLowerCase();
      let result = roleFilter ? users.filter(u => u.role === roleFilter) : users;
      if (search) result = result.filter(u => u.name?.toLowerCase().includes(search) || u.email?.toLowerCase().includes(search) || u.phone?.includes(search));
      result.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
      return res(200, { users: result, total: result.length });
    }

    // PUT /admin/users/:id/status
    if (method === 'PUT' && pathParts[0] === 'users' && pathParts[2] === 'status') {
      const userId = pathParts[1];
      const { status } = body; // 'active' | 'disabled'
      await db.send(new UpdateItemCommand({
        TableName: 'toriino-users',
        Key: marshall({ userId }),
        UpdateExpression: 'SET #s = :s, updatedAt = :u',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: marshall({ ':s': status, ':u': new Date().toISOString() }),
      }));
      if (COGNITO_USER_POOL_ID) {
        const cmd = status === 'disabled' ? new AdminDisableUserCommand({ UserPoolId: COGNITO_USER_POOL_ID, Username: userId }) : new AdminEnableUserCommand({ UserPoolId: COGNITO_USER_POOL_ID, Username: userId });
        await cognito.send(cmd).catch(() => {});
      }
      return res(200, { success: true });
    }

    // PUT /admin/users/:id/role
    if (method === 'PUT' && pathParts[0] === 'users' && pathParts[2] === 'role') {
      const userId = pathParts[1];
      const { role } = body;
      await db.send(new UpdateItemCommand({
        TableName: 'toriino-users',
        Key: marshall({ userId }),
        UpdateExpression: 'SET #r = :r, updatedAt = :u',
        ExpressionAttributeNames: { '#r': 'role' },
        ExpressionAttributeValues: marshall({ ':r': role, ':u': new Date().toISOString() }),
      }));
      return res(200, { success: true });
    }

    // DELETE /admin/users/:id
    if (method === 'DELETE' && pathParts[0] === 'users' && pathParts[1]) {
      const userId = pathParts[1];
      await db.send(new DeleteItemCommand({ TableName: 'toriino-users', Key: marshall({ userId }) }));
      return res(200, { success: true });
    }

    // GET /admin/courses
    if (method === 'GET' && pathParts[0] === 'courses' && !pathParts[1]) {
      const courses = await scanAll('toriino-courses');
      const statusFilter = qs.status;
      let result = statusFilter ? courses.filter(c => c.status === statusFilter) : courses;
      result.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
      return res(200, { courses: result, total: result.length });
    }

    // PUT /admin/courses/:id/status
    if (method === 'PUT' && pathParts[0] === 'courses' && pathParts[2] === 'status') {
      const courseId = pathParts[1];
      const { status } = body; // 'published' | 'draft' | 'rejected'
      await db.send(new UpdateItemCommand({
        TableName: 'toriino-courses',
        Key: marshall({ courseId }),
        UpdateExpression: 'SET #s = :s, updatedAt = :u',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: marshall({ ':s': status, ':u': new Date().toISOString() }),
      }));
      return res(200, { success: true });
    }

    // DELETE /admin/courses/:id
    if (method === 'DELETE' && pathParts[0] === 'courses' && pathParts[1] && !pathParts[2]) {
      const courseId = pathParts[1];
      await db.send(new DeleteItemCommand({ TableName: 'toriino-courses', Key: marshall({ courseId }) }));
      return res(200, { success: true });
    }

    // GET /admin/sessions
    if (method === 'GET' && pathParts[0] === 'sessions' && !pathParts[1]) {
      const sessions = await scanAll('toriino-sessions');
      const statusFilter = qs.status;
      let result = statusFilter ? sessions.filter(s => s.status === statusFilter) : sessions;
      result.sort((a, b) => (b.createdAt || b.dateTime || '').localeCompare(a.createdAt || a.dateTime || ''));
      return res(200, { sessions: result, total: result.length });
    }

    // GET /admin/sessions/:id/summary
    if (method === 'GET' && pathParts[0] === 'sessions' && pathParts[2] === 'summary') {
      const sessionId = pathParts[1];
      const r = await db.send(new GetItemCommand({ TableName: 'toriino-session-summaries', Key: marshall({ sessionId }) }));
      if (!r.Item) return res(404, { error: 'No summary found' });
      return res(200, unmarshall(r.Item));
    }

    // PUT /admin/sessions/:id/status
    if (method === 'PUT' && pathParts[0] === 'sessions' && pathParts[2] === 'status') {
      const sessionId = pathParts[1];
      const { status } = body;
      await db.send(new UpdateItemCommand({
        TableName: 'toriino-sessions',
        Key: marshall({ sessionId }),
        UpdateExpression: 'SET #s = :s, updatedAt = :u',
        ExpressionAttributeNames: { '#s': 'status' },
        ExpressionAttributeValues: marshall({ ':s': status, ':u': new Date().toISOString() }),
      }));
      return res(200, { success: true });
    }

    // GET /admin/mentors
    if (method === 'GET' && pathParts[0] === 'mentors' && !pathParts[1]) {
      const mentors = await scanAll('toriino-mentors');
      const users = await scanAll('toriino-users');
      const usersMap = Object.fromEntries(users.map(u => [u.userId, u]));
      const reviews = await scanAll('toriino-reviews');
      const result = mentors.map(m => ({
        ...m,
        userProfile: usersMap[m.mentorId] || {},
        reviewCount: reviews.filter(r => r.targetId === m.mentorId).length,
        averageRating: (() => {
          const rv = reviews.filter(r => r.targetId === m.mentorId);
          return rv.length ? (rv.reduce((s, r) => s + (r.rating || 0), 0) / rv.length).toFixed(1) : 0;
        })(),
      }));
      return res(200, { mentors: result, total: result.length });
    }

    // PUT /admin/mentors/:id/approval
    if (method === 'PUT' && pathParts[0] === 'mentors' && pathParts[2] === 'approval') {
      const mentorId = pathParts[1];
      const { approved } = body;
      await db.send(new UpdateItemCommand({
        TableName: 'toriino-mentors',
        Key: marshall({ mentorId }),
        UpdateExpression: 'SET approved = :a, updatedAt = :u',
        ExpressionAttributeValues: marshall({ ':a': approved, ':u': new Date().toISOString() }),
      }));
      return res(200, { success: true });
    }

    // GET /admin/earnings
    if (method === 'GET' && pathParts[0] === 'earnings') {
      const earnings = await scanAll('toriino-earnings');
      const users = await scanAll('toriino-users');
      const usersMap = Object.fromEntries(users.map(u => [u.userId, u]));

      // Group by month for chart
      const byMonth = {};
      earnings.forEach(e => {
        if (!byMonth[e.periodKey]) byMonth[e.periodKey] = 0;
        byMonth[e.periodKey] += e.totalAmount || 0;
      });

      // Per-user breakdown
      const byUser = {};
      earnings.forEach(e => {
        if (!byUser[e.userId]) byUser[e.userId] = { userId: e.userId, name: usersMap[e.userId]?.name || 'Unknown', totalEarnings: 0, sessions: 0 };
        byUser[e.userId].totalEarnings += e.totalAmount || 0;
        byUser[e.userId].sessions += e.sessionCount || 0;
      });

      const platformTotal = earnings.reduce((s, e) => s + (e.totalAmount || 0), 0);

      return res(200, {
        platformTotal,
        byMonth: Object.entries(byMonth).sort((a, b) => a[0].localeCompare(b[0])).map(([month, amount]) => ({ month, amount })),
        byUser: Object.values(byUser).sort((a, b) => b.totalEarnings - a.totalEarnings),
      });
    }

    // GET /admin/reviews
    if (method === 'GET' && pathParts[0] === 'reviews' && !pathParts[1]) {
      const reviews = await scanAll('toriino-reviews');
      const ratingFilter = qs.rating ? Number(qs.rating) : null;
      const typeFilter = qs.type;
      let result = reviews;
      if (ratingFilter) result = result.filter(r => r.rating === ratingFilter);
      if (typeFilter) result = result.filter(r => r.targetType === typeFilter);
      result.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
      return res(200, { reviews: result, total: result.length });
    }

    // DELETE /admin/reviews/:targetId/:reviewId
    if (method === 'DELETE' && pathParts[0] === 'reviews' && pathParts[1] && pathParts[2]) {
      await db.send(new DeleteItemCommand({
        TableName: 'toriino-reviews',
        Key: marshall({ targetId: pathParts[1], reviewId: pathParts[2] }),
      }));
      return res(200, { success: true });
    }

    // GET /admin/ai/stats
    if (method === 'GET' && pathParts[0] === 'ai' && pathParts[1] === 'stats') {
      const [chats, summaries, transcripts, twins, memory] = await Promise.allSettled([
        scanAll('toriino-ai-chat'),
        scanAll('toriino-session-summaries'),
        scanAll('toriino-transcripts'),
        scanAll('toriino-ai-twins'),
        scanAll('toriino-ai-memory'),
      ]);

      return res(200, {
        totalChatMessages: chats.status === 'fulfilled' ? chats.value.length : 0,
        totalSummaries: summaries.status === 'fulfilled' ? summaries.value.length : 0,
        totalTranscripts: transcripts.status === 'fulfilled' ? transcripts.value.length : 0,
        totalTwins: twins.status === 'fulfilled' ? twins.value.length : 0,
        usersWithMemory: memory.status === 'fulfilled' ? memory.value.length : 0,
      });
    }

    // POST /admin/notifications/broadcast
    if (method === 'POST' && pathParts[0] === 'notifications' && pathParts[1] === 'broadcast') {
      const { title, message, targetRole } = body;
      if (!title || !message) return res(400, { error: 'title and message required' });

      const users = await scanAll('toriino-users');
      const targets = targetRole && targetRole !== 'all' ? users.filter(u => u.role === targetRole) : users;

      const notifId = `notif_${Date.now()}`;
      const notifTime = new Date().toISOString();

      await Promise.allSettled(targets.map(u =>
        db.send(new UpdateItemCommand({
          TableName: 'toriino-notifications',
          Key: marshall({ userId: u.userId, sortKey: `${notifTime}#${notifId}` }),
          UpdateExpression: 'SET #t = :t, #m = :m, isRead = :f, createdAt = :c, notifType = :n',
          ExpressionAttributeNames: { '#t': 'title', '#m': 'message' },
          ExpressionAttributeValues: marshall({ ':t': title, ':m': message, ':f': false, ':c': notifTime, ':n': 'admin_broadcast' }),
        }))
      ));

      return res(200, { success: true, sentTo: targets.length });
    }

    return res(404, { error: 'Not found' });

  } catch (err) {
    console.error(err);
    return res(500, { error: err.message });
  }
};
