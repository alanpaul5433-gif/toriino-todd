/**
 * payments Lambda — POST /payments/create-intent  (Cognito authorizer)
 *
 * Creates a Stripe PaymentIntent and returns the client secret to the app
 * (flutter_stripe PaymentSheet completes the payment; the stripe-webhook Lambda
 * acts on the result). Everything the webhook trusts is set here, server-side:
 *
 *   { type: 'course_purchase', courseId }
 *       amount and teacherId come from the course record.
 *   { type: 'session_booking', sessionId }
 *       amount and mentorId come from the session record; the caller must be its student.
 *   { amount, currency?, description? }        (anything else, e.g. wallet top-up)
 *       amount in cents (>= 50); client metadata is NOT forwarded.
 *
 * Response: { clientSecret, paymentIntentId }
 * 503 "Stripe not configured" while the SSM parameter STRIPE_SECRET_KEY is NOT_SET.
 *
 * Env: COURSES_TABLE, SESSIONS_TABLE, SSM_PREFIX (e.g. /torino/prod/)
 */
const Stripe = require('stripe');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

const REGION = process.env.AWS_REGION || 'us-east-1';
const COURSES_TABLE = process.env.COURSES_TABLE;
const SESSIONS_TABLE = process.env.SESSIONS_TABLE;

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const ssm = new SSMClient({ region: REGION });

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'POST,OPTIONS',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

// ── Secrets: env (tests/local) first, else SSM SecureString, cached 5 min ──────
const NOT_SET = 'NOT_SET';
const SECRET_TTL_MS = 5 * 60 * 1000;
const secretCache = {};
async function getSecret(name) {
  const fromEnv = process.env[name];
  if (fromEnv && fromEnv !== NOT_SET) return fromEnv;
  const prefix = process.env.SSM_PREFIX;
  if (!prefix) return null;
  const hit = secretCache[name];
  if (hit && Date.now() - hit.at < SECRET_TTL_MS) return hit.value;
  const out = await ssm.send(new GetParameterCommand({ Name: `${prefix}${name}`, WithDecryption: true }));
  const raw = out.Parameter?.Value;
  const value = raw && raw !== NOT_SET ? raw : null;
  secretCache[name] = { value, at: Date.now() };
  return value;
}

let stripeClient;
let stripeKey;
async function getStripe() {
  const key = await getSecret('STRIPE_SECRET_KEY');
  if (!key) return null;
  if (!stripeClient || key !== stripeKey) {
    stripeClient = Stripe(key);
    stripeKey = key;
  }
  return stripeClient;
}

// ── Course purchase: price + teacherId from the course record ──────────────────
async function handleCoursePurchase(stripe, studentId, { courseId, description }) {
  if (!courseId) return res(400, { error: 'courseId is required for course_purchase' });
  if (!COURSES_TABLE) return res(503, { error: 'Payments not configured (COURSES_TABLE)' });

  const { Item: course } = await db.send(new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } }));
  if (!course || course.status === 'deleted') return res(404, { error: 'Course not found' });

  const priceInDollars = Number(course.price) || 0;
  const amountInCents = Math.round(priceInDollars * 100);
  if (amountInCents < 50) {
    return res(400, { error: 'Course price is too low for payment processing (minimum $0.50)' });
  }

  return createIntent(stripe, {
    amount: amountInCents,
    currency: 'usd',
    description: description || `Course: ${course.title || courseId}`,
    metadata: {
      type: 'course_purchase',
      courseId,
      studentId,
      teacherId: course.teacherId || '',
      amount: String(priceInDollars),
    },
  }, { courseId, studentId });
}

// ── Session booking: price + mentorId from the session record ──────────────────
async function handleSessionBooking(stripe, studentId, { sessionId, description }) {
  if (!sessionId) return res(400, { error: 'sessionId is required for session_booking' });
  if (!SESSIONS_TABLE) return res(503, { error: 'Payments not configured (SESSIONS_TABLE)' });

  const { Item: session } = await db.send(new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } }));
  if (!session) return res(404, { error: 'Session not found' });
  if (session.studentId !== studentId) return res(403, { error: 'Only the booked student can pay for this session' });

  const amountInCents = Math.round((Number(session.price) || 0) * 100);
  if (amountInCents < 50) return res(400, { error: 'Session price is too low for payment processing (minimum $0.50)' });

  return createIntent(stripe, {
    amount: amountInCents,
    currency: (session.currency || 'usd').toLowerCase(),
    description: description || `Session: ${session.title || session.topic || sessionId}`,
    metadata: { type: 'session_booking', sessionId, studentId, mentorId: session.mentorId || '' },
  }, { sessionId, studentId });
}

async function createIntent(stripe, params, logCtx) {
  try {
    const intent = await stripe.paymentIntents.create({ ...params, automatic_payment_methods: { enabled: true } });
    log('INFO', 'Payment intent created', { paymentIntentId: intent.id, amount: params.amount, ...logCtx });
    return res(200, { clientSecret: intent.client_secret, paymentIntentId: intent.id });
  } catch (err) {
    log('ERROR', 'Stripe payment intent error', { error: err.message, ...logCtx });
    return res(502, { error: `Payment provider error: ${err.message}` });
  }
}

// ── Entry point ──────────────────────────────────────────────────────────────
exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});
  if (event.httpMethod !== 'POST') return res(405, { error: 'Method not allowed' });

  // The caller's identity comes only from the API Gateway Cognito authorizer.
  const claims = event.requestContext?.authorizer?.claims;
  if (!claims || !claims.sub) {
    log('WARN', 'Missing authorizer context — request rejected', {});
    return res(401, { error: 'Unauthorized: missing authorizer context' });
  }
  const userId = claims.sub;

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch {
    return res(400, { error: 'Invalid request body' });
  }

  let stripe;
  try {
    stripe = await getStripe();
  } catch (err) {
    log('ERROR', 'Could not read Stripe secret', { error: err.message });
    return res(500, { error: 'Payment service could not load its configuration' });
  }
  if (!stripe) {
    log('ERROR', 'STRIPE_SECRET_KEY is NOT_SET');
    return res(503, { error: 'Stripe not configured' });
  }

  try {
    // Older app builds put type/sessionId inside `metadata`; only those two keys are read from it.
    const meta = body.metadata && typeof body.metadata === 'object' ? body.metadata : {};
    const type = body.type || meta.type;
    if (type === 'course_purchase') {
      return await handleCoursePurchase(stripe, userId, { ...body, courseId: body.courseId || meta.courseId });
    }
    if (type === 'session_booking') {
      return await handleSessionBooking(stripe, userId, { ...body, sessionId: body.sessionId || meta.sessionId });
    }

    const { amount, currency = 'usd', description = '' } = body;
    if (!amount || typeof amount !== 'number' || amount < 50) {
      return res(400, { error: 'amount must be a number >= 50 (cents)' });
    }
    return await createIntent(stripe, {
      amount: Math.round(amount),
      currency: String(currency).toLowerCase(),
      description: String(description).slice(0, 500),
      metadata: { type: 'generic', userId },
    }, { userId });
  } catch (err) {
    log('ERROR', 'Payments handler error', { error: err.message });
    return res(500, { error: 'Payment request failed' });
  }
};
