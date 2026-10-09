/**
 * services.test.js — Jest tests for the security-relevant rules in the
 * sessions, courses, reviews and earnings Lambdas (DynamoDB mocked).
 *
 * Run from aws-backend/:  npx jest tests/services.test.js
 */

'use strict';

const mockSend = jest.fn();

jest.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('@aws-sdk/lib-dynamodb', () => {
  const cmd = (type) => jest.fn().mockImplementation((input) => ({ input, _type: type }));
  return {
    DynamoDBDocumentClient: { from: jest.fn().mockReturnValue({ send: mockSend }) },
    GetCommand: cmd('Get'),
    PutCommand: cmd('Put'),
    UpdateCommand: cmd('Update'),
    DeleteCommand: cmd('Delete'),
    QueryCommand: cmd('Query'),
    ScanCommand: cmd('Scan'),
    BatchGetCommand: cmd('BatchGet'),
    TransactWriteCommand: cmd('TransactWrite'),
  };
});

const mockSign = jest.fn().mockResolvedValue('https://signed.example/obj?X-Amz-Signature=x');
jest.mock('@aws-sdk/client-s3', () => ({
  S3Client: jest.fn().mockImplementation(() => ({})),
  GetObjectCommand: jest.fn().mockImplementation((input) => ({ input })),
  PutObjectCommand: jest.fn().mockImplementation((input) => ({ input })),
}), { virtual: true });
jest.mock('@aws-sdk/s3-request-presigner', () => ({ getSignedUrl: (...a) => mockSign(...a) }), { virtual: true });
jest.mock('@aws-sdk/client-cognito-identity-provider', () => ({
  CognitoIdentityProviderClient: jest.fn().mockImplementation(() => ({ send: jest.fn() })),
  AdminDeleteUserCommand: jest.fn(),
}), { virtual: true });

const mockSsmSend = jest.fn();
jest.mock('@aws-sdk/client-ssm', () => ({
  SSMClient: jest.fn().mockImplementation(() => ({ send: mockSsmSend })),
  GetParameterCommand: jest.fn().mockImplementation((input) => ({ input })),
}), { virtual: true });

Object.assign(process.env, {
  PLATFORM_FEE_PERCENT: '25',
  WALLET_TABLE: 'toriino-wallet',
  WALLET_EVENTS_TABLE: 'toriino-wallet-events',
  MEDIA_BUCKET: 'torino-app-storage',
  USERS_TABLE: 'torino-users',
  MENTORS_TABLE: 'torino-mentors',
  CDN_BASE: 'https://cdn.example.net',
  SESSIONS_TABLE: 'torino-sessions',
  COURSES_TABLE: 'torino-courses',
  LESSONS_TABLE: 'toriino-lessons',
  ENROLLMENTS_TABLE: 'toriino-enrollments',
  REVIEWS_TABLE: 'toriino-reviews',
  EARNINGS_TABLE: 'torino-earnings',
  EARNING_ENTRIES_TABLE: 'toriino-earning-entries',
  WITHDRAWALS_TABLE: 'toriino-withdrawals',
});

const sessions = require('../lambda/sessions/index').handler;
const courses = require('../lambda/courses/index').handler;
const reviews = require('../lambda/reviews/index').handler;
const earnings = require('../lambda/earnings/index').handler;
const users = require('../lambda/users/index').handler;
const payments = require('../lambda/payments/index').handler;

function ev(method, path, { sub = 'me', role = 'student', body, qs } = {}) {
  return {
    httpMethod: method,
    path,
    body: body ? JSON.stringify(body) : null,
    queryStringParameters: qs || null,
    requestContext: { authorizer: { claims: { sub, 'custom:role': role } } },
  };
}
const json = (r) => JSON.parse(r.body);

beforeEach(() => {
  mockSend.mockReset();
  mockSend.mockResolvedValue({});
});

