/**
 * stripe-webhook Lambda — /prod/payments/webhook
 *
 * Handles:
 *   payment_intent.succeeded          → enroll student or confirm session, credit earnings
 *   payment_intent.payment_failed     → mark payment failed on relevant order
 *   charge.refunded                   → reverse earnings, mark enrollment/session refunded
 *   customer.subscription.created     → activate subscription
 *   customer.subscription.updated     → update subscription status
 *   customer.subscription.deleted     → deactivate subscription
 *
 * Idempotency:
 *   - Event-level: every event.id is stored in toriino-stripe-events before processing.
 *     Replaying the same event.id is a no-op.
 *   - Enrollment: uses studentId+courseId composite key with ConditionExpression.
 *   - Earnings: uses deterministic earningId = '<type>_<paymentIntentId>' so that
 *     duplicate writes and refund reversals are both safe.
 *
 * OWNER: set these Lambda env vars before pointing the Stripe webhook here:
 *   STRIPE_WEBHOOK_SECRET   — whsec_... from Stripe dashboard
 *   STRIPE_SECRET_KEY       — sk_live_... or sk_test_...
 *   EARNINGS_TABLE          — toriino-earnings
 *   ENROLLMENTS_TABLE       — toriino-enrollments
 *   SESSIONS_TABLE          — toriino-sessions
 *   STRIPE_EVENTS_TABLE     — toriino-stripe-events  (PK = eventId, TTL = ttl)
 */

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
} = require('@aws-sdk/lib-dynamodb');

const REGION              = process.env.AWS_REGION            || 'us-east-1';
const STRIPE_EVENTS_TABLE = process.env.STRIPE_EVENTS_TABLE   || 'toriino-stripe-events';
const EARNINGS_TABLE      = process.env.EARNINGS_TABLE        || 'toriino-earnings';
const ENROLLMENTS_TABLE   = process.env.ENROLLMENTS_TABLE     || 'toriino-enrollments';
const SESSIONS_TABLE      = process.env.SESSIONS_TABLE        || 'toriino-sessions';
const WEBHOOK_SECRET      = process.env.STRIPE_WEBHOOK_SECRET || '';

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

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
  const amountDecimal = amount / 100;

  if (type === 'course_purchase') {
    if (!courseId || !studentId) {
      log('WARN', 'course_purchase missing courseId or studentId — skipping enrollment', {
        courseId, studentId, paymentIntentId: paymentIntent.id,
      });
      return;
    }

    // Enrollment: idempotent via (studentId PK, courseId SK) composite key.
    // The ENROLLMENTS_TABLE uses studentId as partition key and courseId as sort key.
    try {
      await db.send(new PutCommand({
        TableName: ENROLLMENTS_TABLE,
        Item: {
          studentId,
          courseId,
          paymentIntentId: paymentIntent.id,
          status: 'active',
          enrolledAt: new Date().toISOString(),
          progress: 0,
        },
        // Write only if this (studentId, courseId) pair does not already exist
        ConditionExpression: 'attribute_not_exists(courseId)',
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
            amount: amountDecimal * 0.8, // 80% to teacher, 20% platform
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
      UpdateExpression: 'SET #status = :s, paymentIntentId = :pi, updatedAt = :u',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
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
            amount: amountDecimal * 0.85, // 85% to mentor
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
        Key: { studentId, courseId },
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

async function handleSubscription(subscription, action) {
  const { metadata = {} } = subscription;
  const { userId } = metadata;
  if (!userId) return;
  await db.send(new UpdateCommand({
    TableName: 'toriino-users',
    Key: { userId },
    UpdateExpression: 'SET subscription = :sub, updatedAt = :u',
    ExpressionAttributeValues: {
      ':sub': {
        subscriptionId: subscription.id,
        status: subscription.status,
        action,
        updatedAt: new Date().toISOString(),
      },
      ':u': new Date().toISOString(),
    },
  }));
}

// ── Handler entry point ────────────────────────────────────────────────────────
exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});

  const sig = (event.headers || {})['stripe-signature'];
  let stripeEvent;

  try {
    stripeEvent = stripe.webhooks.constructEvent(
      event.body,
      sig,
      WEBHOOK_SECRET,
    );
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
        await handleSubscription(stripeEvent.data.object, 'created');
        break;
      case 'customer.subscription.updated':
        await handleSubscription(stripeEvent.data.object, 'updated');
        break;
      case 'customer.subscription.deleted':
        await handleSubscription(stripeEvent.data.object, 'deleted');
        break;
      default:
        log('INFO', 'Unhandled webhook event type', { type: stripeEvent.type });
    }
    return res(200, { received: true });
  } catch (err) {
    log('ERROR', 'Error processing webhook event', { type: stripeEvent.type, error: err.message });
    // Return 500 so Stripe retries
    return res(500, { error: 'Processing failed' });
  }
};
