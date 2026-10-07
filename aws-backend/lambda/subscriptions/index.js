/**
 * subscriptions Lambda  (Cognito authorizer)
 *
 *   GET  /subscriptions/plans[?audience=student|teacher|mentor]
 *        Plans offered to the caller's role (or the given audience). A plan is offered only if
 *        it is active, has a real Stripe Price ID and a valid price. `savings` is computed here
 *        from the actual prices (vs the same audience's offered monthly plan) and omitted when
 *        there is no real saving. { audience, plans, comingSoon }
 *   GET  /subscriptions/me        the caller's server-side record { premium, status, planId, … }
 *   POST /subscriptions { planId } creates the Stripe subscription server-side (incomplete) and
 *        returns the PaymentIntent client secret. It NEVER activates anything: only the
 *        stripe-webhook Lambda does (customer.subscription.*, invoice.paid / payment_failed).
 *   POST /subscriptions/cancel     asks Stripe to cancel at period end; the webhook records it.
 *
 * Config (SSM under SSM_PREFIX, no redeploy needed to change):
 *   SUBSCRIPTION_PLANS (String, JSON array): { planId, name, audience, months, price, currency,
 *                                              stripePriceId ("NOT_SET" until provided), active }
 *   STRIPE_SECRET_KEY  (SecureString)
 *
 * Env: SUBSCRIPTIONS_TABLE (PK userId), USERS_TABLE, SSM_PREFIX
 */
const Stripe = require('stripe');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

const REGION = process.env.AWS_REGION || 'us-east-1';
const SUBSCRIPTIONS_TABLE = process.env.SUBSCRIPTIONS_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;

const db = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const ssm = new SSMClient({ region: REGION });

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
};
const res = (statusCode, body) => ({ statusCode, headers, body: JSON.stringify(body) });
function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const AUDIENCES = new Set(['student', 'teacher', 'mentor']);
const ACTIVE_STATUSES = new Set(['active', 'trialing']);
const NOT_SET = 'NOT_SET';

// ── SSM (cached 5 min) ───────────────────────────────────────────────────────
const cache = {};
async function getParam(name, secure) {
  if (process.env[name] && process.env[name] !== NOT_SET) return process.env[name];
  const hit = cache[name];
  if (hit && Date.now() - hit.at < 5 * 60 * 1000) return hit.value;
  let value = null;
  try {
    const out = await ssm.send(new GetParameterCommand({ Name: `${process.env.SSM_PREFIX}${name}`, WithDecryption: secure }));
    const raw = out.Parameter?.Value;
    value = raw && raw !== NOT_SET ? raw : null;
  } catch (err) {
    if (err.name !== 'ParameterNotFound') throw err;
  }
  cache[name] = { value, at: Date.now() };
  return value;
}

async function loadPlans() {
  const raw = await getParam('SUBSCRIPTION_PLANS', false);
  if (!raw) return [];
  let plans;
  try { plans = JSON.parse(raw); } catch {
    log('ERROR', 'SUBSCRIPTION_PLANS is not valid JSON');
    return [];
  }
  return Array.isArray(plans) ? plans : [];
}

const isOffered = (p) => p && p.active === true && AUDIENCES.has(p.audience)
  && typeof p.planId === 'string' && Number.isInteger(p.months) && p.months > 0
  && Number(p.price) > 0 && typeof p.stripePriceId === 'string' && p.stripePriceId && p.stripePriceId !== NOT_SET;

// Saving vs paying the same audience's monthly plan for the same period, from real prices.
function withSavings(plan, offered) {
  const view = {
    planId: plan.planId,
    name: plan.name || plan.planId,
    audience: plan.audience,
    months: plan.months,
    price: Number(plan.price),
    currency: (plan.currency || 'usd').toLowerCase(),
  };
  const monthly = offered.find((m) => m.audience === plan.audience && m.months === 1
    && (m.currency || 'usd').toLowerCase() === view.currency);
  if (monthly && plan.months > 1) {
    const equivCents = Math.round(Number(monthly.price) * 100) * plan.months;
    const priceCents = Math.round(view.price * 100);
    if (priceCents < equivCents) {
      const savedCents = equivCents - priceCents;
      view.savings = {
        amount: savedCents / 100,
        percent: Math.round((savedCents / equivCents) * 100),
        comparedTo: monthly.planId,
      };
    }
  }
  return view;
}

let stripeClient; let stripeKey;
async function getStripe() {
  const key = await getParam('STRIPE_SECRET_KEY', true);
  if (!key) return null;
  if (!stripeClient || key !== stripeKey) { stripeClient = Stripe(key); stripeKey = key; }
  return stripeClient;
}

async function getRecord(userId) {
  const { Item } = await db.send(new GetCommand({ TableName: SUBSCRIPTIONS_TABLE, Key: { userId } }));
  return Item || null;
}
const isPremium = (r) => Boolean(r && r.premium === true && ACTIVE_STATUSES.has(r.status)
  && (!r.currentPeriodEnd || Date.parse(r.currentPeriodEnd) > Date.now()));

