/**
 * stripe-webhook Lambda — POST /prod/stripe/webhook (no Cognito authorizer; Stripe
 * cannot send a Cognito token, so requests are authenticated by Stripe-Signature).
 *
 * Responses: 400 for a missing/bad Stripe-Signature, 503 "not configured" while
 * STRIPE_WEBHOOK_SECRET or STRIPE_SECRET_KEY is NOT_SET (SSM) or empty.
 *
 * Handles:
 *   payment_intent.succeeded          → enroll student or confirm session, credit earnings
 *   payment_intent.payment_failed     → mark payment failed on relevant order
 *   charge.refunded                   → reverse earnings, mark enrollment/session refunded
 *   customer.subscription.created/updated, invoice.paid
 *                                     → (re)activate or update the plan (SUBSCRIPTIONS_TABLE)
 *   customer.subscription.deleted, invoice.payment_failed
 *                                     → deactivate the plan
 *
 * Idempotency:
 *   - Event-level: every event.id is stored in toriino-stripe-events before processing.
 *     Replaying the same event.id is a no-op.
 *   - Enrollment: uses studentId+courseId composite key with ConditionExpression.
 *   - Earnings: uses deterministic earningId = '<type>_<paymentIntentId>' so that
 *     duplicate writes and refund reversals are both safe.
 *
 * Secrets (SSM SecureString under SSM_PREFIX, placeholder NOT_SET; the owner sets them):
 *   STRIPE_WEBHOOK_SECRET   — whsec_... from the Stripe dashboard
 *   STRIPE_SECRET_KEY       — sk_live_... or sk_test_...
 * Env (set by template.yaml):
 *   SSM_PREFIX              — /torino/prod/
 *   EARNING_ENTRIES_TABLE   — toriino-earning-entries (PK earningId; GSI userId-index)
 *   ENROLLMENTS_TABLE       — toriino-enrollments (PK enrollmentId = enr_<courseId>_<studentId>)
 *   SESSIONS_TABLE          — torino-sessions
 *   USERS_TABLE             — torino-users
 *   STRIPE_EVENTS_TABLE     — toriino-stripe-events  (PK = eventId, TTL = ttl)
 */

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const Stripe = require('stripe');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  DynamoDBDocumentClient,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
} = require('@aws-sdk/lib-dynamodb');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

const REGION              = process.env.AWS_REGION            || 'us-east-1';
const STRIPE_EVENTS_TABLE = process.env.STRIPE_EVENTS_TABLE   || 'toriino-stripe-events';
const EARNINGS_TABLE      = process.env.EARNING_ENTRIES_TABLE || 'toriino-earning-entries';
const ENROLLMENTS_TABLE   = process.env.ENROLLMENTS_TABLE     || 'toriino-enrollments';
const SESSIONS_TABLE      = process.env.SESSIONS_TABLE        || 'torino-sessions';
const USERS_TABLE         = process.env.USERS_TABLE           || 'torino-users';

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const ssm = new SSMClient({ region: REGION });

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

// Teacher/mentor share: the payments Lambda fixes it into the PaymentIntent metadata
// (teacherShareCents) at purchase time. Older intents without it fall back to the current
// PLATFORM_FEE_PERCENT (SSM String); if that is unavailable we throw so Stripe retries.
let feeCache;
async function teacherShareDollars(paymentIntent) {
  const fixed = Number(paymentIntent.metadata?.teacherShareCents);
  if (paymentIntent.metadata?.teacherShareCents !== undefined && Number.isInteger(fixed) && fixed >= 0 && fixed <= paymentIntent.amount) {
    return fixed / 100;
  }
  let pct = Number(process.env.PLATFORM_FEE_PERCENT);
  if (!process.env.PLATFORM_FEE_PERCENT) {
    if (!feeCache || Date.now() - feeCache.at > SECRET_TTL_MS) {
      const out = await ssm.send(new GetParameterCommand({ Name: `${process.env.SSM_PREFIX}PLATFORM_FEE_PERCENT` }));
      feeCache = { value: Number(out.Parameter?.Value), at: Date.now() };
    }
    pct = feeCache.value;
  }
  if (!Number.isFinite(pct) || pct < 0 || pct > 100) throw new Error('Platform fee not configured');
  return (paymentIntent.amount - Math.round((paymentIntent.amount * pct) / 100)) / 100;
}

