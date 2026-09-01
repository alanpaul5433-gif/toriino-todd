/**
 * Toriino Todd — AI Lambda Deployment Script
 *
 * Deploys the 7 AI Lambda functions:
 *   toriino-ai-transcripts, toriino-ai-summaries, toriino-ai-chat,
 *   toriino-ai-twins, toriino-ai-memory, toriino-agora-recording,
 *   toriino-transcribe-processor
 *
 * Also creates the required DynamoDB tables and IAM role updates.
 *
 * Prerequisites:
 *   - aws-config.json must exist (created by deploy.js)
 *   - AWS credentials configured (aws configure or env vars)
 *   - GEMINI_API_KEY set in environment or passed via --gemini-key flag
 *   - For Agora recording: AGORA_APP_ID, AGORA_CUSTOMER_ID, AGORA_CUSTOMER_SECRET in env
 *
 * Usage: node deploy-ai.js [--gemini-key YOUR_KEY]
 */

const {
  LambdaClient,
  CreateFunctionCommand,
  UpdateFunctionCodeCommand,
  UpdateFunctionConfigurationCommand,
  GetFunctionCommand,
  AddPermissionCommand,
} = require("@aws-sdk/client-lambda");

const {
  DynamoDBClient,
  CreateTableCommand,
  DescribeTableCommand,
  ListTablesCommand,
} = require("@aws-sdk/client-dynamodb");

const {
  IAMClient,
  AttachRolePolicyCommand,
  GetRoleCommand,
} = require("@aws-sdk/client-iam");

const {
  S3Client,
  CreateBucketCommand,
  PutBucketCorsCommand,
  HeadBucketCommand,
  PutBucketNotificationConfigurationCommand,
} = require("@aws-sdk/client-s3");

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const REGION = "us-east-1";
const PROJECT_PREFIX = "toriino";

const lambda = new DynamoDBClient({ region: REGION }); // placeholder — overridden below
const lambdaClient = new LambdaClient({ region: REGION });
const dynamoClient = new DynamoDBClient({ region: REGION });
const iamClient = new IAMClient({ region: REGION });
const s3Client = new S3Client({ region: REGION });

// Parse --gemini-key flag
const args = process.argv.slice(2);
const geminiKeyFlag = args.find((a) => a.startsWith("--gemini-key="));
const GEMINI_API_KEY = geminiKeyFlag
  ? geminiKeyFlag.split("=")[1]
  : process.env.GEMINI_API_KEY || "";

if (!GEMINI_API_KEY) {
  console.warn("\n  [warn] GEMINI_API_KEY not set — Lambda env vars will have empty key.\n");
}

// Load config from deploy.js output
const configPath = path.join(__dirname, "aws-config.json");
if (!fs.existsSync(configPath)) {
  console.error("aws-config.json not found. Run deploy.js first.");
  process.exit(1);
}
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const RECORDING_S3_BUCKET = `${PROJECT_PREFIX}-recordings-${config.accountId || "888245942659"}`;

// ─── DynamoDB Tables ────────────────────────────────────────────────────────

