/**
 * payment.test.js — Jest tests for payments Lambda and stripe-webhook Lambda
 *
 * Run from aws-backend/:  npx jest tests/payment.test.js
 *
 * Mocks:
 *   - @aws-sdk/client-dynamodb  (DynamoDBClient)
 *   - @aws-sdk/lib-dynamodb     (DynamoDBDocumentClient + commands)
 *   - stripe
 */

'use strict';

// The webhook returns 503 "not configured" without these.
process.env.STRIPE_WEBHOOK_SECRET = 'whsec_test';
process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
process.env.COURSES_TABLE = 'torino-courses';
process.env.SESSIONS_TABLE = 'torino-sessions';

// ── Mock @aws-sdk ──────────────────────────────────────────────────────────────
const mockSend = jest.fn();

jest.mock('@aws-sdk/client-dynamodb', () => ({
  DynamoDBClient: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('@aws-sdk/lib-dynamodb', () => ({
  DynamoDBDocumentClient: {
    from: jest.fn().mockReturnValue({ send: mockSend }),
  },
  GetCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Get' })),
  PutCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Put' })),
  UpdateCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Update' })),
  QueryCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Query' })),
  DeleteCommand: jest.fn().mockImplementation((input) => ({ input, _type: 'Delete' })),
}));

// SSM is only reached when a secret is not in env; the tests set env, so it must never be called.
const mockSsmSend = jest.fn();
jest.mock('@aws-sdk/client-ssm', () => ({
  SSMClient: jest.fn().mockImplementation(() => ({ send: mockSsmSend })),
  GetParameterCommand: jest.fn().mockImplementation((input) => ({ input })),
}), { virtual: true });

// ── Mock stripe ────────────────────────────────────────────────────────────────
const mockConstructEvent = jest.fn();
const mockPaymentIntentsCreate = jest.fn();
const mockPaymentIntentsRetrieve = jest.fn();

jest.mock('stripe', () => {
  return jest.fn().mockReturnValue({
    paymentIntents: {
      create: mockPaymentIntentsCreate,
      retrieve: mockPaymentIntentsRetrieve,
    },
    webhooks: {
      constructEvent: mockConstructEvent,
    },
  });
});

// ── Helpers ────────────────────────────────────────────────────────────────────
function makeWebhookEvent(type, dataObject) {
  return {
    httpMethod: 'POST',
    headers: { 'stripe-signature': 'sig_test' },
    body: '{}',
    requestContext: {},
  };
}

function makeAuthEvent(body = {}) {
  return {
    httpMethod: 'POST',
    headers: {},
    body: JSON.stringify(body),
    requestContext: {
      authorizer: { claims: { sub: 'user-student-123' } },
    },
  };
}

// Reset mocks before each test
beforeEach(() => {
  jest.clearAllMocks();
  // Default: DynamoDB send succeeds
  mockSend.mockResolvedValue({});
});

// ── Load handlers after mocks are in place ─────────────────────────────────────
let paymentsHandler;
let webhookHandler;

beforeAll(() => {
  paymentsHandler = require('../lambda/payments/index').handler;
  webhookHandler  = require('../lambda/stripe-webhook/index').handler;
});

// ═══════════════════════════════════════════════════════════════════════════════
// WEBHOOK TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe('stripe-webhook: signature and configuration', () => {
  test('Bad Stripe-Signature → 400, nothing written', async () => {
    mockConstructEvent.mockImplementation(() => { throw new Error('No signatures found'); });
    const result = await webhookHandler({
      httpMethod: 'POST',
      headers: { 'Stripe-Signature': 't=0,v1=bad' },
      body: '{}',
    });
    expect(result.statusCode).toBe(400);
    expect(mockSend).not.toHaveBeenCalled();
  });

  test('Missing Stripe-Signature → 400', async () => {
    const result = await webhookHandler({ httpMethod: 'POST', headers: {}, body: '{}' });
    expect(result.statusCode).toBe(400);
    expect(mockConstructEvent).not.toHaveBeenCalled();
  });

  test('Mixed-case Stripe-Signature header is passed to constructEvent', async () => {
    mockConstructEvent.mockReturnValue({ id: 'evt_case', type: 'ping', data: { object: {} } });
    const result = await webhookHandler({
      httpMethod: 'POST',
      headers: { 'Stripe-Signature': 'sig_case' },
      body: '{"a":1}',
    });
    expect(result.statusCode).toBe(200);
    expect(mockConstructEvent).toHaveBeenCalledWith('{"a":1}', 'sig_case', 'whsec_test');
  });

  test('Empty STRIPE_WEBHOOK_SECRET → 503 "not configured"', async () => {
    const saved = process.env.STRIPE_WEBHOOK_SECRET;
    process.env.STRIPE_WEBHOOK_SECRET = '';
    try {
      const result = await webhookHandler(makeWebhookEvent());
      expect(result.statusCode).toBe(503);
      expect(JSON.parse(result.body).error).toMatch(/not configured/i);
      expect(mockConstructEvent).not.toHaveBeenCalled();
    } finally {
      process.env.STRIPE_WEBHOOK_SECRET = saved;
    }
  });
});

describe('stripe-webhook: payment_intent.succeeded — course purchase', () => {

  const pi = {
    id: 'pi_course_001',
    amount: 5000,
    currency: 'usd',
    metadata: {
      type: 'course_purchase',
      courseId: 'course-abc',
      studentId: 'student-123',
      teacherId: 'teacher-456',
    },
  };

  test('1. Successful course payment: student enrolled, teacher credited', async () => {
    mockConstructEvent.mockReturnValue({
      id: 'evt_001',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    // First mockSend call = markProcessed (PutCommand → returns true)
    // Second = enrollment PutCommand
    // Third = earnings PutCommand
    mockSend.mockResolvedValueOnce({})  // markProcessed: success (new event)
            .mockResolvedValueOnce({})  // enrollment write
            .mockResolvedValueOnce({}); // earnings write

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.received).toBe(true);
    expect(body.duplicate).toBeUndefined();

    // Verify enrollment was written with correct keys
    const enrollmentCall = mockSend.mock.calls[1][0];
    expect(enrollmentCall.input.Item.studentId).toBe('student-123');
    expect(enrollmentCall.input.Item.courseId).toBe('course-abc');
    expect(enrollmentCall.input.Item.status).toBe('active');

    // Verify earnings were written with deterministic earningId
    const earningsCall = mockSend.mock.calls[2][0];
    expect(earningsCall.input.Item.earningId).toBe('course_pi_course_001');
    expect(earningsCall.input.Item.userId).toBe('teacher-456');
    expect(earningsCall.input.Item.amount).toBeCloseTo(50 * 0.8);
  });

});

describe('stripe-webhook: payment_intent.succeeded — session booking', () => {

  const pi = {
    id: 'pi_session_001',
    amount: 3000,
    currency: 'usd',
    metadata: {
      type: 'session_booking',
      sessionId: 'session-xyz',
      mentorId: 'mentor-789',
      userId: 'student-123',
    },
  };

  test('2. Successful session payment: session confirmed, mentor credited', async () => {
    mockConstructEvent.mockReturnValue({
      id: 'evt_002',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    mockSend.mockResolvedValue({});

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);

    // Verify session update
    const sessionCall = mockSend.mock.calls[1][0];
    expect(sessionCall.input.Key.sessionId).toBe('session-xyz');
    expect(sessionCall.input.ExpressionAttributeValues[':s']).toBe('confirmed');

    // Verify mentor earnings
    const earningsCall = mockSend.mock.calls[2][0];
    expect(earningsCall.input.Item.earningId).toBe('session_pi_session_001');
    expect(earningsCall.input.Item.userId).toBe('mentor-789');
    expect(earningsCall.input.Item.status).toBe('pending');
  });

});

describe('stripe-webhook: payment_intent.payment_failed', () => {

  test('3. Failed payment: no enrollment, no earnings, session marked failed', async () => {
    const pi = {
      id: 'pi_fail_001',
      metadata: { type: 'session_booking', sessionId: 'session-xyz' },
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_003',
      type: 'payment_intent.payment_failed',
      data: { object: pi },
    });

    mockSend.mockResolvedValue({});

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);

    // Only markProcessed + session update — no enrollment or earnings
    expect(mockSend).toHaveBeenCalledTimes(2);
    const sessionCall = mockSend.mock.calls[1][0];
    expect(sessionCall.input.ExpressionAttributeValues[':s']).toBe('payment_failed');
  });

});

describe('stripe-webhook: idempotency', () => {

  test('4. Duplicate webhook delivery — no double enrollment or earnings', async () => {
    const pi = {
      id: 'pi_dup_001',
      amount: 5000,
      currency: 'usd',
      metadata: {
        type: 'course_purchase',
        courseId: 'course-abc',
        studentId: 'student-123',
        teacherId: 'teacher-456',
      },
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_dup_001',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    // Simulate: markProcessed throws ConditionalCheckFailedException (already processed)
    const dupErr = new Error('Already exists');
    dupErr.name = 'ConditionalCheckFailedException';
    mockSend.mockRejectedValueOnce(dupErr);

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.duplicate).toBe(true);

    // Only 1 DynamoDB call (the markProcessed that failed) — no enrollment or earnings
    expect(mockSend).toHaveBeenCalledTimes(1);
  });

  test('4b. Enrollment already exists — idempotent, no error', async () => {
    const pi = {
      id: 'pi_enroll_dup',
      amount: 5000,
      currency: 'usd',
      metadata: {
        type: 'course_purchase',
        courseId: 'course-abc',
        studentId: 'student-123',
        teacherId: 'teacher-456',
      },
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_enroll_dup',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    const dupErr = new Error('Enrollment exists');
    dupErr.name = 'ConditionalCheckFailedException';

    mockSend.mockResolvedValueOnce({})  // markProcessed: new event
            .mockRejectedValueOnce(dupErr)  // enrollment: already exists
            .mockResolvedValueOnce({}); // earnings: success

    const result = await webhookHandler(makeWebhookEvent());
    // Should succeed despite enrollment already existing
    expect(result.statusCode).toBe(200);
  });

});

describe('stripe-webhook: missing metadata', () => {

  test('5. Missing studentId in metadata — graceful skip, no crash', async () => {
    const pi = {
      id: 'pi_no_student',
      amount: 5000,
      currency: 'usd',
      metadata: {
        type: 'course_purchase',
        courseId: 'course-abc',
        teacherId: 'teacher-456',
        // studentId: missing
      },
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_no_student',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    mockSend.mockResolvedValue({});

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    // Only markProcessed — enrollment and earnings skipped due to missing studentId
    expect(mockSend).toHaveBeenCalledTimes(1);
  });

  test('6. Missing courseId in metadata — graceful skip, no crash', async () => {
    const pi = {
      id: 'pi_no_course',
      amount: 5000,
      currency: 'usd',
      metadata: {
        type: 'course_purchase',
        studentId: 'student-123',
        // courseId: missing
      },
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_no_course',
      type: 'payment_intent.succeeded',
      data: { object: pi },
    });

    mockSend.mockResolvedValue({});

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    expect(mockSend).toHaveBeenCalledTimes(1); // only markProcessed
  });

});

describe('stripe-webhook: charge.refunded', () => {

  test('8. Refund processing: enrollment marked refunded, earnings reversed', async () => {
    const charge = {
      id: 'ch_refund_001',
      amount_refunded: 5000,
      payment_intent: 'pi_course_001',
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_refund_001',
      type: 'charge.refunded',
      data: { object: charge },
    });

    // stripe.paymentIntents.retrieve returns the original PI metadata
    mockPaymentIntentsRetrieve.mockResolvedValue({
      id: 'pi_course_001',
      metadata: {
        type: 'course_purchase',
        courseId: 'course-abc',
        studentId: 'student-123',
        teacherId: 'teacher-456',
      },
    });

    mockSend.mockResolvedValue({});

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    expect(mockPaymentIntentsRetrieve).toHaveBeenCalledWith('pi_course_001');

    // Find enrollment update call
    const updateCalls = mockSend.mock.calls.filter(c => c[0]._type === 'Update');
    const enrollmentUpdate = updateCalls.find(c =>
      c[0].input && c[0].input.Key && c[0].input.Key.enrollmentId === 'enr_course-abc_student-123'
    );
    expect(enrollmentUpdate).toBeDefined();
    expect(enrollmentUpdate[0].input.ExpressionAttributeValues[':s']).toBe('refunded');

    // Find earnings reversal
    const earningsUpdate = updateCalls.find(c =>
      c[0].input && c[0].input.Key && c[0].input.Key.earningId === 'course_pi_course_001'
    );
    expect(earningsUpdate).toBeDefined();
  });

  test('9. Duplicate refund event — idempotent, no double reversal', async () => {
    const charge = {
      id: 'ch_refund_dup',
      amount_refunded: 5000,
      payment_intent: 'pi_course_001',
    };

    mockConstructEvent.mockReturnValue({
      id: 'evt_refund_dup',
      type: 'charge.refunded',
      data: { object: charge },
    });

    // markProcessed returns duplicate
    const dupErr = new Error('Already processed');
    dupErr.name = 'ConditionalCheckFailedException';
    mockSend.mockRejectedValueOnce(dupErr);

    const result = await webhookHandler(makeWebhookEvent());
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.duplicate).toBe(true);
    expect(mockSend).toHaveBeenCalledTimes(1);
  });

});

