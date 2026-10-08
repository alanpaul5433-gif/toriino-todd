/**
 * earnings Lambda — /earnings  (Cognito authorizer on every route)
 *
 *   GET  /earnings            { currentMonth, totalEarnings, totalWithdrawn, availableBalance,
 *                               pendingWithdrawals, monthlyBreakdown }
 *   GET  /earnings/history    { history, withdrawals }
 *   POST /earnings/withdraw   { amount } → pending withdrawal; rejected (409) if it
 *                             exceeds availableBalance. Any other field (bank or account details
 *                             included) is rejected with 400 and nothing is stored: payouts will
 *                             go through Stripe Connect, so bank data never reaches this API.
 *                             An optimistic lock on the earnings row
 *                             (withdrawVersion) stops two concurrent requests overdrawing.
 *
 * totalEarnings   = the user's aggregate row in EARNINGS_TABLE (monthly total)
 *                 + ledger entries written by the Stripe webhook with status 'available'
 *                   ('pending' entries — held until a session completes — are reported
 *                   as pendingEarnings; 'reversed' ones are refunds and are ignored).
 * availableBalance = totalEarnings − totalWithdrawn, where totalWithdrawn counts every
 * withdrawal that is not rejected/cancelled (pending ones are reserved).
 *
 * Env: EARNINGS_TABLE (PK userId), EARNING_ENTRIES_TABLE (PK earningId, GSI userId-index),
 *      WITHDRAWALS_TABLE (PK userId, SK withdrawalId)
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  QueryCommand,
  TransactWriteCommand,
} = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

const REGION = process.env.AWS_REGION || "us-east-1";
const EARNINGS_TABLE = process.env.EARNINGS_TABLE;
const WITHDRAWALS_TABLE = process.env.WITHDRAWALS_TABLE;
const ENTRIES_TABLE = process.env.EARNING_ENTRIES_TABLE;

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function log(level, message, extra = {}) {
  console.log(JSON.stringify({ level, message, timestamp: new Date().toISOString(), ...extra }));
}

const NOT_COUNTED = new Set(["rejected", "cancelled", "failed"]);
const round2 = (n) => Math.round(n * 100) / 100;

exports.handler = async (event) => {
  const method = event.httpMethod;
  if (method === "OPTIONS") return response(200, {});

  const claims = event.requestContext?.authorizer?.claims || {};
  const userId = claims.sub;
  if (!userId) return response(401, { error: "Unauthorized" });
  if (!EARNINGS_TABLE || !WITHDRAWALS_TABLE || !ENTRIES_TABLE) return response(503, { error: "Earnings service not configured" });

  let body = {};
  try { body = event.body ? JSON.parse(event.body) : {}; } catch {
    return response(400, { error: "Invalid JSON body" });
  }

  const seg = event.path.split("/").filter(Boolean);
  try {
    if (seg.length === 1 && method === "GET") {
      const { _version, ...publicSummary } = await summary(userId);
      return response(200, publicSummary);
    }
    if (seg.length === 2 && seg[1] === "history" && method === "GET") return await history(userId);
    if (seg.length === 2 && seg[1] === "withdraw" && method === "POST") return await withdraw(userId, claims, body);
    return response(404, { error: "Route not found" });
  } catch (error) {
    log("ERROR", "Earnings handler error", { error: error.message, path: event.path, method });
    return response(500, { error: "Earnings request failed" });
  }
};

async function loadEarnings(userId) {
  const r = await dynamodb.send(new GetCommand({ TableName: EARNINGS_TABLE, Key: { userId } }));
  return r.Item ? [r.Item] : [];
}

async function queryByUser(userId, TableName, IndexName) {
  const items = [];
  let ExclusiveStartKey;
  do {
    const page = await dynamodb.send(new QueryCommand({
      TableName,
      IndexName,
      KeyConditionExpression: "userId = :u",
      ExpressionAttributeValues: { ":u": userId },
      ExclusiveStartKey,
    }));
    items.push(...(page.Items || []));
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
  return items;
}

const loadWithdrawals = (userId) => queryByUser(userId, WITHDRAWALS_TABLE);
const loadEntries = (userId) => queryByUser(userId, ENTRIES_TABLE, "userId-index");
const sum = (items, field) => items.reduce((s, x) => s + (Number(x[field]) || 0), 0);

const toPeriod = (r) => ({
  userId: r.userId,
  periodKey: r.periodKey,
  amount: Number(r.totalAmount) || 0,
  sessions: Number(r.sessionCount) || 0,
  createdAt: r.createdAt,
});

async function summary(userId) {
  const [records, entries, withdrawals] = await Promise.all([
    loadEarnings(userId), loadEntries(userId), loadWithdrawals(userId),
  ]);
  const breakdown = records.filter((r) => r.periodKey).map(toPeriod)
    .sort((a, b) => String(a.periodKey).localeCompare(String(b.periodKey)));
  const thisMonth = new Date().toISOString().slice(0, 7);
  const current = breakdown.find((p) => p.periodKey === thisMonth)
    || breakdown[breakdown.length - 1]
    || { userId, periodKey: thisMonth, amount: 0, sessions: 0 };

  const available = entries.filter((e) => e.status === "available");
  const pending = entries.filter((e) => e.status === "pending");
  const counted = withdrawals.filter((w) => !NOT_COUNTED.has(w.status));

  const totalEarnings = round2(breakdown.reduce((s, p) => s + p.amount, 0) + sum(available, "amount"));
  const totalWithdrawn = round2(sum(counted, "amount"));

  return {
    currentMonth: { userId, periodKey: current.periodKey, amount: current.amount, sessions: current.sessions },
    totalEarnings,
    totalWithdrawn,
    availableBalance: round2(Math.max(0, totalEarnings - totalWithdrawn)),
    pendingEarnings: round2(sum(pending, "amount")),
    pendingWithdrawals: round2(sum(counted.filter((w) => w.status === "pending"), "amount")),
    monthlyBreakdown: breakdown,
    _version: records[0]?.withdrawVersion || 0,
  };
}

async function history(userId) {
  const [records, entries, withdrawals] = await Promise.all([
    loadEarnings(userId), loadEntries(userId), loadWithdrawals(userId),
  ]);
  entries.sort((a, b) => String(b.createdAt || "").localeCompare(String(a.createdAt || "")));
  withdrawals.sort((a, b) => String(b.requestedAt || "").localeCompare(String(a.requestedAt || "")));
  return response(200, {
    history: records.filter((r) => r.periodKey).map(toPeriod),
    entries,
    withdrawals: withdrawals.map(({ bankDetails, ...w }) => w),
  });
}

// Only "amount" is accepted. Anything else (bankDetails, accountNumber, iban, …) is refused
// rather than silently dropped, so a client never believes its bank data was saved.
const WITHDRAW_FIELDS = new Set(["amount"]);

async function withdraw(userId, claims, body) {
  const extra = Object.keys(body || {}).filter((k) => !WITHDRAW_FIELDS.has(k));
  if (extra.length) {
    return response(400, {
      error: "Only \"amount\" is accepted. Bank details are not collected here; payouts will use Stripe Connect.",
      rejectedFields: extra,
    });
  }
  const { amount } = body;
  const role = String(claims["custom:role"] || "").toLowerCase();
  if (!["teacher", "mentor"].includes(role)) return response(403, { error: "Only teachers and mentors can withdraw earnings" });

  const value = round2(Number(amount));
  if (!Number.isFinite(value) || value <= 0) return response(400, { error: "amount must be greater than 0" });

  const s = await summary(userId);
  if (value > s.availableBalance) {
    return response(409, { error: `Amount exceeds available balance (${s.availableBalance})`, availableBalance: s.availableBalance });
  }

  const now = new Date().toISOString();
  const withdrawal = {
    userId,
    withdrawalId: `wd_${randomUUID()}`,
    amount: value,
    status: "pending",
    requestedAt: now,
    createdAt: now,
  };

  try {
    await dynamodb.send(new TransactWriteCommand({
      TransactItems: [
        {
          Update: {
            TableName: EARNINGS_TABLE,
            Key: { userId },
            UpdateExpression: "SET withdrawVersion = :next",
            ConditionExpression: "attribute_not_exists(withdrawVersion) OR withdrawVersion = :v",
            ExpressionAttributeValues: { ":v": s._version, ":next": s._version + 1 },
          },
        },
        { Put: { TableName: WITHDRAWALS_TABLE, Item: withdrawal, ConditionExpression: "attribute_not_exists(withdrawalId)" } },
      ],
    }));
  } catch (err) {
    if (err.name === "TransactionCanceledException") {
      return response(409, { error: "Balance changed while processing; please retry" });
    }
    throw err;
  }

  log("INFO", "Withdrawal requested", { userId, withdrawalId: withdrawal.withdrawalId, amount: value });
  return response(201, {
    message: "Withdrawal request submitted. Processing in 2–3 business days.",
    withdrawalId: withdrawal.withdrawalId,
    status: "pending",
    availableBalance: round2(s.availableBalance - value),
  });
}