let stripe;
let stripeKey;
function stripeFor(key) {
  if (!stripe || key !== stripeKey) {
    stripe = Stripe(key);
    stripeKey = key;
  }
  return stripe;
}

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
};

function res(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

// ── Idempotency guard ──────────────────────────────────────────────────────────
async function markProcessed(eventId) {
  const ttl = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60; // 30-day TTL
  try {
    await db.send(new PutCommand({
      TableName: STRIPE_EVENTS_TABLE,
      Item: { eventId, processedAt: new Date().toISOString(), ttl },
      ConditionExpression: 'attribute_not_exists(eventId)',
    }));
    return true; // first time — process it
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') return false; // already processed
    throw err;
  }
}

// ── Handlers ───────────────────────────────────────────────────────────────────
async function handlePaymentSucceeded(paymentIntent) {
  const { metadata = {}, amount, currency } = paymentIntent;
  const { type, courseId, sessionId, studentId, mentorId, teacherId } = metadata;

  if (type === 'course_purchase') {
    if (!courseId || !studentId) {
      log('WARN', 'course_purchase missing courseId or studentId — skipping enrollment', {
        courseId, studentId, paymentIntentId: paymentIntent.id,
      });
      return;
    }

    // Enrollment: idempotent via the deterministic enrollmentId the courses Lambda also uses.
    try {
      await db.send(new PutCommand({
        TableName: ENROLLMENTS_TABLE,
        Item: {
          enrollmentId: `enr_${courseId}_${studentId}`,
          userId: studentId,
          studentId,
          courseId,
          paymentIntentId: paymentIntent.id,
          status: 'active',
          enrolledAt: new Date().toISOString(),
          progress: 0,
        },
        // Write only if this (studentId, courseId) pair does not already exist
        ConditionExpression: 'attribute_not_exists(enrollmentId)',
      }));
      log('INFO', 'Student enrolled via webhook', { studentId, courseId });
    } catch (err) {
      if (err.name === 'ConditionalCheckFailedException') {
        log('INFO', 'Enrollment already exists — idempotent skip', { studentId, courseId });
      } else {
        throw err;
      }
    }

    // Credit teacher earnings — deterministic earningId for idempotency
    if (teacherId) {
      const earningId = `course_${paymentIntent.id}`;
      try {
        await db.send(new PutCommand({
          TableName: EARNINGS_TABLE,
          Item: {
            earningId,
            userId: teacherId,
            type: 'course_sale',
            amount: await teacherShareDollars(paymentIntent), // price − platform fee (server-computed)
            currency,
            referenceId: courseId,
            paymentIntentId: paymentIntent.id,
            status: 'available',
            createdAt: new Date().toISOString(),
          },
          ConditionExpression: 'attribute_not_exists(earningId)',
        }));
      } catch (err) {
        if (err.name === 'ConditionalCheckFailedException') {
          log('INFO', 'Earning already recorded — idempotent skip', { earningId });
        } else {
          throw err;
        }
      }
    }

  } else if (type === 'session_booking' && sessionId) {
    // Confirm session payment
    await db.send(new UpdateCommand({
      TableName: SESSIONS_TABLE,
      Key: { sessionId },
      UpdateExpression: 'SET #status = :s, paymentIntentId = :pi, paymentStatus = :paid, paymentMethod = :card, updatedAt = :u',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':paid': 'paid',
        ':card': 'card',
        ':s': 'confirmed',
        ':pi': paymentIntent.id,
        ':u': new Date().toISOString(),
      },
    }));

    // Credit mentor earnings — deterministic earningId for idempotency
    if (mentorId) {
      const earningId = `session_${paymentIntent.id}`;
      try {
        await db.send(new PutCommand({
          TableName: EARNINGS_TABLE,
          Item: {
            earningId,
            userId: mentorId,
            type: 'session',
            amount: await teacherShareDollars(paymentIntent), // price − platform fee (server-computed)
            currency,
            referenceId: sessionId,
            paymentIntentId: paymentIntent.id,
            status: 'pending', // held until session completes
            createdAt: new Date().toISOString(),
          },
          ConditionExpression: 'attribute_not_exists(earningId)',
        }));
      } catch (err) {
        if (err.name === 'ConditionalCheckFailedException') {
          log('INFO', 'Mentor earning already recorded — idempotent skip', { earningId });
        } else {
          throw err;
        }
      }
    }
  }
}

