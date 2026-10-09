/**
 * payments Lambda  (Cognito authorizer)
 *
 * All money is computed here, in cents, from server-side records; the app only
 * displays these numbers.
 *
 *   GET  /payments/quote?courseId=…                       course purchase
 *   GET  /payments/quote?sessionId=…                      booked session (caller = its student)
 *   GET  /payments/quote?mentorId=…&duration=<minutes>    before booking (mentor hourlyRate)
 *        → { currency, price, platformFeePercent, platformFee, teacherShare,
 *            walletBalance?, walletApplied, amountDue }
 *
 *   POST /payments/create-intent
 *     { type: 'course_purchase', courseId }   → Stripe PaymentIntent for the course price
 *     { type: 'session_booking', sessionId, useWallet? (default true) }
 *         wallet covers the whole price → paid from the wallet now (atomic: wallet debit,
 *         wallet event, session confirmed, mentor earning) → { paidWithWallet: true, … }
 *         otherwise → Stripe PaymentIntent for the full price (the wallet is not touched;
 *         there are no partial wallet+card splits)
 *   Anything else → 400. The app never sends an amount (subscriptions use /subscriptions).
 *
 * Fee model: one value, SSM String PLATFORM_FEE_PERCENT under SSM_PREFIX. The student pays
 * the price; platformFee = price × % and teacherShare = price − platformFee. Both are fixed
 * into the PaymentIntent metadata, so the webhook credits exactly what was quoted.
 * Missing/invalid fee → 503 "Platform fee not configured" (never guessed).
 * 503 "Stripe not configured" while STRIPE_SECRET_KEY is NOT_SET.
 *
 * Env: COURSES_TABLE, SESSIONS_TABLE, MENTORS_TABLE, WALLET_TABLE, WALLET_EVENTS_TABLE,
 *      EARNING_ENTRIES_TABLE, SSM_PREFIX (e.g. /torino/prod/)
 */
const Stripe = require('stripe');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, TransactWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

const REGION = process.env.AWS_REGION || 'us-east-1';
const COURSES_TABLE = process.env.COURSES_TABLE;
const SESSIONS_TABLE = process.env.SESSIONS_TABLE;
const MENTORS_TABLE = process.env.MENTORS_TABLE;
const WALLET_TABLE = process.env.WALLET_TABLE;
const WALLET_EVENTS_TABLE = process.env.WALLET_EVENTS_TABLE;
const EARNING_ENTRIES_TABLE = process.env.EARNING_ENTRIES_TABLE;

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const ssm = new SSMClient({ region: REGION });

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

function notConfigured(message) {
  const err = new Error(message);
  err.code = 'NOT_CONFIGURED';
  return err;
}

// ── SSM: secrets (SecureString) and the platform fee (String), cached 5 min ─────
const NOT_SET = 'NOT_SET';
const TTL_MS = 5 * 60 * 1000;
const cache = {};
async function getParam(name, { secure }) {
  const fromEnv = process.env[name];
  if (fromEnv && fromEnv !== NOT_SET) return fromEnv;
  const prefix = process.env.SSM_PREFIX;
  if (!prefix) return null;
  const hit = cache[name];
  if (hit && Date.now() - hit.at < TTL_MS) return hit.value;
  let value = null;
  try {
    const out = await ssm.send(new GetParameterCommand({ Name: `${prefix}${name}`, WithDecryption: secure }));
    const raw = out.Parameter?.Value;
    value = raw && raw !== NOT_SET ? raw : null;
  } catch (err) {
    if (err.name !== 'ParameterNotFound') throw err;
  }
  cache[name] = { value, at: Date.now() };
  return value;
}
const getSecret = (name) => getParam(name, { secure: true });

async function platformFeePercent() {
  const raw = await getParam('PLATFORM_FEE_PERCENT', { secure: false });
  const pct = Number(raw);
  if (raw === null || raw === '' || !Number.isFinite(pct) || pct < 0 || pct > 100) {
    throw notConfigured('Platform fee not configured');
  }
  return pct;
}