describe('sessions: GET /sessions only returns the caller\'s sessions', () => {
  test.each([
    ['teacher', 'mentorId = :u OR teacherId = :u'],
    ['mentor', 'mentorId = :u OR teacherId = :u'],
    ['student', 'studentId = :u'],
    [undefined, 'studentId = :u OR mentorId = :u OR teacherId = :u'],
  ])('role=%s filters on the caller', async (role, filter) => {
    mockSend.mockResolvedValueOnce({ Items: [{ sessionId: 's1', mentorId: 'me' }] });
    const r = await sessions(ev('GET', '/sessions', { qs: role ? { role } : null }));
    expect(r.statusCode).toBe(200);
    const scan = mockSend.mock.calls[0][0];
    expect(scan.input.FilterExpression).toBe(filter);
    expect(scan.input.ExpressionAttributeValues[':u']).toBe('me');
  });

  test('GET /sessions/{id} of someone else → 403', async () => {
    mockSend.mockResolvedValueOnce({ Item: { sessionId: 's1', studentId: 'a', mentorId: 'b' } });
    const r = await sessions(ev('GET', '/sessions/s1'));
    expect(r.statusCode).toBe(403);
  });

  test('a student cannot book a session for another student', async () => {
    const r = await sessions(ev('POST', '/sessions', {
      body: { mentorId: 'm1', studentId: 'someone-else', dateTime: '2026-11-01T10:00:00Z' },
    }));
    expect(r.statusCode).toBe(403);
    expect(mockSend).not.toHaveBeenCalled();
  });
});

describe('courses: DELETE /courses/{id}', () => {
  const course = { courseId: 'c1', teacherId: 'me', status: 'published' };

  test('blocked with 409 while students are enrolled; nothing changed', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: course })                         // get course
      .mockResolvedValueOnce({ Items: [{ enrollmentId: 'e1' }] });     // enrollment scan
    const r = await courses(ev('DELETE', '/courses/c1', { role: 'teacher' }));
    expect(r.statusCode).toBe(409);
    expect(json(r).error).toBe('Cannot delete a course with enrolled students');
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Update' || c[0]._type === 'Delete')).toBe(false);
  });

  test('soft-deletes the course and cascades to its lessons', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: course })
      .mockResolvedValueOnce({ Items: [] })                                         // no enrollments
      .mockResolvedValueOnce({ Items: [{ courseId: 'c1', lessonId: 'l1' }, { courseId: 'c1', lessonId: 'l2' }] })
      .mockResolvedValue({});
    const r = await courses(ev('DELETE', '/courses/c1', { role: 'teacher' }));
    expect(r.statusCode).toBe(200);
    const updates = mockSend.mock.calls.map((c) => c[0]).filter((c) => c._type === 'Update');
    expect(updates).toHaveLength(3);
    expect(updates.every((u) => u.input.ExpressionAttributeValues[':d'] === 'deleted')).toBe(true);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Delete')).toBe(false);
  });

  test('only the owner can delete', async () => {
    mockSend.mockResolvedValueOnce({ Item: { ...course, teacherId: 'other' } });
    const r = await courses(ev('DELETE', '/courses/c1', { role: 'teacher' }));
    expect(r.statusCode).toBe(403);
  });

  test('list pagination returns lastKey', async () => {
    mockSend.mockResolvedValueOnce({ Items: [{ courseId: 'c1' }], LastEvaluatedKey: { courseId: 'c1' } });
    const r = await courses(ev('GET', '/courses', { qs: { limit: '1' } }));
    expect(r.statusCode).toBe(200);
    expect(json(r).lastKey).toBe(encodeURIComponent(JSON.stringify({ courseId: 'c1' })));
  });
});

