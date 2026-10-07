/**
 * subscriptions.test.js — plans, checkout, webhook-only activation and the premium gate.
 * Run from aws-backend/:  npx jest tests/subscriptions.test.js
 */
'use strict';

const mockSend = jest.fn();
const mockSsm = jest.fn();
const mockStripe = {
  customers: { create: jest.fn() },
  subscriptions: { create: jest.fn(), retrieve: jest.fn(), update: jest.fn() },
  webhooks: { constructEvent: jest.fn() },
};

jest.mock('@aws-sdk/client-dynamodb', () => ({ DynamoDBClient: jest.fn().mockImplementation(() => ({})) }));
jest.mock('@aws-sdk/lib-dynamodb', () => {
  const cmd = (type) => jest.fn().mockImplementation((input) => ({ input, _type: type }));
  return {
    DynamoDBDocumentClient: { from: jest.fn().mockReturnValue({ send: mockSend }) },
    GetCommand: cmd('Get'), PutCommand: cmd('Put'), UpdateCommand: cmd('Update'),
    DeleteCommand: cmd('Delete'), QueryCommand: cmd('Query'), ScanCommand: cmd('Scan'),
  };
});
jest.mock('@aws-sdk/client-ssm', () => ({
  SSMClient: jest.fn().mockImplementation(() => ({ send: mockSsm })),
  GetParameterCommand: jest.fn().mockImplementation((input) => ({ input })),
}), { virtual: true });
jest.mock('stripe', () => jest.fn().mockReturnValue(mockStripe));

Object.assign(process.env, {
  SSM_PREFIX: '/torino/prod/',
  SUBSCRIPTIONS_TABLE: 'toriino-subscriptions',
  USERS_TABLE: 'torino-users',
  STRIPE_SECRET_KEY: 'sk_test_dummy',
  STRIPE_WEBHOOK_SECRET: 'whsec_test',
});

const PLAN = (audience, id, months, price, extra = {}) => ({
  planId: `${audience}-${id}`, name: id, audience, months, price, currency: 'usd',
  stripePriceId: `price_${audience}_${id}`, active: true, ...extra,
});
let plans = [];
let premiumFeatures = '[]';
mockSsm.mockImplementation(async (c) => {
  const n = c.input.Name;
  if (n.endsWith('SUBSCRIPTION_PLANS')) return { Parameter: { Value: JSON.stringify(plans) } };
  if (n.endsWith('PREMIUM_FEATURES')) return { Parameter: { Value: premiumFeatures } };
  if (n.endsWith('GEMINI_API_KEY')) return { Parameter: { Value: 'NOT_SET' } };
  throw Object.assign(new Error('nf'), { name: 'ParameterNotFound' });
});

// The Lambda caches SSM config for 5 minutes, so each test loads a fresh copy.
const subs = (...a) => { jest.resetModules(); return require('../lambda/subscriptions/index').handler(...a); };
const webhook = require('../lambda/stripe-webhook/index').handler;
const chat = require('../lambda/ai-chat/index').handler;

const ev = (method, path, { sub = 'u1', role = 'teacher', body, qs } = {}) => ({
  httpMethod: method, path, body: body ? JSON.stringify(body) : null, queryStringParameters: qs || null,
  requestContext: { authorizer: { claims: { sub, 'custom:role': role, email: 'u1@example.com' } } },
});
const json = (r) => JSON.parse(r.body);

beforeEach(() => {
  mockSend.mockReset(); mockSend.mockResolvedValue({});
  Object.values(mockStripe).forEach((g) => Object.values(g).forEach((f) => f.mockReset()));
});

