/**
 * POST /notifications/register-device
 * Body: { token: string, platform: 'android' | 'ios' }
 * Stores/updates the FCM token for the authenticated user.
 *
 * Table: toriino-devices (PK: userId, SK: token)
 * Env: DEVICES_TABLE (default: toriino-devices)
 */
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const REGION = process.env.AWS_REGION || 'us-east-1';
const DEVICES_TABLE = process.env.DEVICES_TABLE || 'toriino-devices';

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

const headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'POST,OPTIONS',
};

function getUserId(event) {
  const sub = event.requestContext?.authorizer?.claims?.sub;
  if (sub) return sub;
  try {
    const auth = event.headers?.Authorization || event.headers?.authorization || '';
    const token = auth.replace(/^Bearer\s+/i, '');
    if (!token) return null;
    return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()).sub || null;
  } catch { return null; }
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') return { statusCode: 200, headers, body: '{}' };

  const userId = getUserId(event);
  if (!userId) return { statusCode: 401, headers, body: JSON.stringify({ error: 'Unauthorized' }) };

  let body;
  try { body = JSON.parse(event.body || '{}'); } catch {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid JSON' }) };
  }

  const { token, platform } = body;
  if (!token) return { statusCode: 400, headers, body: JSON.stringify({ error: 'token is required' }) };

  await ddb.send(new PutCommand({
    TableName: DEVICES_TABLE,
    Item: {
      userId,
      token,
      platform: platform || 'android',
      updatedAt: new Date().toISOString(),
    },
  }));

  return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
};