async function handlePaymentFailed(paymentIntent) {
  const { metadata = {} } = paymentIntent;
  const { type, sessionId } = metadata;
  if (type === 'session_booking' && sessionId) {
    await db.send(new UpdateCommand({
      TableName: SESSIONS_TABLE,
      Key: { sessionId },
      UpdateExpression: 'SET #status = :s, updatedAt = :u',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':s': 'payment_failed',
        ':u': new Date().toISOString(),
      },
    }));
  }
}

// ── Refund handler ─────────────────────────────────────────────────────────────
async function handleChargeRefunded(charge) {
  const paymentIntentId = charge.payment_intent;
  if (!paymentIntentId) {
    log('WARN', 'charge.refunded with no payment_intent — skipping', { chargeId: charge.id });
    return;
  }

  // Retrieve the original payment intent from Stripe to get metadata
  let paymentIntent;
  try {
    paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
  } catch (err) {
    log('ERROR', 'Failed to retrieve payment intent for refund', {
      paymentIntentId, error: err.message,
    });
    throw err;
  }

  const { metadata = {} } = paymentIntent;
  const { type, courseId, sessionId, studentId, mentorId, teacherId } = metadata;

  if (type === 'course_purchase' && courseId && studentId) {
    // OWNER_DECISION: Define whether refunded students retain course access.
    // Currently status is set to 'refunded' but course access is NOT revoked.
    // To revoke access, add a check in the course content Lambda that rejects
    // requests where enrollment.status === 'refunded'.
    try {
      await db.send(new UpdateCommand({
        TableName: ENROLLMENTS_TABLE,
        Key: { enrollmentId: `enr_${courseId}_${studentId}` },
        UpdateExpression: 'SET #status = :s, refundedAt = :r, updatedAt = :u',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: {
          ':s': 'refunded',
          ':r': new Date().toISOString(),
          ':u': new Date().toISOString(),
        },
      }));
      log('INFO', 'Enrollment marked refunded', { studentId, courseId });
    } catch (err) {
      log('WARN', 'Could not update enrollment for refund', {
        studentId, courseId, error: err.message,
      });
    }

    // Reverse teacher earnings — idempotent via conditional update
    if (teacherId) {
      const earningId = `course_${paymentIntentId}`;
      try {
        await db.send(new UpdateCommand({
          TableName: EARNINGS_TABLE,
          Key: { earningId },
          UpdateExpression: 'SET #status = :reversed, refundedAt = :r',
          ConditionExpression: '#status <> :reversed',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: {
            ':reversed': 'reversed',
            ':r': new Date().toISOString(),
          },
        }));
        log('INFO', 'Teacher earning reversed for refund', { earningId, teacherId });
      } catch (err) {
        if (err.name === 'ConditionalCheckFailedException') {
          log('INFO', 'Earning already reversed — idempotent skip', { earningId });
        } else {
          log('WARN', 'Could not reverse teacher earning', { earningId, error: err.message });
        }
      }
    }

  } else if (type === 'session_booking' && sessionId) {
    try {
      await db.send(new UpdateCommand({
        TableName: SESSIONS_TABLE,
        Key: { sessionId },
        UpdateExpression: 'SET #status = :s, refundedAt = :r, updatedAt = :u',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: {
          ':s': 'refunded',
          ':r': new Date().toISOString(),
          ':u': new Date().toISOString(),
        },
      }));
      log('INFO', 'Session marked refunded', { sessionId });
    } catch (err) {
      log('WARN', 'Could not update session for refund', { sessionId, error: err.message });
    }

    // Reverse mentor earnings — idempotent via conditional update
    if (mentorId) {
      const earningId = `session_${paymentIntentId}`;
      try {
        await db.send(new UpdateCommand({
          TableName: EARNINGS_TABLE,
          Key: { earningId },
          UpdateExpression: 'SET #status = :reversed, refundedAt = :r',
          ConditionExpression: '#status <> :reversed',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: {
            ':reversed': 'reversed',
            ':r': new Date().toISOString(),
          },
        }));
        log('INFO', 'Mentor earning reversed for refund', { earningId, mentorId });
      } catch (err) {
        if (err.name === 'ConditionalCheckFailedException') {
          log('INFO', 'Mentor earning already reversed — idempotent skip', { earningId });
        } else {
          log('WARN', 'Could not reverse mentor earning', { earningId, error: err.message });
        }
      }
    }
  } else {
    log('INFO', 'Refund for unhandled payment type — no state changes', {
      type, paymentIntentId, chargeId: charge.id,
    });
  }
}