describe('GET /subscriptions/plans', () => {
  test('only active plans with a real price ID, for the caller’s role, sorted', async () => {
    plans = [
      PLAN('teacher', 'yearly', 12, 99.99),
      PLAN('teacher', 'monthly', 1, 9.99),
      PLAN('teacher', 'quarterly', 3, 49.99, { stripePriceId: 'NOT_SET' }), // no price ID → hidden
      PLAN('teacher', 'weekly', 1, 3, { active: false }),                 // inactive → hidden
      PLAN('student', 'monthly', 1, 5),                                    // other audience → hidden
    ];
    const r = await subs(ev('GET', '/subscriptions/plans'));
    const b = json(r);
    expect(b.audience).toBe('teacher');
    expect(b.plans.map((p) => p.planId)).toEqual(['teacher-monthly', 'teacher-yearly']);
    expect(b.plans[0]).not.toHaveProperty('stripePriceId');
    expect(b.comingSoon).toBe(false);
  });

  test('savings are computed from real prices, and omitted when there is no saving', async () => {
    plans = [PLAN('mentor', 'monthly', 1, 9.99), PLAN('mentor', 'quarterly', 3, 49.99), PLAN('mentor', 'yearly', 12, 99.99)];
    const b = json(await subs(ev('GET', '/subscriptions/plans', { role: 'mentor' })));
    const q = b.plans.find((p) => p.planId === 'mentor-quarterly');
    const y = b.plans.find((p) => p.planId === 'mentor-yearly');
    expect(q).not.toHaveProperty('savings'); // 49.99 > 3 × 9.99
    expect(y.savings).toEqual({ amount: 19.89, percent: 17, comparedTo: 'mentor-monthly' }); // 119.88 − 99.99
  });

  test('nothing offered for the role → comingSoon', async () => {
    plans = [PLAN('teacher', 'monthly', 1, 9.99, { active: false })];
    const b = json(await subs(ev('GET', '/subscriptions/plans', { role: 'student' })));
    expect(b).toEqual({ audience: 'student', plans: [], comingSoon: true });
  });
});

describe('POST /subscriptions (checkout)', () => {
  test('creates an incomplete subscription and NEVER marks premium', async () => {
    plans = [PLAN('teacher', 'monthly', 1, 9.99)];
    mockSend.mockImplementation(async (c) => (c._type === 'Get' && c.input.TableName === 'torino-users'
      ? { Item: { userId: 'u1', stripeCustomerId: 'cus_1' } } : {}));
    mockStripe.subscriptions.create.mockResolvedValue({ id: 'sub_1', latest_invoice: { payment_intent: { client_secret: 'pi_secret' } } });
    const r = await subs(ev('POST', '/subscriptions', { body: { planId: 'teacher-monthly', price: 0.01 } }));
    expect(r.statusCode).toBe(200);
    expect(json(r)).toMatchObject({ subscriptionId: 'sub_1', clientSecret: 'pi_secret', status: 'incomplete' });
    const created = mockStripe.subscriptions.create.mock.calls[0][0];
    expect(created.items).toEqual([{ price: 'price_teacher_monthly' }]); // server price ID, client amount ignored
    expect(created.metadata).toEqual({ userId: 'u1', planId: 'teacher-monthly', audience: 'teacher' });
    const put = mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Put');
    expect(put.input.Item).toMatchObject({ status: 'incomplete', premium: false });
  });

  test('a plan for another role → 403; an unknown/inactive plan → 404', async () => {
    plans = [PLAN('mentor', 'monthly', 1, 9.99), PLAN('teacher', 'yearly', 12, 99, { active: false })];
    expect((await subs(ev('POST', '/subscriptions', { body: { planId: 'mentor-monthly' } }))).statusCode).toBe(403);
    expect((await subs(ev('POST', '/subscriptions', { body: { planId: 'teacher-yearly' } }))).statusCode).toBe(404);
    expect(mockStripe.subscriptions.create).not.toHaveBeenCalled();
  });
});