// ═══════════════════════════════════════════════════════════════════════════════
// PAYMENTS LAMBDA TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe('payments Lambda: authorization', () => {

  test('10. Missing API Gateway authorizer context → 401', async () => {
    const event = {
      httpMethod: 'POST',
      headers: {},
      body: JSON.stringify({ courseId: 'course-abc', type: 'course_purchase' }),
      requestContext: {}, // no authorizer
    };

    process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
    const result = await paymentsHandler(event);
    expect(result.statusCode).toBe(401);
    const body = JSON.parse(result.body);
    expect(body.error).toMatch(/Unauthorized/);
  });

  test('10b. No requestContext at all → 401', async () => {
    const event = {
      httpMethod: 'POST',
      headers: {},
      body: JSON.stringify({ courseId: 'course-abc', type: 'course_purchase' }),
      // requestContext: missing entirely
    };

    process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
    const result = await paymentsHandler(event);
    expect(result.statusCode).toBe(401);
  });

});

describe('payments Lambda: course purchase — server-authoritative price', () => {

  test('7. Course not found in DB → 404', async () => {
    // DynamoDB returns no item
    mockSend.mockResolvedValueOnce({ Item: undefined });

    process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
    const event = makeAuthEvent({ type: 'course_purchase', courseId: 'nonexistent' });
    const result = await paymentsHandler(event);

    expect(result.statusCode).toBe(404);
    const body = JSON.parse(result.body);
    expect(body.error).toMatch(/Course not found/);
  });

  test('Course found — creates PaymentIntent with server price, not client-supplied amount', async () => {
    // DB returns course with price $50
    mockSend.mockResolvedValueOnce({
      Item: { courseId: 'course-abc', title: 'Test Course', price: 50, teacherId: 'teacher-x' },
    });

    mockPaymentIntentsCreate.mockResolvedValueOnce({
      client_secret: 'cs_test_xyz',
      id: 'pi_new_001',
    });

    process.env.STRIPE_SECRET_KEY = 'sk_test_dummy';
    const event = makeAuthEvent({
      type: 'course_purchase',
      courseId: 'course-abc',
      // Client does NOT supply amount — server fetches from DB
    });

    const result = await paymentsHandler(event);
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body.clientSecret).toBe('cs_test_xyz');

    // Verify Stripe was called with amount from DB ($50 = 5000 cents)
    expect(mockPaymentIntentsCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 5000,
        metadata: expect.objectContaining({
          type: 'course_purchase',
          courseId: 'course-abc',
          studentId: 'user-student-123', // from Cognito claims
          teacherId: 'teacher-x',       // from DB record
        }),
      })
    );
  });

});