describe('reviews: one review per student per target', () => {
  test('second review → 409 "already submitted a review"', async () => {
    mockSend.mockResolvedValueOnce({ Items: [{ reviewId: 'rev_me', reviewerId: 'me' }] });
    const r = await reviews(ev('POST', '/reviews', { body: { targetId: 'm1', targetType: 'mentor', rating: 5 } }));
    expect(r.statusCode).toBe(409);
    expect(json(r).error).toMatch(/already submitted a review/);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Put')).toBe(false);
  });

  test('first review is written with a deterministic id and a conditional put', async () => {
    mockSend.mockResolvedValueOnce({ Items: [] }).mockResolvedValue({});
    const r = await reviews(ev('POST', '/reviews', { body: { targetId: 'm1', targetType: 'mentor', rating: 4 } }));
    expect(r.statusCode).toBe(201);
    const put = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Put');
    expect(put.input.Item.reviewId).toBe('rev_me');
    expect(put.input.ConditionExpression).toBe('attribute_not_exists(reviewId)');
  });

  test('course review requires an enrollment', async () => {
    mockSend.mockResolvedValueOnce({ Items: [] }).mockResolvedValueOnce({ Items: [] });
    const r = await reviews(ev('POST', '/reviews', { body: { targetId: 'c1', targetType: 'course', rating: 4 } }));
    expect(r.statusCode).toBe(403);
  });
});

describe('earnings', () => {
  test('GET /earnings returns totalWithdrawn and availableBalance', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Get') return { Item: { userId: 'me', periodKey: '2026-10', totalAmount: 100, sessionCount: 2 } };
      if (c.input.TableName === 'toriino-earning-entries') return { Items: [{ amount: 20, status: 'available' }, { amount: 5, status: 'pending' }] };
      return { Items: [{ amount: 30, status: 'pending' }, { amount: 10, status: 'rejected' }] };
    });
    const r = await earnings(ev('GET', '/earnings', { role: 'mentor' }));
    const b = json(r);
    expect(r.statusCode).toBe(200);
    expect(b.totalEarnings).toBe(120);
    expect(b.totalWithdrawn).toBe(30);
    expect(b.availableBalance).toBe(90);
    expect(b.pendingEarnings).toBe(5);
    expect(b._version).toBeUndefined();
  });

  test('withdrawing more than the available balance → 409, nothing written', async () => {
    mockSend.mockImplementation(async (c) => (c._type === 'Get'
      ? { Item: { userId: 'me', periodKey: '2026-10', totalAmount: 50 } }
      : { Items: [] }));
    const r = await earnings(ev('POST', '/earnings/withdraw', { role: 'mentor', body: { amount: 60 } }));
    expect(r.statusCode).toBe(409);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'TransactWrite')).toBe(false);
  });

  test.each([
    [{ amount: 10, bankDetails: { accountNumber: '12345678', iban: 'GB00TEST' } }, ['bankDetails']],
    [{ amount: 10, accountNumber: '12345678', routingNumber: '000000000' }, ['accountNumber', 'routingNumber']],
  ])('withdraw with bank fields → 400, nothing read or written (%#)', async (body, fields) => {
    mockSend.mockResolvedValue({ Items: [] });
    const r = await earnings(ev('POST', '/earnings/withdraw', { role: 'teacher', body }));
    expect(r.statusCode).toBe(400);
    expect(json(r).rejectedFields).toEqual(fields);
    expect(mockSend).not.toHaveBeenCalled();
  });

  test('a valid withdrawal stores only amount, status and timestamps (no bank fields)', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Get') return { Item: { userId: 'me', periodKey: '2026-10', totalAmount: 50 } };
      if (c._type === 'TransactWrite') return {};
      return { Items: [] };
    });
    const r = await earnings(ev('POST', '/earnings/withdraw', { role: 'teacher', body: { amount: 20 } }));
    expect(r.statusCode).toBe(201);
    const tx = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'TransactWrite');
    const item = tx.input.TransactItems[1].Put.Item;
    expect(Object.keys(item).sort()).toEqual(['amount', 'createdAt', 'requestedAt', 'status', 'userId', 'withdrawalId']);
  });
});