describe('stripe-webhook: subscription activation is webhook-only', () => {
  const stripeSub = (over = {}) => ({
    id: 'sub_1', customer: 'cus_1', status: 'active', cancel_at_period_end: false,
    current_period_end: 1893456000, metadata: { userId: 'u1', planId: 'teacher-monthly', audience: 'teacher' }, ...over,
  });
  const deliver = (type, object, created = 1800000000) => {
    mockStripe.webhooks.constructEvent.mockReturnValue({ id: `evt_${type}_${created}`, type, created, data: { object } });
    return webhook({ httpMethod: 'POST', headers: { 'Stripe-Signature': 'sig' }, body: '{}' });
  };
  const subUpdate = () => mockSend.mock.calls.map((c) => c[0]).find((c) => c._type === 'Update' && c.input.TableName === 'toriino-subscriptions');

  test('invoice.paid → re-reads the subscription from Stripe and activates premium', async () => {
    mockStripe.subscriptions.retrieve.mockResolvedValue(stripeSub());
    const r = await deliver('invoice.paid', { id: 'in_1', subscription: 'sub_1' });
    expect(r.statusCode).toBe(200);
    expect(mockStripe.subscriptions.retrieve).toHaveBeenCalledWith('sub_1');
    const u = subUpdate();
    expect(u.input.Key).toEqual({ userId: 'u1' });
    expect(u.input.ExpressionAttributeValues).toMatchObject({ ':st': 'active', ':pr': true, ':pe': '2030-01-01T00:00:00.000Z' });
  });

  test('customer.subscription.deleted → premium false, status canceled', async () => {
    await deliver('customer.subscription.deleted', stripeSub({ status: 'canceled' }));
    expect(subUpdate().input.ExpressionAttributeValues).toMatchObject({ ':st': 'canceled', ':pr': false });
  });

  test('invoice.payment_failed → deactivated even though Stripe still says active', async () => {
    mockStripe.subscriptions.retrieve.mockResolvedValue(stripeSub({ status: 'active' }));
    await deliver('invoice.payment_failed', { id: 'in_2', subscription: 'sub_1' });
    expect(subUpdate().input.ExpressionAttributeValues).toMatchObject({ ':st': 'past_due', ':pr': false });
  });

  test('out-of-order events are rejected by the lastEventAt condition; a stale one is ignored, not an error', async () => {
    mockStripe.subscriptions.retrieve.mockResolvedValue(stripeSub());
    mockSend.mockImplementation(async (c) => {
      if (c._type === 'Update' && c.input.TableName === 'toriino-subscriptions') {
        throw Object.assign(new Error('stale'), { name: 'ConditionalCheckFailedException' });
      }
      return {};
    });
    const r = await deliver('invoice.paid', { id: 'in_3', subscription: 'sub_1' }, 1700000000);
    expect(r.statusCode).toBe(200);
    expect(subUpdate().input.ConditionExpression).toContain('lastEventAt <= :t');
  });

  test('a deactivation for a different subscription cannot switch off the live plan', async () => {
    await deliver('customer.subscription.updated', stripeSub({ id: 'sub_old', status: 'incomplete_expired' }));
    const u = subUpdate();
    expect(u.input.ConditionExpression).toContain('stripeSubscriptionId = :sid OR premium = :false');
    expect(u.input.ExpressionAttributeValues[':sid']).toBe('sub_old');
  });
});

describe('premium gate (PREMIUM_FEATURES)', () => {
  test('feature not listed → no subscription check at all', async () => {
    premiumFeatures = '[]';
    const r = await chat(ev('POST', '/ai/chat/u1', { role: 'student', body: { message: 'hi' } }));
    expect(r.statusCode).toBe(503); // reaches the Gemini step ("not configured"), not the gate
    expect(mockSend.mock.calls.some((c) => c[0].input?.TableName === 'toriino-subscriptions')).toBe(false);
  });

  test('feature listed + no active subscription → 402 premium required', async () => {
    premiumFeatures = '["ai_chat"]';
    jest.resetModules(); // drop the 5-minute cache
    const freshChat = require('../lambda/ai-chat/index').handler;
    mockSend.mockResolvedValue({ Item: { userId: 'u1', premium: true, status: 'past_due' } });
    const r = await freshChat(ev('POST', '/ai/chat/u1', { role: 'student', body: { message: 'hi' } }));
    expect(r.statusCode).toBe(402);
    expect(json(r)).toEqual({ error: 'premium required', feature: 'ai_chat' });
  });

  test('feature listed + active, unexpired subscription → passes the gate', async () => {
    premiumFeatures = '["ai_chat"]';
    jest.resetModules();
    const freshChat = require('../lambda/ai-chat/index').handler;
    mockSend.mockResolvedValue({ Item: { userId: 'u1', premium: true, status: 'active', currentPeriodEnd: '2099-01-01T00:00:00Z' } });
    const r = await freshChat(ev('POST', '/ai/chat/u1', { role: 'student', body: { message: 'hi' } }));
    expect(r.statusCode).toBe(503); // past the gate, stopped by "Gemini not configured"
  });
});