// ── Subscriptions: the ONLY place a plan is activated or deactivated ─────────────
// The record (SUBSCRIPTIONS_TABLE, PK userId) is written from the Stripe subscription
// object itself. premium = status active/trialing (never after deletion or a failed
// invoice). Out-of-order events are ignored (lastEventAt), and an event about some other,
// inactive subscription (e.g. an abandoned checkout) can never switch a live plan off.
const SUBSCRIPTIONS_TABLE = process.env.SUBSCRIPTIONS_TABLE || 'toriino-subscriptions';
const ACTIVE_SUB_STATUSES = new Set(['active', 'trialing']);

async function syncSubscription(sub, eventCreated, { deleted = false, paymentFailed = false } = {}) {
  const userId = sub.metadata?.userId;
  if (!userId) {
    log('WARN', 'Subscription without metadata.userId — ignored', { subscriptionId: sub.id });
    return;
  }
  const status = deleted ? 'canceled' : (paymentFailed && ACTIVE_SUB_STATUSES.has(sub.status) ? 'past_due' : sub.status);
  const premium = !deleted && !paymentFailed && ACTIVE_SUB_STATUSES.has(status);
  const periodEnd = sub.current_period_end || sub.items?.data?.[0]?.current_period_end;
  const now = new Date().toISOString();

  const values = {
    ':plan': sub.metadata.planId || 'unknown',
    ':aud': sub.metadata.audience || 'unknown',
    ':sid': sub.id,
    ':cid': typeof sub.customer === 'string' ? sub.customer : sub.customer?.id || 'unknown',
    ':st': status,
    ':pr': premium,
    ':cap': Boolean(sub.cancel_at_period_end),
    ':t': eventCreated,
    ':now': now,
  };
  let set = 'SET planId = :plan, audience = :aud, stripeSubscriptionId = :sid, stripeCustomerId = :cid, '
    + '#s = :st, premium = :pr, cancelAtPeriodEnd = :cap, lastEventAt = :t, updatedAt = :now, createdAt = if_not_exists(createdAt, :now)';
  if (periodEnd) { set += ', currentPeriodEnd = :pe'; values[':pe'] = new Date(periodEnd * 1000).toISOString(); }

  let condition = '(attribute_not_exists(lastEventAt) OR lastEventAt <= :t)';
  if (!premium) condition += ' AND (attribute_not_exists(stripeSubscriptionId) OR stripeSubscriptionId = :sid OR premium = :false)';
  if (!premium) values[':false'] = false;

  try {
    await db.send(new UpdateCommand({
      TableName: SUBSCRIPTIONS_TABLE,
      Key: { userId },
      UpdateExpression: set,
      ConditionExpression: condition,
      ExpressionAttributeNames: { '#s': 'status' },
      ExpressionAttributeValues: values,
    }));
    log('INFO', 'Subscription synced', { userId, subscriptionId: sub.id, status, premium });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      log('INFO', 'Stale or unrelated subscription event ignored', { userId, subscriptionId: sub.id, status });
      return;
    }
    throw err;
  }
}

function invoiceSubscriptionId(invoice) {
  const v = invoice.subscription || invoice.parent?.subscription_details?.subscription;
  return typeof v === 'string' ? v : v?.id;
}