describe('courses: paid enrollment and private lesson media', () => {
  test('enrolling in a PAID course → 402 "payment required", nothing written', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c9', price: 49, status: 'published' } })
      .mockResolvedValueOnce({ Items: [] });                       // not enrolled yet
    const r = await courses(ev('POST', '/courses/c9/enroll'));
    expect(r.statusCode).toBe(402);
    expect(json(r).error).toBe('payment required');
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Put')).toBe(false);
  });

  test('enrolling in a FREE course → 201', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c0', price: 0, status: 'active' } })
      .mockResolvedValueOnce({ Items: [] })
      .mockResolvedValue({});
    const r = await courses(ev('POST', '/courses/c0/enroll'));
    expect(r.statusCode).toBe(201);
    const put = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Put');
    expect(put.input.Item.enrollmentId).toBe('enr_c0_me');
  });

  test('paid lesson media without an enrollment → 402, no URL signed', async () => {
    mockSign.mockClear();
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c9', price: 49, teacherId: 't1' } })
      .mockResolvedValueOnce({ Item: { courseId: 'c9', lessonId: 'l1', videoKey: 'lessons/t1/v.mp4' } })
      .mockResolvedValueOnce({ Items: [] });
    const r = await courses(ev('GET', '/courses/c9/lessons/l1/media'));
    expect(r.statusCode).toBe(402);
    expect(mockSign).not.toHaveBeenCalled();
  });

  test('paid lesson media for an enrolled student → short-lived signed URL', async () => {
    mockSign.mockClear();
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c9', price: 49, teacherId: 't1' } })
      .mockResolvedValueOnce({ Item: { courseId: 'c9', lessonId: 'l1', videoKey: 'lessons/t1/v.mp4' } })
      .mockResolvedValueOnce({ Items: [{ enrollmentId: 'e', status: 'active' }] });
    const r = await courses(ev('GET', '/courses/c9/lessons/l1/media'));
    expect(r.statusCode).toBe(200);
    expect(json(r).videoUrl).toMatch(/^https:\/\/signed/);
    expect(mockSign.mock.calls[0][2]).toEqual({ expiresIn: 300 });
    expect(mockSign.mock.calls[0][1].input).toEqual({ Bucket: 'torino-app-storage', Key: 'lessons/t1/v.mp4' });
  });

  test('a refunded enrollment does not unlock paid media', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c9', price: 49, teacherId: 't1' } })
      .mockResolvedValueOnce({ Item: { courseId: 'c9', lessonId: 'l1', videoKey: 'lessons/t1/v.mp4' } })
      .mockResolvedValueOnce({ Items: [{ enrollmentId: 'e', status: 'refunded' }] });
    const r = await courses(ev('GET', '/courses/c9/lessons/l1/media'));
    expect(r.statusCode).toBe(402);
  });

  test("a lesson cannot point at someone else's upload", async () => {
    mockSend.mockResolvedValueOnce({ Item: { courseId: 'c9', price: 49, teacherId: 'me' } });
    const r = await courses(ev('POST', '/courses/c9/lessons', {
      role: 'teacher', body: { title: 'L', videoKey: 'lessons/other-user/v.mp4' },
    }));
    expect(r.statusCode).toBe(400);
  });
});

describe('users: introVideoUrl', () => {
  test("rejects a URL that is not the caller's intro-videos upload", async () => {
    const r = await users(ev('PUT', '/users/profile', { role: 'mentor', body: { introVideoUrl: 'https://evil.example/x.mp4' } }));
    expect(r.statusCode).toBe(400);
    expect(mockSend).not.toHaveBeenCalled();
  });

  test('saves the URL and mirrors it onto the mentor record', async () => {
    const url = 'https://cdn.example.net/intro-videos/me/v.mp4';
    mockSend.mockResolvedValueOnce({ Attributes: { userId: 'me', role: 'Mentor', introVideoUrl: url } }).mockResolvedValue({});
    const r = await users(ev('PUT', '/users/profile', { role: 'mentor', body: { introVideoUrl: url } }));
    expect(r.statusCode).toBe(200);
    const mirror = mockSend.mock.calls.map((c) => c[0]).filter((c) => c._type === 'Update')[1];
    expect(mirror.input.TableName).toBe('torino-mentors');
    expect(mirror.input.Key).toEqual({ mentorId: 'me' });
  });
});