// Everything in integer cents; the teacher gets the remainder so the parts always add up.
function split(priceDollars, pct) {
  const priceCents = Math.round((Number(priceDollars) || 0) * 100);
  const platformFeeCents = Math.round((priceCents * pct) / 100);
  return { priceCents, platformFeeCents, teacherShareCents: priceCents - platformFeeCents };
}
const dollars = (cents) => Math.round(cents) / 100;

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

// ── Records ───────────────────────────────────────────────────────────────────
async function loadCourse(courseId) {
  if (!courseId) return null;
  const { Item } = await db.send(new GetCommand({ TableName: COURSES_TABLE, Key: { courseId } }));
  return Item && Item.status !== 'deleted' ? Item : null;
}
async function loadSession(sessionId) {
  if (!sessionId) return null;
  const { Item } = await db.send(new GetCommand({ TableName: SESSIONS_TABLE, Key: { sessionId } }));
  return Item || null;
}
async function walletBalanceCents(userId) {
  const { Item } = await db.send(new GetCommand({ TableName: WALLET_TABLE, Key: { userId } }));
  return Math.round((Number(Item?.balance) || 0) * 100);
}

function quoteBody({ currency = 'usd', priceCents, platformFeeCents, teacherShareCents }, pct, wallet) {
  const body = {
    currency,
    price: dollars(priceCents),
    platformFeePercent: pct,
    platformFee: dollars(platformFeeCents),
    teacherShare: dollars(teacherShareCents),
    walletApplied: 0,
    amountDue: dollars(priceCents),
  };
  if (wallet !== undefined) {
    body.walletBalance = dollars(wallet);
    // All or nothing: the wallet pays only if it covers the whole price.
    if (priceCents > 0 && wallet >= priceCents) {
      body.walletApplied = dollars(priceCents);
      body.amountDue = 0;
    }
  }
  return body;
}

// ── GET /payments/quote ───────────────────────────────────────────────────────
async function quote(userId, qs) {
  const pct = await platformFeePercent();
  if (qs.courseId) {
    const course = await loadCourse(qs.courseId);
    if (!course) return res(404, { error: 'Course not found' });
    return res(200, { courseId: course.courseId, ...quoteBody(split(course.price, pct), pct) });
  }
  if (qs.sessionId) {
    const session = await loadSession(qs.sessionId);
    if (!session) return res(404, { error: 'Session not found' });
    if (session.studentId !== userId) return res(403, { error: 'Only the booked student can get a quote for this session' });
    const s = split(session.price, pct);
    const body = quoteBody({ ...s, currency: (session.currency || 'usd').toLowerCase() }, pct, await walletBalanceCents(userId));
    return res(200, { sessionId: session.sessionId, paymentStatus: session.paymentStatus || 'unpaid', ...body });
  }
  if (qs.mentorId) {
    const minutes = Number(qs.duration || 60);
    if (!Number.isInteger(minutes) || minutes < 15 || minutes > 480) return res(400, { error: 'duration must be 15–480 minutes' });
    const { Item: mentor } = await db.send(new GetCommand({ TableName: MENTORS_TABLE, Key: { mentorId: qs.mentorId } }));
    if (!mentor || mentor.approved === false) return res(404, { error: 'Mentor not found' });
    const price = ((Number(mentor.hourlyRate) || 0) * minutes) / 60;
    return res(200, { mentorId: qs.mentorId, durationMinutes: minutes,
      ...quoteBody(split(price, pct), pct, await walletBalanceCents(userId)) });
  }
  return res(400, { error: 'courseId, sessionId or mentorId is required' });
}