// ── Handlers ─────────────────────────────────────────────────────────────────
async function plansFor(role, qs) {
  const audience = String(qs.audience || role || '').toLowerCase();
  if (!AUDIENCES.has(audience)) return res(400, { error: 'audience must be student, teacher or mentor' });
  const offered = (await loadPlans()).filter(isOffered);
  const plans = offered.filter((p) => p.audience === audience)
    .sort((a, b) => a.months - b.months)
    .map((p) => withSavings(p, offered));
  return res(200, { audience, plans, comingSoon: plans.length === 0 });
}

async function me(userId) {
  const r = await getRecord(userId);
  if (!r) return res(200, { premium: false, status: 'none' });
  return res(200, {
    premium: isPremium(r),
    status: r.status,
    planId: r.planId,
    currentPeriodEnd: r.currentPeriodEnd,
    cancelAtPeriodEnd: Boolean(r.cancelAtPeriodEnd),
  });
}

async function subscribe(userId, role, claims, { planId }) {
  if (!planId) return res(400, { error: 'planId is required' });
  const plan = (await loadPlans()).find((p) => p.planId === planId);
  if (!isOffered(plan)) return res(404, { error: 'Plan not available' });
  if (plan.audience !== role) return res(403, { error: 'This plan is not offered for your role' });

  const current = await getRecord(userId);
  if (isPremium(current)) return res(409, { error: 'You already have an active subscription' });

  const stripe = await getStripe();
  if (!stripe) return res(503, { error: 'Stripe not configured' });

  // One Stripe customer per user, remembered on the profile.
  const { Item: user } = await db.send(new GetCommand({ TableName: USERS_TABLE, Key: { userId } }));
  let customerId = user?.stripeCustomerId;
  if (!customerId) {
    const customer = await stripe.customers.create({ email: claims.email || undefined, metadata: { userId } });
    customerId = customer.id;
    await db.send(new UpdateCommand({
      TableName: USERS_TABLE, Key: { userId },
      UpdateExpression: 'SET stripeCustomerId = :c',
      ConditionExpression: 'attribute_exists(userId)',
      ExpressionAttributeValues: { ':c': customerId },
    }));
  }

  const sub = await stripe.subscriptions.create({
    customer: customerId,
    items: [{ price: plan.stripePriceId }],
    payment_behavior: 'default_incomplete',
    payment_settings: { save_default_payment_method: 'on_subscription' },
    expand: ['latest_invoice.payment_intent'],
    metadata: { userId, planId: plan.planId, audience: plan.audience },
  });

  // Pending record only — premium stays false until the webhook sees a paid, active subscription.
  await db.send(new PutCommand({
    TableName: SUBSCRIPTIONS_TABLE,
    Item: {
      userId, planId: plan.planId, audience: plan.audience,
      stripeSubscriptionId: sub.id, stripeCustomerId: customerId,
      status: 'incomplete', premium: false,
      createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
    },
    // Never overwrite a record the webhook has already advanced past "incomplete".
    ConditionExpression: 'attribute_not_exists(userId) OR #s <> :active',
    ExpressionAttributeNames: { '#s': 'status' },
    ExpressionAttributeValues: { ':active': 'active' },
  }));
  log('INFO', 'Subscription created (incomplete)', { userId, planId, subscriptionId: sub.id });
  return res(200, {
    subscriptionId: sub.id,
    clientSecret: sub.latest_invoice?.payment_intent?.client_secret || null,
    status: 'incomplete',
    message: 'Complete the payment; your plan activates when Stripe confirms it.',
  });
}

async function cancel(userId) {
  const r = await getRecord(userId);
  if (!r || !r.stripeSubscriptionId || !ACTIVE_STATUSES.has(r.status)) return res(404, { error: 'No active subscription' });
  const stripe = await getStripe();
  if (!stripe) return res(503, { error: 'Stripe not configured' });
  await stripe.subscriptions.update(r.stripeSubscriptionId, { cancel_at_period_end: true });
  return res(202, { message: 'Cancellation requested; it takes effect at the end of the paid period.' });
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});
  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return res(401, { error: 'Unauthorized' });
  if (!SUBSCRIPTIONS_TABLE || !USERS_TABLE) return res(503, { error: 'Subscriptions not configured' });
  const role = String(claims['custom:role'] || '').toLowerCase();

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch { return res(400, { error: 'Invalid JSON body' }); }

  try {
    const p = event.path; const m = event.httpMethod;
    if (p === '/subscriptions/plans' && m === 'GET') return await plansFor(role, event.queryStringParameters || {});
    if (p === '/subscriptions/me' && m === 'GET') return await me(userId);
    if (p === '/subscriptions' && m === 'POST') return await subscribe(userId, role, claims, body);
    if (p === '/subscriptions/cancel' && m === 'POST') return await cancel(userId);
    return res(404, { error: 'Not found' });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') return res(409, { error: 'Subscription state changed; please retry' });
    log('ERROR', 'Subscriptions handler error', { error: err.message });
    return res(500, { error: 'Subscription request failed' });
  }
};