describe('courses: POST /courses/{id}/complete', () => {
  test('marks the caller’s active enrollment completed', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c1', price: 0 } })
      .mockResolvedValueOnce({ Items: [{ enrollmentId: 'enr_c1_me', status: 'active' }] })
      .mockResolvedValue({});
    const r = await courses(ev('POST', '/courses/c1/complete'));
    expect(r.statusCode).toBe(200);
    const upd = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Update');
    expect(upd.input.Key).toEqual({ enrollmentId: 'enr_c1_me' });
    expect(upd.input.ExpressionAttributeValues[':c']).toBe('completed');
  });

  test('not enrolled (or refunded) → 404, nothing written', async () => {
    mockSend
      .mockResolvedValueOnce({ Item: { courseId: 'c1', price: 0 } })
      .mockResolvedValueOnce({ Items: [{ enrollmentId: 'e', status: 'refunded' }] });
    const r = await courses(ev('POST', '/courses/c1/complete'));
    expect(r.statusCode).toBe(404);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Update')).toBe(false);
  });
});

describe('users: GET /users/{id} — who may view a student profile', () => {
  // A student record carrying private fields that must never leak.
  const STUDENT = {
    userId: 'stu1', role: 'Student', name: 'Sam Student', avatarUrl: 'https://cdn.example.net/profiles/stu1/a.png',
    bio: 'Learning', email: 'sam@example.com', phone: '+100000', fcmToken: 'tok', walletBalance: 50,
  };

  // Answers by table, so the tests don't depend on the order of calls.
  function db({ sessions = [], courses = [], enrollments = [] }) {
    mockSend.mockImplementation(async (c) => {
      const t = c.input.TableName;
      if (c._type === 'Get' && t === 'torino-users') return { Item: c.input.Key.userId === 'stu1' ? STUDENT : undefined };
      if (c._type === 'Get' && t === 'torino-mentors') return {};
      if (c._type === 'Scan' && t === 'torino-sessions') return { Items: sessions };
      if (c._type === 'Scan' && t === 'torino-courses') return { Items: courses };
      if (c._type === 'Scan' && t === 'toriino-enrollments') return { Items: enrollments };
      throw new Error(`unexpected ${c._type} on ${t}`);
    });
  }
  const PRIVATE = ['email', 'phone', 'fcmToken', 'walletBalance'];

  test('allowed for a mentor who shares a session with the student', async () => {
    db({ sessions: [{ sessionId: 's1', studentId: 'stu1', mentorId: 'me', title: 'Algebra', dateTime: '2027-01-01T10:00:00Z', notes: 'private note' }] });
    const r = await users(ev('GET', '/users/stu1', { role: 'mentor' }));
    expect(r.statusCode).toBe(200);
    const b = json(r);
    expect(b).toMatchObject({ userId: 'stu1', name: 'Sam Student', bio: 'Learning' });
    expect(b.sharedSessions).toEqual([{ sessionId: 's1', title: 'Algebra', dateTime: '2027-01-01T10:00:00Z' }]);
    for (const f of PRIVATE) expect(b).not.toHaveProperty(f);
    expect(JSON.stringify(b)).not.toMatch(/sam@example\.com|private note/);
    // The session scan is restricted to sessions between this student and the caller.
    const scan = mockSend.mock.calls.map((c) => c[0]).find((c) => c.input.TableName === 'torino-sessions');
    expect(scan.input.ExpressionAttributeValues).toEqual({ ':s': 'stu1', ':c': 'me' });
  });

  test('allowed for a teacher whose course the student is enrolled in', async () => {
    db({
      courses: [{ courseId: 'c1', teacherId: 'me', title: 'Physics', status: 'published', price: 20 }],
      enrollments: [{ enrollmentId: 'e1', userId: 'stu1', courseId: 'c1', status: 'active', progress: 40 }],
    });
    const r = await users(ev('GET', '/users/stu1', { role: 'teacher' }));
    expect(r.statusCode).toBe(200);
    const b = json(r);
    expect(b.sharedCourses).toEqual([expect.objectContaining({ courseId: 'c1', title: 'Physics', enrollmentStatus: 'active', progress: 40 })]);
    expect(b.sharedCourses[0]).not.toHaveProperty('price');
    for (const f of PRIVATE) expect(b).not.toHaveProperty(f);
  });

  test('403 for an unrelated student (no shared session, enrolled only in other teachers’ courses)', async () => {
    db({
      courses: [{ courseId: 'c1', teacherId: 'me', status: 'published' }],
      enrollments: [{ enrollmentId: 'e2', userId: 'stu1', courseId: 'someone-elses-course', status: 'active' }],
    });
    const r = await users(ev('GET', '/users/stu1', { role: 'teacher' }));
    expect(r.statusCode).toBe(403);
    expect(r.body).not.toMatch(/Sam Student|sam@example\.com/);
  });

  test('403 when the only enrollment in the caller’s course was refunded', async () => {
    db({
      courses: [{ courseId: 'c1', teacherId: 'me', status: 'published' }],
      enrollments: [{ enrollmentId: 'e1', userId: 'stu1', courseId: 'c1', status: 'refunded' }],
    });
    const r = await users(ev('GET', '/users/stu1', { role: 'teacher' }));
    expect(r.statusCode).toBe(403);
  });

  test('403 when a student tries to view another student, without reading any sessions', async () => {
    db({ sessions: [{ sessionId: 's1', studentId: 'stu1', mentorId: 'me' }] });
    const r = await users(ev('GET', '/users/stu1', { role: 'student' }));
    expect(r.statusCode).toBe(403);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Scan')).toBe(false);
  });

  test('a teacher profile is public but still whitelisted', async () => {
    mockSend.mockImplementation(async (c) => {
      const t = c.input.TableName;
      if (c._type === 'Get' && t === 'torino-users') return { Item: { userId: 't9', role: 'Teacher', name: 'Tia', bio: 'Physics', email: 'tia@example.com', phone: '1' } };
      if (c._type === 'Get') return {};
      if (c._type === 'Scan' && t === 'torino-courses') return { Items: [
        { courseId: 'c1', teacherId: 't9', title: 'Live', status: 'published' },
        { courseId: 'c2', teacherId: 't9', title: 'Hidden', status: 'draft' },
      ] };
      throw new Error(`unexpected ${c._type} on ${t}`);
    });
    const r = await users(ev('GET', '/users/t9', { role: 'student' }));
    expect(r.statusCode).toBe(200);
    const b = json(r);
    expect(b).toMatchObject({ userId: 't9', role: 'Teacher', name: 'Tia' });
    expect(b.courses.map((c) => c.courseId)).toEqual(['c1']);
    expect(b).not.toHaveProperty('email');
    expect(b).not.toHaveProperty('phone');
  });
});

