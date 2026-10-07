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

Object.assign(process.env, {
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