const AI_TABLES = [
  {
    name: `${PROJECT_PREFIX}-transcripts`,
    key: [{ AttributeName: "sessionId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "sessionId", AttributeType: "S" }],
  },
  {
    name: `${PROJECT_PREFIX}-session-summaries`,
    key: [{ AttributeName: "sessionId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "sessionId", AttributeType: "S" }],
  },
  {
    name: `${PROJECT_PREFIX}-ai-chat`,
    key: [
      { AttributeName: "userId", KeyType: "HASH" },
      { AttributeName: "messageId", KeyType: "RANGE" },
    ],
    attrs: [
      { AttributeName: "userId", AttributeType: "S" },
      { AttributeName: "messageId", AttributeType: "S" },
    ],
  },
  {
    name: `${PROJECT_PREFIX}-ai-twins`,
    key: [{ AttributeName: "userId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "userId", AttributeType: "S" }],
  },
  {
    name: `${PROJECT_PREFIX}-ai-memory`,
    key: [{ AttributeName: "userId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "userId", AttributeType: "S" }],
  },
  {
    name: `${PROJECT_PREFIX}-knowledge-graph`,
    key: [{ AttributeName: "userId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "userId", AttributeType: "S" }],
  },
  {
    name: `${PROJECT_PREFIX}-recordings`,
    key: [{ AttributeName: "sessionId", KeyType: "HASH" }],
    attrs: [{ AttributeName: "sessionId", AttributeType: "S" }],
  },
];

// ─── Lambda Definitions ─────────────────────────────────────────────────────

const AI_LAMBDAS = [
  {
    name: `${PROJECT_PREFIX}-ai-transcripts`,
    dir: path.join(__dirname, "..", "lambda", "ai-transcripts"),
    timeout: 15,
    memorySize: 256,
    envVars: {
      TRANSCRIPTS_TABLE: `${PROJECT_PREFIX}-transcripts`,
    },
  },
  {
    name: `${PROJECT_PREFIX}-ai-summaries`,
    dir: path.join(__dirname, "..", "lambda", "ai-summaries"),
    timeout: 60,
    memorySize: 256,
    envVars: {
      SUMMARIES_TABLE: `${PROJECT_PREFIX}-session-summaries`,
      TRANSCRIPTS_TABLE: `${PROJECT_PREFIX}-transcripts`,
      GEMINI_API_KEY,
    },
  },
  {
    name: `${PROJECT_PREFIX}-ai-chat`,
    dir: path.join(__dirname, "..", "lambda", "ai-chat"),
    timeout: 30,
    memorySize: 256,
    envVars: {
      CHAT_TABLE: `${PROJECT_PREFIX}-ai-chat`,
      GEMINI_API_KEY,
    },
  },
  {
    name: `${PROJECT_PREFIX}-ai-twins`,
    dir: path.join(__dirname, "..", "lambda", "ai-twins"),
    timeout: 60,
    memorySize: 256,
    envVars: {
      TWINS_TABLE: `${PROJECT_PREFIX}-ai-twins`,
      GEMINI_API_KEY,
    },
  },
  {
    name: `${PROJECT_PREFIX}-ai-memory`,
    dir: path.join(__dirname, "..", "lambda", "ai-memory"),
    timeout: 30,
    memorySize: 256,
    envVars: {
      MEMORY_TABLE: `${PROJECT_PREFIX}-ai-memory`,
      KNOWLEDGE_GRAPH_TABLE: `${PROJECT_PREFIX}-knowledge-graph`,
      GEMINI_API_KEY,
    },
  },
  {
    name: `${PROJECT_PREFIX}-agora-recording`,
    dir: path.join(__dirname, "..", "lambda", "agora-recording"),
    timeout: 30,
    memorySize: 256,
    envVars: {
      RECORDING_TABLE: `${PROJECT_PREFIX}-recordings`,
      AGORA_APP_ID: process.env.AGORA_APP_ID || "",
      AGORA_CUSTOMER_ID: process.env.AGORA_CUSTOMER_ID || "",
      AGORA_CUSTOMER_SECRET: process.env.AGORA_CUSTOMER_SECRET || "",
      RECORDING_S3_BUCKET,
    },
  },
  {
    name: `${PROJECT_PREFIX}-transcribe-processor`,
    dir: path.join(__dirname, "..", "lambda", "transcribe-processor"),
    timeout: 900, // 15 min max — polls Transcribe job
    memorySize: 512,
    envVars: {
      TRANSCRIPTS_TABLE: `${PROJECT_PREFIX}-transcripts`,
      SUMMARIES_TABLE: `${PROJECT_PREFIX}-session-summaries`,
      GEMINI_API_KEY,
    },
    s3Trigger: RECORDING_S3_BUCKET,
  },
  {
    name: `${PROJECT_PREFIX}-admin`,
    dir: path.join(__dirname, "..", "lambda", "admin"),
    timeout: 30,
    memorySize: 256,
    envVars: {
      COGNITO_USER_POOL_ID: process.env.COGNITO_USER_POOL_ID || config.userPoolId || "",
    },
  },
];

// ─── Helpers ────────────────────────────────────────────────────────────────

async function tableExists(tableName) {
  try {
    await dynamoClient.send(new DescribeTableCommand({ TableName: tableName }));
    return true;
  } catch {
    return false;
  }
}

async function functionExists(functionName) {
  try {
    await lambdaClient.send(new GetFunctionCommand({ FunctionName: functionName }));
    return true;
  } catch {
    return false;
  }
}

async function bucketExists(bucketName) {
  try {
    await s3Client.send(new HeadBucketCommand({ Bucket: bucketName }));
    return true;
  } catch {
    return false;
  }
}

function zipLambda(dir, functionName) {
  const tmpDir = path.join(__dirname, ".tmp-zips");
  if (!fs.existsSync(tmpDir)) fs.mkdirSync(tmpDir);
  const zipPath = path.join(tmpDir, `${functionName}.zip`);

  // Windows: use PowerShell Compress-Archive
  const dirEscaped = dir.replace(/'/g, "''");
  const zipEscaped = zipPath.replace(/'/g, "''");
  execSync(
    `powershell -Command "Compress-Archive -Path '${dirEscaped}\\*' -DestinationPath '${zipEscaped}' -Force"`,
    { stdio: "inherit" }
  );
  return fs.readFileSync(zipPath);
}

// ─── Create DynamoDB Tables ──────────────────────────────────────────────────

async function createTables() {
  console.log("\n  [1/4] Creating DynamoDB tables...");
  for (const table of AI_TABLES) {
    if (await tableExists(table.name)) {
      console.log(`    [skip] ${table.name} (already exists)`);
      continue;
    }
    await dynamoClient.send(
      new CreateTableCommand({
        TableName: table.name,
        KeySchema: table.key,
        AttributeDefinitions: table.attrs,
        BillingMode: "PAY_PER_REQUEST",
      })
    );
    console.log(`    [created] ${table.name}`);
  }
}

// ─── Create Recordings S3 Bucket ────────────────────────────────────────────

async function createRecordingsBucket() {
  console.log("\n  [2/4] Creating recordings S3 bucket...");
  if (await bucketExists(RECORDING_S3_BUCKET)) {
    console.log(`    [skip] ${RECORDING_S3_BUCKET} (already exists)`);
    return;
  }
  await s3Client.send(new CreateBucketCommand({ Bucket: RECORDING_S3_BUCKET }));
  await s3Client.send(
    new PutBucketCorsCommand({
      Bucket: RECORDING_S3_BUCKET,
      CORSConfiguration: {
        CORSRules: [
          {
            AllowedHeaders: ["*"],
            AllowedMethods: ["GET", "PUT", "POST"],
            AllowedOrigins: ["*"],
            MaxAgeSeconds: 3000,
          },
        ],
      },
    })
  );
  console.log(`    [created] ${RECORDING_S3_BUCKET}`);
}

// ─── Attach IAM Policies to Lambda Role ─────────────────────────────────────

async function attachIamPolicies() {
  console.log("\n  [3/4] Attaching IAM policies...");
  const roleName = config.lambdaRoleArn.split("/").pop();
  const policies = [
    "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/ComprehendFullAccess",
  ];
  for (const policyArn of policies) {
    try {
      await iamClient.send(
        new AttachRolePolicyCommand({ RoleName: roleName, PolicyArn: policyArn })
      );
      console.log(`    [attached] ${policyArn.split("/").pop()}`);
    } catch (error) {
      console.log(`    [skip/error] ${policyArn.split("/").pop()}: ${error.message}`);
    }
  }
}

// ─── Deploy Lambda Functions ─────────────────────────────────────────────────

async function deployLambda(funcConfig) {
  const { name, dir, timeout, memorySize, envVars } = funcConfig;
  const exists = await functionExists(name);
  console.log(`    ${exists ? "[updating]" : "[creating]"} ${name}...`);

  const zipBuffer = zipLambda(dir, name);

  if (exists) {
    await lambdaClient.send(new UpdateFunctionCodeCommand({ FunctionName: name, ZipFile: zipBuffer }));
    // Wait a moment before updating config (code update must complete first)
    await new Promise((r) => setTimeout(r, 3000));
    await lambdaClient.send(
      new UpdateFunctionConfigurationCommand({
        FunctionName: name,
        Environment: { Variables: envVars },
        Timeout: timeout,
        MemorySize: memorySize,
      })
    );
  } else {
    await lambdaClient.send(
      new CreateFunctionCommand({
        FunctionName: name,
        Runtime: "nodejs20.x",
        Role: config.lambdaRoleArn,
        Handler: "index.handler",
        Code: { ZipFile: zipBuffer },
        Timeout: timeout,
        MemorySize: memorySize,
        Environment: { Variables: envVars },
      })
    );
  }
  console.log(`    [done] ${name}`);
}

async function wireS3Trigger(funcConfig, accountId) {
  if (!funcConfig.s3Trigger) return;
  const functionName = funcConfig.name;
  const bucket = funcConfig.s3Trigger;

  try {
    await lambdaClient.send(
      new AddPermissionCommand({
        FunctionName: functionName,
        StatementId: `s3-trigger-${Date.now()}`,
        Action: "lambda:InvokeFunction",
        Principal: "s3.amazonaws.com",
        SourceArn: `arn:aws:s3:::${bucket}`,
        SourceAccount: accountId,
      })
    );

    await s3Client.send(
      new PutBucketNotificationConfigurationCommand({
        Bucket: bucket,
        NotificationConfiguration: {
          LambdaFunctionConfigurations: [
            {
              LambdaFunctionArn: `arn:aws:lambda:${REGION}:${accountId}:function:${functionName}`,
              Events: ["s3:ObjectCreated:*"],
              Filter: {
                Key: {
                  FilterRules: [
                    { Name: "prefix", Value: "recordings/" },
                    { Name: "suffix", Value: ".mp4" },
                  ],
                },
              },
            },
          ],
        },
      })
    );
    console.log(`    [wired] S3 trigger: ${bucket} → ${functionName}`);
  } catch (error) {
    console.log(`    [warn] S3 trigger setup: ${error.message}`);
  }
}

async function deployAllLambdas() {
  console.log("\n  [4/4] Deploying Lambda functions...");
  const accountId = config.accountId || "888245942659";

  for (const func of AI_LAMBDAS) {
    try {
      await deployLambda(func);
      await wireS3Trigger(func, accountId);
    } catch (error) {
      console.error(`    [error] ${func.name}: ${error.message}`);
    }
  }
}

// ─── API Gateway Routes Summary ──────────────────────────────────────────────

function printRoutesSummary() {
  console.log("\n  ┌─────────────────────────────────────────────────────────┐");
  console.log("  │  AI API Routes — wire these in deploy-api.js             │");
  console.log("  ├──────────────────────────────────────────────────────────┤");
  const routes = [
    ["POST/GET", "/sessions/{id}/transcript",      "toriino-ai-transcripts"],
    ["POST/GET", "/sessions/{id}/summary",         "toriino-ai-summaries"],
    ["POST/GET", "/ai/chat/{userId}",              "toriino-ai-chat"],
    ["POST/GET", "/ai/twins/{userId}",             "toriino-ai-twins"],
    ["POST",     "/ai/twins/{userId}/ask",         "toriino-ai-twins"],
    ["GET/PUT",  "/ai/memory/{userId}",            "toriino-ai-memory"],
    ["POST",     "/ai/memory/{userId}/recommend",  "toriino-ai-memory"],
    ["GET/POST", "/ai/memory/{userId}/graph",      "toriino-ai-memory"],
    ["POST",     "/sessions/{id}/recording/start", "toriino-agora-recording"],
    ["POST",     "/sessions/{id}/recording/stop",  "toriino-agora-recording"],
    ["GET",      "/sessions/{id}/recording",       "toriino-agora-recording"],
    ["GET",      "/admin/stats",                   "toriino-admin"],
    ["GET/PUT",  "/admin/users",                   "toriino-admin"],
    ["GET",      "/admin/courses",                 "toriino-admin"],
    ["GET",      "/admin/sessions",                "toriino-admin"],
    ["GET",      "/admin/mentors",                 "toriino-admin"],
    ["GET",      "/admin/earnings",                "toriino-admin"],
    ["GET",      "/admin/reviews",                 "toriino-admin"],
    ["GET",      "/admin/ai/stats",                "toriino-admin"],
    ["POST",     "/admin/notifications/broadcast", "toriino-admin"],
  ];
  for (const [method, route, fn] of routes) {
    console.log(`  │  ${method.padEnd(8)} ${route.padEnd(36)} → ${fn}`);
  }
  console.log("  └──────────────────────────────────────────────────────────┘");
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\n=============================================================");
  console.log("  TORIINO — Deploying AI Lambda Layer");
  console.log("=============================================================");

  await createTables();
  await createRecordingsBucket();
  await attachIamPolicies();
  await deployAllLambdas();

  printRoutesSummary();
  console.log("\n  Deployment complete. Add the routes above to deploy-api.js\n");
}

main().catch(console.error);