describe('courses: teacherName', () => {
  test('course list responses carry the teacher display name only', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Scan') return { Items: [{ courseId: 'c1', teacherId: 't9', title: 'X' }] };
      if (c._type === 'BatchGet') return { Responses: { 'torino-users': [{ userId: 't9', name: 'Tia' }] } };
      return {};
    });
    const r = await courses(ev('GET', '/courses'));
    expect(json(r).courses[0]).toMatchObject({ courseId: 'c1', teacherName: 'Tia' });
    const bg = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'BatchGet');
    expect(bg.input.RequestItems['torino-users'].ProjectionExpression).toBe('userId, #n');
  });
});

describe('payments: server-side fee, quote and wallet', () => {
  afterEach(() => { process.env.PLATFORM_FEE_PERCENT = '25'; });

  test('course quote: fee and teacher share in cents, parts add up', async () => {
    mockSend.mockResolvedValueOnce({ Item: { courseId: 'c1', price: 59.99 } });
    const r = await payments(ev('GET', '/payments/quote', { qs: { courseId: 'c1' } }));
    expect(r.statusCode).toBe(200);
    expect(json(r)).toMatchObject({ price: 59.99, platformFeePercent: 25, platformFee: 15, teacherShare: 44.99, amountDue: 59.99 });
  });

  test('no configured fee → 503, never a guessed fee', async () => {
    delete process.env.PLATFORM_FEE_PERCENT;
    mockSsmSend.mockRejectedValueOnce(Object.assign(new Error('nf'), { name: 'ParameterNotFound' }));
    const r = await payments(ev('GET', '/payments/quote', { qs: { courseId: 'c1' } }));
    expect(r.statusCode).toBe(503);
    expect(json(r).error).toBe('Platform fee not configured');
  });

  test('session fully covered by the wallet: one atomic transaction, mentor gets price − fee', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Get' && c.input.TableName === 'torino-sessions') return { Item: { sessionId: 's1', studentId: 'me', mentorId: 'm1', price: 40 } };
      if (c._type === 'Get' && c.input.TableName === 'toriino-wallet') return { Item: { userId: 'me', balance: 70 } };
      return {};
    });
    const r = await payments(ev('POST', '/payments/create-intent', { body: { type: 'session_booking', sessionId: 's1' } }));
    expect(r.statusCode).toBe(200);
    expect(json(r)).toMatchObject({ paidWithWallet: true, amountCharged: 40, platformFee: 10, teacherShare: 30 });
    const tx = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'TransactWrite').input.TransactItems;
    expect(tx).toHaveLength(4);
    expect(tx[0].Update.ConditionExpression).toBe('balance >= :a');
    expect(tx[0].Update.ExpressionAttributeValues[':a']).toBe(40);
    expect(tx[3].Put.Item).toMatchObject({ userId: 'm1', amount: 30, platformFee: 10, status: 'pending' });
  });

  test('wallet too low and Stripe not configured → 503, wallet untouched (no partial split)', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c.input.TableName === 'torino-sessions') return { Item: { sessionId: 's1', studentId: 'me', mentorId: 'm1', price: 40 } };
      if (c.input.TableName === 'toriino-wallet') return { Item: { userId: 'me', balance: 10 } };
      return {};
    });
    mockSsmSend.mockResolvedValue({ Parameter: { Value: 'NOT_SET' } });
    const r = await payments(ev('POST', '/payments/create-intent', { body: { type: 'session_booking', sessionId: 's1' } }));
    expect(r.statusCode).toBe(503);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'TransactWrite' || c[0]._type === 'Update')).toBe(false);
  });

  test('another student cannot pay for (or quote) someone else’s session', async () => {
    mockSend.mockResolvedValue({ Item: { sessionId: 's1', studentId: 'other', mentorId: 'm1', price: 40 } });
    const r = await payments(ev('GET', '/payments/quote', { qs: { sessionId: 's1' } }));
    expect(r.statusCode).toBe(403);
  });
});

