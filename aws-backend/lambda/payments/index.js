/**
 * payments Lambda — POST /payments/create-intent
 *
 * Creates a Stripe PaymentIntent and returns the client secret to the app.
 * The app then uses flutter_stripe's PaymentSheet to complete the payment.
 *
 * Request body (session_booking / generic):
 *   { amount, currency, description, metadata? }
 *   amount — integer in smallest currency unit (cents for USD)
 *
 * Request body (course_purchase — server-authoritative):
 *   { type: 'course_purchase', courseId, description? }
 *   amount and teacherId are fetched server-side from DynamoDB; not trusted from client.
 *
 * Response:
 *   { clientSecret, paymentIntentId }
 *
 * Env vars (owner must set):
 *   STRIPE_SECRET_KEY — sk_test_... (test) or sk_live_... (live, never commit)
 *   COURSES_TABLE     — toriino-courses  (required for course_purchase route)
 */

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const Stripe = require('stripe');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

const stripe = Stripe(process.env.STRIPE_SECRET_KEY || '');

const REGION       = process.env.AWS_REGION    || 'us-east-2';
const COURSES_TABLE = process.env.COURSES_TABLE || 'toriino-courses';

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'POST,OPTIONS',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

// ── Course-purchase route ───────────────────────────────────────────────────
// Server fetches price + teacherId from DynamoDB — client cannot supply these.
async function handleCoursePurchase(studentId, body) {
  const { courseId, description } = body;
  if (!courseId) return res(400, { error: 'courseId is required for course_purchase' });

  const courseResult = await db.send(new GetCommand({
    TableName: COURSES_TABLE,
    Key: { courseId },
  }));

  if (!courseResult.Item) return res(404, { error: 'Course not found' });

  const course = courseResult.Item;
  const priceInDollars = Number(course.price) || 0;
  const amountInCents  = Math.round(priceInDollars * 100);

  if (amountInCents < 50) {
    return res(400, { error: 'Course price is too low for payment processing (minimum $0.50)' });
  }

  const teacherId = course.teacherId || '';

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'usd',
      description: description || `Course: ${course.title || courseId}`,
      metadata: {
        type: 'course_purchase',
        courseId,
        studentId,          // from Cognito — server-authoritative
        teacherId,          // from course record — server-authoritative
        amount: String(priceInDollars),
      },
      automatic_payment_methods: { enabled: true },
    });

    log('INFO', 'Course purchase intent created', {
      paymentIntentId: paymentIntent.id,
      courseId,
      studentId,
      teacherId,
      amountInCents,
    });

    return res(200, {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    log('ERROR', 'Stripe course purchase error', { error: err.message, courseId, studentId });
    return res(400, { error: err.message });
  }
}

// ── Lambda entry point ──────────────────────────────────────────────────────
exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});
  if (event.httpMethod !== 'POST') return res(405, { error: 'Method not allowed' });

  // Security: studentId / userId must come from Cognito authorizer context only.
  // Manually decoded JWTs are untrusted — reject if authorizer context is absent.
  const claims = event.requestContext?.authorizer?.claims;
  if (!claims || !claims.sub) {
    log('WARN', 'Missing authorizer context — request rejected', {});
    return res(401, { error: 'Unauthorized: missing authorizer context' });
  }
  const userId = claims.sub;

  if (!process.env.STRIPE_SECRET_KEY) {
    log('ERROR', 'STRIPE_SECRET_KEY env var is not set');
    return res(500, { error: 'Payment service not configured' });
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return res(400, { error: 'Invalid request body' });
  }

  // Course purchase uses a dedicated server-authoritative path
  if (body.type === 'course_purchase') {
    return await handleCoursePurchase(userId, body);
  }

  // Generic / session-booking path (client-supplied amount, metadata)
  const { amount, currency = 'usd', description = '', metadata = {} } = body;

  if (!amount || typeof amount !== 'number' || amount < 50) {
    return res(400, { error: 'amount must be a number >= 50 (cents)' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency,
      description,
      metadata: { userId, ...metadata },
      automatic_payment_methods: { enabled: true },
    });

    log('INFO', 'Payment intent created', { paymentIntentId: paymentIntent.id, amount, currency, userId });
    return res(200, {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    log('ERROR', 'Stripe payment intent error', { error: err.message, userId });
    return res(400, { error: err.message });
  }
};
