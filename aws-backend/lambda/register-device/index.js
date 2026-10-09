/**
 * register-device Lambda — POST /notifications/fcm-token  (Cognito authorizer)
 *
 * Body (what the app sends, lib/services/fcm_service.dart):
 *   { token: string, platform: 'android' | 'ios' }
 * The legacy field name `fcmToken` is also accepted.
 *
 * Stores the device in DEVICES_TABLE (PK userId, SK token) and mirrors the latest
 * token onto the user's profile (fcmToken) when the profile exists.
 *
 * Env: DEVICES_TABLE, USERS_TABLE
 */
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const REGION = process.env.AWS_REGION || 'us-east-1';
const DEVICES_TABLE = process.env.DEVICES_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

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

const PLATFORMS = new Set(['android', 'ios', 'web']);

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return res(200, {});
  if (event.httpMethod !== 'POST') return res(404, { error: 'Route not found' });

  const userId = event.requestContext?.authorizer?.claims?.sub;
  if (!userId) return res(401, { error: 'Unauthorized' });
  if (!DEVICES_TABLE || !USERS_TABLE) return res(503, { error: 'Device registration not configured' });

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch {
    return res(400, { error: 'Invalid JSON body' });
  }

  const token = typeof body.token === 'string' ? body.token : body.fcmToken;
  if (!token || typeof token !== 'string' || token.length > 4096) {
    return res(400, { error: 'token is required' });
  }
  const platform = PLATFORMS.has(body.platform) ? body.platform : 'android';
  const now = new Date().toISOString();

  try {
    await ddb.send(new PutCommand({
      TableName: DEVICES_TABLE,
      Item: { userId, token, platform, updatedAt: now },
    }));
  } catch (err) {
    log('ERROR', 'Device token write failed', { userId, error: err.message });
    return res(500, { error: 'Could not save the device token' });
  }

  // Mirror onto the profile; never create a profile from here.
  try {
    await ddb.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: 'SET fcmToken = :t, fcmPlatform = :p, fcmUpdatedAt = :now',
      ConditionExpression: 'attribute_exists(userId)',
      ExpressionAttributeValues: { ':t': token, ':p': platform, ':now': now },
    }));
  } catch (err) {
    if (err.name !== 'ConditionalCheckFailedException') {
      log('WARN', 'Profile fcmToken mirror failed (device row saved)', { userId, error: err.message });
    }
  }

  return res(200, { success: true, platform });
};