async function handleInvoice(invoice, eventCreated, paymentFailed) {
  const subId = invoiceSubscriptionId(invoice);
  if (!subId) return; // not a subscription invoice
  const sub = await stripe.subscriptions.retrieve(subId);
  await syncSubscription(sub, eventCreated, { paymentFailed });
}

// ── Handler entry point ────────────────────────────────────────────────────────
exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});

  // Read per request (cached 5 min) so secrets set after a cold start are picked up.
  let webhookSecret;
  let secretKey;
  try {
    [webhookSecret, secretKey] = await Promise.all([getSecret('STRIPE_WEBHOOK_SECRET'), getSecret('STRIPE_SECRET_KEY')]);
  } catch (err) {
    log('ERROR', 'Could not read Stripe secrets', { error: err.message });
    return res(500, { error: 'Webhook could not load its configuration' });
  }
  if (!webhookSecret || !secretKey) {
    log('ERROR', 'Stripe webhook not configured — STRIPE_WEBHOOK_SECRET or STRIPE_SECRET_KEY is NOT_SET');
    return res(503, { error: 'Stripe webhook not configured' });
  }
  stripeFor(secretKey);

  // API Gateway passes header names as the client sent them (Stripe sends "Stripe-Signature").
  const reqHeaders = event.headers || {};
  const sigKey = Object.keys(reqHeaders).find((k) => k.toLowerCase() === 'stripe-signature');
  const sig = sigKey ? reqHeaders[sigKey] : undefined;
  if (!sig) {
    log('WARN', 'Webhook request without Stripe-Signature header');
    return res(400, { error: 'Missing Stripe-Signature header' });
  }

  // Signature verification needs the exact raw body.
  const rawBody = event.isBase64Encoded
    ? Buffer.from(event.body || '', 'base64').toString('utf8')
    : (event.body || '');
  let stripeEvent;

  try {
    stripeEvent = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (err) {
    log('ERROR', 'Webhook signature verification failed', { error: err.message });
    return res(400, { error: 'Invalid signature' });
  }

  // Idempotency — skip already-processed events
  const isNew = await markProcessed(stripeEvent.id);
  if (!isNew) {
    log('INFO', 'Duplicate webhook event skipped', { eventId: stripeEvent.id, type: stripeEvent.type });
    return res(200, { received: true, duplicate: true });
  }

  log('INFO', 'Processing webhook event', { eventId: stripeEvent.id, type: stripeEvent.type });

  try {
    switch (stripeEvent.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSucceeded(stripeEvent.data.object);
        break;
      case 'payment_intent.payment_failed':
        await handlePaymentFailed(stripeEvent.data.object);
        break;
      case 'charge.refunded':
        await handleChargeRefunded(stripeEvent.data.object);
        break;
      case 'customer.subscription.created':
        await syncSubscription(stripeEvent.data.object, stripeEvent.created);
        break;
      case 'customer.subscription.updated':
        await syncSubscription(stripeEvent.data.object, stripeEvent.created);
        break;
      case 'customer.subscription.deleted':
        await syncSubscription(stripeEvent.data.object, stripeEvent.created, { deleted: true });
        break;
      case 'invoice.paid':
        await handleInvoice(stripeEvent.data.object, stripeEvent.created, false);
        break;
      case 'invoice.payment_failed':
        await handleInvoice(stripeEvent.data.object, stripeEvent.created, true);
        break;
      default:
        log('INFO', 'Unhandled webhook event type', { type: stripeEvent.type });
    }
    return res(200, { received: true });
  } catch (err) {
    log('ERROR', 'Error processing webhook event', { type: stripeEvent.type, error: err.message });
    // Release the idempotency marker so Stripe's retry is processed, not skipped as a duplicate.
    try {
      await db.send(new DeleteCommand({ TableName: STRIPE_EVENTS_TABLE, Key: { eventId: stripeEvent.id } }));
    } catch (e) {
      log('ERROR', 'Could not release idempotency marker', { eventId: stripeEvent.id, error: e.message });
    }
    // Return 500 so Stripe retries
    return res(500, { error: 'Processing failed' });
  }
};