describe('sessions: server-set price and display names', () => {
  test('a student booking ignores the client price and uses hourlyRate × duration', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Get' && c.input.TableName === 'torino-mentors') return { Item: { mentorId: 'm1', hourlyRate: 80, approved: true } };
      return {};
    });
    const r = await sessions(ev('POST', '/sessions', { body: { mentorId: 'm1', dateTime: '2027-02-01T10:00:00Z', duration: 30, price: 0.01 } }));
    expect(r.statusCode).toBe(201);
    const put = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Put');
    expect(put.input.Item.price).toBe(40);
    expect(json(r).session.pricing).toMatchObject({ price: 40, platformFee: 10, teacherShare: 30 });
  });

  test('a student cannot change the price of their session', async () => {
    mockSend.mockResolvedValueOnce({ Item: { sessionId: 's1', studentId: 'me', mentorId: 'm1', price: 40 } });
    const r = await sessions(ev('PUT', '/sessions/s1', { body: { price: 1 } }));
    expect(r.statusCode).toBe(403);
    expect(mockSend.mock.calls.some((c) => c[0]._type === 'Update')).toBe(false);
  });

  test('session list carries studentName and mentorName', async () => {
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Scan') return { Items: [{ sessionId: 's1', studentId: 'stu', mentorId: 'me', price: 20 }] };
      if (c._type === 'BatchGet' && c.input.RequestItems['torino-users']) return { Responses: { 'torino-users': [{ userId: 'stu', name: 'Sam' }, { userId: 'me', name: 'Mia' }] } };
      return { Responses: {} };
    });
    const r = await sessions(ev('GET', '/sessions', { role: 'mentor', qs: { role: 'mentor' } }));
    expect(json(r).sessions[0]).toMatchObject({ studentName: 'Sam', mentorName: 'Mia', pricing: { teacherShare: 15 } });
  });
});