// ── Course purchase: price + teacherId from the course record ──────────────────
async function handleCoursePurchase(stripe, studentId, { courseId, description }) {
  if (!courseId) return res(400, { error: 'courseId is required for course_purchase' });
  const course = await loadCourse(courseId);
  if (!course) return res(404, { error: 'Course not found' });

  const pct = await platformFeePercent();
  const s = split(course.price, pct);
  if (s.priceCents < 50) return res(400, { error: 'Course price is too low for payment processing (minimum $0.50)' });

  return createIntent(stripe, {
    amount: s.priceCents,
    currency: 'usd',
    description: description || `Course: ${course.title || courseId}`,
    metadata: {
      type: 'course_purchase',
      courseId,
      studentId,
      teacherId: course.teacherId || '',
      amount: String(dollars(s.priceCents)),
      platformFeePercent: String(pct),
      platformFeeCents: String(s.platformFeeCents),
      teacherShareCents: String(s.teacherShareCents),
    },
  }, { courseId, studentId });
}

// ── Session booking: price + mentorId from the session record ──────────────────
async function handleSessionBooking(getStripeFn, studentId, { sessionId, description, useWallet = true }) {
  if (!sessionId) return res(400, { error: 'sessionId is required for session_booking' });
  const session = await loadSession(sessionId);
  if (!session) return res(404, { error: 'Session not found' });
  if (session.studentId !== studentId) return res(403, { error: 'Only the booked student can pay for this session' });
  if (session.paymentStatus === 'paid') return res(409, { error: 'This session is already paid' });

  const pct = await platformFeePercent();
  const s = split(session.price, pct);
  if (s.priceCents <= 0) return res(400, { error: 'This session has no price to pay' });

  if (useWallet !== false && await walletBalanceCents(studentId) >= s.priceCents) {
    return payFromWallet(studentId, session, s, pct);
  }

  const stripe = await getStripeFn();
  if (!stripe) return res(503, { error: 'Stripe not configured' });
  if (s.priceCents < 50) return res(400, { error: 'Session price is too low for card payment (minimum $0.50)' });
  return createIntent(stripe, {
    amount: s.priceCents,
    currency: (session.currency || 'usd').toLowerCase(),
    description: description || `Session: ${session.title || session.topic || sessionId}`,
    metadata: {
      type: 'session_booking',
      sessionId,
      studentId,
      mentorId: session.mentorId || '',
      platformFeePercent: String(pct),
      platformFeeCents: String(s.platformFeeCents),
      teacherShareCents: String(s.teacherShareCents),
    },
  }, { sessionId, studentId });
}

// One transaction: if any part fails (balance too low, already paid, …) nothing changes.
async function payFromWallet(studentId, session, s, pct) {
  const now = new Date().toISOString();
  const eventId = `session_${session.sessionId}`;
  const amount = dollars(s.priceCents);
  try {
    await db.send(new TransactWriteCommand({
      TransactItems: [
        { Update: {
          TableName: WALLET_TABLE,
          Key: { userId: studentId },
          UpdateExpression: 'SET balance = balance - :a, updatedAt = :now',
          ConditionExpression: 'balance >= :a',
          ExpressionAttributeValues: { ':a': amount, ':now': now },
        } },
        { Put: {
          TableName: WALLET_EVENTS_TABLE,
          Item: { userId: studentId, eventId, amount, description: `Session ${session.sessionId}`, type: 'session_payment', createdAt: now },
          ConditionExpression: 'attribute_not_exists(eventId)',
        } },
        { Update: {
          TableName: SESSIONS_TABLE,
          Key: { sessionId: session.sessionId },
          UpdateExpression: 'SET #s = :confirmed, paymentStatus = :paid, paymentMethod = :wallet, paidAt = :now, updatedAt = :now',
          ConditionExpression: 'studentId = :student AND (attribute_not_exists(paymentStatus) OR paymentStatus <> :paid)',
          ExpressionAttributeNames: { '#s': 'status' },
          ExpressionAttributeValues: { ':confirmed': 'confirmed', ':paid': 'paid', ':wallet': 'wallet', ':now': now, ':student': studentId },
        } },
        { Put: {
          TableName: EARNING_ENTRIES_TABLE,
          Item: {
            earningId: `session_wallet_${session.sessionId}`,
            userId: session.mentorId,
            type: 'session',
            amount: dollars(s.teacherShareCents),
            platformFee: dollars(s.platformFeeCents),
            platformFeePercent: pct,
            currency: (session.currency || 'usd').toLowerCase(),
            referenceId: session.sessionId,
            paymentMethod: 'wallet',
            status: 'pending', // held until the session completes, like card payments
            createdAt: now,
          },
          ConditionExpression: 'attribute_not_exists(earningId)',
        } },
      ],
    }));
  } catch (err) {
    if (err.name === 'TransactionCanceledException') {
      return res(409, { error: 'Wallet payment could not be completed (balance changed or session already paid)' });
    }
    throw err;
  }
  log('INFO', 'Session paid from wallet', { sessionId: session.sessionId, studentId, amountCents: s.priceCents });
  return res(200, {
    paidWithWallet: true,
    sessionId: session.sessionId,
    amountCharged: amount,
    platformFee: dollars(s.platformFeeCents),
    teacherShare: dollars(s.teacherShareCents),
    walletBalance: dollars(await walletBalanceCents(studentId)),
  });
}

