const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
} = require("@aws-sdk/lib-dynamodb");

const REGION = "us-east-1";
const WALLET_TABLE = process.env.WALLET_TABLE || "toriino-wallet";
const WALLET_EVENTS_TABLE =
  process.env.WALLET_EVENTS_TABLE || "toriino-wallet-events";

const dynamodb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: REGION })
);

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "POST,GET,OPTIONS",
};

function response(statusCode, body) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

function getUserId(event) {
  return event.requestContext?.authorizer?.claims?.sub;
}

exports.handler = async (event) => {
  const method = event.httpMethod;
  const path = event.path;

  if (method === "OPTIONS") return response(200, {});

  // userId always from Cognito authorizer — never trust client body
  const userId = getUserId(event);
  if (!userId) return response(401, { error: "Unauthorized" });

  try {
    if (path === "/wallet/deduct" && method === "POST") {
      return await deductBalance(userId, event.body ? JSON.parse(event.body) : {});
    }
    if (path === "/wallet" && method === "GET") {
      return await getBalance(userId);
    }
    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Wallet error:", error);
    return response(500, { error: error.message });
  }
};

// ── Get Balance ────────────────────────────────────────────
async function getBalance(userId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: WALLET_TABLE, Key: { userId } })
  );
  const balance = result.Item?.balance ?? 0;
  return response(200, { userId, balance });
}

// ── Deduct Balance ─────────────────────────────────────────
async function deductBalance(userId, body) {
  const { amount, description, idempotencyKey } = body;

  if (typeof amount !== "number" || amount <= 0) {
    return response(400, { error: "amount must be a positive number" });
  }
  if (!description || typeof description !== "string") {
    return response(400, { error: "description is required" });
  }

  // Idempotency: if key provided, check if already processed
  if (idempotencyKey) {
    const existing = await dynamodb.send(
      new GetCommand({
        TableName: WALLET_EVENTS_TABLE,
        Key: { userId, eventId: idempotencyKey },
      })
    );
    if (existing.Item) {
      return response(200, {
        message: "Already processed",
        balance: existing.Item.balanceAfter,
        idempotencyKey,
      });
    }
  }

  // Read current balance
  const walletResult = await dynamodb.send(
    new GetCommand({ TableName: WALLET_TABLE, Key: { userId } })
  );
  const currentBalance = walletResult.Item?.balance ?? 0;

  if (currentBalance < amount) {
    // TODO: charge Stripe for shortfall (Stripe not yet configured)
    return response(402, {
      error: "insufficient_balance",
      balance: currentBalance,
    });
  }

  // Atomic deduction with ConditionExpression to prevent race conditions
  let newBalance;
  try {
    const updateResult = await dynamodb.send(
      new UpdateCommand({
        TableName: WALLET_TABLE,
        Key: { userId },
        UpdateExpression: "SET balance = balance - :amount, updatedAt = :ts",
        ConditionExpression: "balance >= :amount",
        ExpressionAttributeValues: {
          ":amount": amount,
          ":ts": new Date().toISOString(),
        },
        ReturnValues: "ALL_NEW",
      })
    );
    newBalance = updateResult.Attributes.balance;
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") {
      // Race condition: balance dropped below amount between read and write
      const refreshed = await dynamodb.send(
        new GetCommand({ TableName: WALLET_TABLE, Key: { userId } })
      );
      return response(402, {
        error: "insufficient_balance",
        balance: refreshed.Item?.balance ?? 0,
      });
    }
    throw err;
  }

  // Record the event for idempotency and audit
  if (idempotencyKey) {
    await dynamodb.send(
      new PutCommand({
        TableName: WALLET_EVENTS_TABLE,
        Item: {
          userId,
          eventId: idempotencyKey,
          amount,
          description,
          balanceAfter: newBalance,
          createdAt: new Date().toISOString(),
        },
        ConditionExpression: "attribute_not_exists(eventId)",
      }).catch(() => {
        // Duplicate write race — already processed
      })
    );
  }

  return response(200, {
    message: "Deduction successful",
    balance: newBalance,
    deducted: amount,
  });
}
