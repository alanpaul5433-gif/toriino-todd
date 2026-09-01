const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } = require("@aws-sdk/lib-dynamodb");

const REGION = process.env.AWS_REGION || "us-east-1";
const RECORDING_TABLE = process.env.RECORDING_TABLE || "toriino-recordings";
const AGORA_APP_ID = process.env.AGORA_APP_ID;
const AGORA_CUSTOMER_ID = process.env.AGORA_CUSTOMER_ID;
const AGORA_CUSTOMER_SECRET = process.env.AGORA_CUSTOMER_SECRET;
const RECORDING_S3_BUCKET = process.env.RECORDING_S3_BUCKET || "toriino-recordings";

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

function getUserId(event) {
  return event.requestContext?.authorizer?.claims?.sub;
}

function agoraAuthHeader() {
  const credentials = Buffer.from(`${AGORA_CUSTOMER_ID}:${AGORA_CUSTOMER_SECRET}`).toString("base64");
  return `Basic ${credentials}`;
}

exports.handler = async (event) => {
  const path = event.path;
  const method = event.httpMethod;
  const body = event.body ? JSON.parse(event.body) : {};
  const userId = getUserId(event);

  if (method === "OPTIONS") return response(200, {});
  if (!userId) return response(401, { error: "Unauthorized" });

  try {
    const startMatch = path.match(/^\/sessions\/([^/]+)\/recording\/start$/);
    if (startMatch && method === "POST") return await startRecording(userId, startMatch[1], body);

    const stopMatch = path.match(/^\/sessions\/([^/]+)\/recording\/stop$/);
    if (stopMatch && method === "POST") return await stopRecording(userId, stopMatch[1], body);

    const statusMatch = path.match(/^\/sessions\/([^/]+)\/recording$/);
    if (statusMatch && method === "GET") return await getRecordingStatus(statusMatch[1]);

    return response(404, { error: "Route not found" });
  } catch (error) {
    console.error("Agora recording error:", error);
    return response(500, { error: error.message });
  }
};

async function startRecording(userId, sessionId, data) {
  const { channelName, token, uid } = data;
  if (!channelName || !token || !uid) return response(400, { error: "channelName, token, and uid are required" });

  // Acquire a resource ID from Agora Cloud Recording API
  const acquireRes = await fetch(
    `https://api.agora.io/v1/apps/${AGORA_APP_ID}/cloud_recording/acquire`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: agoraAuthHeader() },
      body: JSON.stringify({ cname: channelName, uid: String(uid), clientRequest: {} }),
    }
  );
  if (!acquireRes.ok) {
    const err = await acquireRes.text();
    throw new Error(`Agora acquire failed: ${err}`);
  }
  const { resourceId } = await acquireRes.json();

  // Start recording
  const startRes = await fetch(
    `https://api.agora.io/v1/apps/${AGORA_APP_ID}/cloud_recording/resourceid/${resourceId}/mode/mix/start`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: agoraAuthHeader() },
      body: JSON.stringify({
        cname: channelName,
        uid: String(uid),
        clientRequest: {
          token,
          storageConfig: {
            vendor: 1, // AWS S3
            region: 0, // us-east-1
            bucket: RECORDING_S3_BUCKET,
            fileNamePrefix: ["recordings", sessionId],
          },
          recordingConfig: {
            channelType: 0, // communication
            streamTypes: 2, // audio + video
            maxIdleTime: 30,
            audioProfile: 1,
            transcodingConfig: {
              width: 640, height: 480, fps: 15, bitrate: 500,
              mixedVideoLayout: 1, backgroundColor: "#000000",
            },
          },
        },
      }),
    }
  );

  if (!startRes.ok) {
    const err = await startRes.text();
    throw new Error(`Agora start recording failed: ${err}`);
  }
  const { sid } = await startRes.json();

  const now = new Date().toISOString();
  const recording = {
    sessionId, startedBy: userId, channelName, resourceId, sid, uid: String(uid),
    status: "recording", startedAt: now, createdAt: now,
  };
  await dynamodb.send(new PutCommand({ TableName: RECORDING_TABLE, Item: recording }));

  return response(201, { message: "Recording started", resourceId, sid, sessionId });
}

async function stopRecording(userId, sessionId, data) {
  const recordingResult = await dynamodb.send(
    new GetCommand({ TableName: RECORDING_TABLE, Key: { sessionId } })
  );
  if (!recordingResult.Item) return response(404, { error: "No active recording found" });

  const { resourceId, sid, channelName, uid } = recordingResult.Item;

  const stopRes = await fetch(
    `https://api.agora.io/v1/apps/${AGORA_APP_ID}/cloud_recording/resourceid/${resourceId}/sid/${sid}/mode/mix/stop`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: agoraAuthHeader() },
      body: JSON.stringify({ cname: channelName, uid, clientRequest: {} }),
    }
  );

  if (!stopRes.ok) {
    const err = await stopRes.text();
    throw new Error(`Agora stop recording failed: ${err}`);
  }
  const stopData = await stopRes.json();
  const s3Files = stopData.serverResponse?.fileList || [];

  const now = new Date().toISOString();
  await dynamodb.send(
    new PutCommand({
      TableName: RECORDING_TABLE,
      Item: { ...recordingResult.Item, status: "stopped", stoppedAt: now, s3Files, updatedAt: now },
    })
  );

  return response(200, { message: "Recording stopped", sessionId, s3Files });
}

async function getRecordingStatus(sessionId) {
  const result = await dynamodb.send(
    new GetCommand({ TableName: RECORDING_TABLE, Key: { sessionId } })
  );
  if (!result.Item) return response(404, { error: "Recording not found" });
  return response(200, result.Item);
}