async function createIntent(stripe, params, logCtx) {
  try {
    const intent = await stripe.paymentIntents.create({ ...params, automatic_payment_methods: { enabled: true } });
    log('INFO', 'Payment intent created', { paymentIntentId: intent.id, amount: params.amount, ...logCtx });
    return res(200, { clientSecret: intent.client_secret, paymentIntentId: intent.id, amountDue: dollars(params.amount) });
  } catch (err) {
    log('ERROR', 'Stripe payment intent error', { error: err.message, ...logCtx });
    return res(502, { error: `Payment provider error: ${err.message}` });
  }
}

// ── Entry point ──────────────────────────────────────────────────────────────
exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});

  // The caller's identity comes only from the API Gateway Cognito authorizer.
  const claims = event.requestContext?.authorizer?.claims;
  if (!claims || !claims.sub) {
    log('WARN', 'Missing authorizer context — request rejected', {});
    return res(401, { error: 'Unauthorized: missing authorizer context' });
  }
  const userId = claims.sub;

  try {
    if (event.httpMethod === 'GET' && event.path === '/payments/quote') {
      return await quote(userId, event.queryStringParameters || {});
    }
    if (event.httpMethod !== 'POST') return res(405, { error: 'Method not allowed' });

    let body;
    try { body = JSON.parse(event.body || '{}'); } catch {
      return res(400, { error: 'Invalid request body' });
    }

    // Older app builds put type/sessionId inside `metadata`; only those two keys are read from it.
    const meta = body.metadata && typeof body.metadata === 'object' ? body.metadata : {};
    const type = body.type || meta.type;

    // A session can be paid entirely from the wallet, without Stripe.
    if (type === 'session_booking') {
      return await handleSessionBooking(getStripe, userId, { ...body, sessionId: body.sessionId || meta.sessionId });
    }

    const stripe = await getStripe();
    if (!stripe) {
      log('ERROR', 'STRIPE_SECRET_KEY is NOT_SET');
      return res(503, { error: 'Stripe not configured' });
    }
    if (type === 'course_purchase') {
      return await handleCoursePurchase(stripe, userId, { ...body, courseId: body.courseId || meta.courseId });
    }

    return res(400, { error: "type must be 'course_purchase' or 'session_booking'" });
  } catch (err) {
    if (err.code === 'NOT_CONFIGURED') return res(503, { error: err.message });
    log('ERROR', 'Payments handler error', { error: err.message });
    return res(500, { error: 'Payment request failed' });
  }
};
