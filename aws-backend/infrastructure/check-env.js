/**
 * Toriino Todd — Pre-deployment Environment Check
 *
 * Validates AWS credentials and connectivity before running deploy scripts.
 * Run this first to make sure everything is configured correctly.
 *
 * Usage: node check-env.js
 */

const { STSClient, GetCallerIdentityCommand } = require("@aws-sdk/client-sts");
const { DynamoDBClient, ListTablesCommand } = require("@aws-sdk/client-dynamodb");
const { LambdaClient, ListFunctionsCommand } = require("@aws-sdk/client-lambda");
const { APIGatewayClient, GetRestApiCommand } = require("@aws-sdk/client-api-gateway");
const fs = require("fs");
const path = require("path");

const REGION = "us-east-1";
const REST_API_ID = "pq8cu94cfd";
const PROJECT_PREFIX = "toriino";

const sts = new STSClient({ region: REGION });
const dynamo = new DynamoDBClient({ region: REGION });
const lambda = new LambdaClient({ region: REGION });
const apigw = new APIGatewayClient({ region: REGION });

let ok = 0, warn = 0, fail = 0;

function pass(msg) { console.log(`  ✓  ${msg}`); ok++; }
function skip(msg) { console.log(`  ⚠  ${msg}`); warn++; }
function error(msg) { console.log(`  ✗  ${msg}`); fail++; }

async function main() {
  console.log("\n==============================================");
  console.log("  TORIINO — Environment Check");
  console.log("==============================================\n");

  // 1. AWS credentials
  console.log("  [1/5] AWS Credentials");
  try {
    const id = await sts.send(new GetCallerIdentityCommand({}));
    pass(`Account: ${id.Account} (${id.Arn})`);
  } catch (e) {
    error(`AWS credentials not configured: ${e.message}`);
    error("Run: aws configure");
    console.log("\n  Cannot continue without credentials.\n");
    process.exit(1);
  }

  // 2. Config file
  console.log("\n  [2/5] aws-config.json");
  const configPath = path.join(__dirname, "aws-config.json");
  if (fs.existsSync(configPath)) {
    const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
    pass(`Found: ${configPath}`);
    if (config.cognitoUserPoolId) pass(`Cognito Pool ID: ${config.cognitoUserPoolId}`);
    else skip("cognitoUserPoolId missing — needed for auth");
    if (config.lambdaRoleArn) pass(`Lambda Role ARN: ${config.lambdaRoleArn}`);
    else skip("lambdaRoleArn missing — run deploy.js first");
  } else {
    skip("aws-config.json not found — run deploy.js to create it");
  }

  // 3. DynamoDB Tables
  console.log("\n  [3/5] DynamoDB Tables");
  const expectedTables = [
    "toriino-users", "toriino-courses", "toriino-sessions", "toriino-mentors",
    "toriino-earnings", "toriino-reviews", "toriino-notifications",
    "toriino-transcripts", "toriino-session-summaries", "toriino-ai-chat",
    "toriino-ai-twins", "toriino-ai-memory", "toriino-knowledge-graph",
  ];
  try {
    const r = await dynamo.send(new ListTablesCommand({ Limit: 100 }));
    const existing = new Set(r.TableNames);
    let missing = 0;
    for (const t of expectedTables) {
      if (existing.has(t)) pass(t);
      else { skip(`${t} — not yet created`); missing++; }
    }
    if (missing > 0) skip(`${missing} tables missing — run deploy.js and deploy-ai.js`);
  } catch (e) {
    error(`Cannot list DynamoDB tables: ${e.message}`);
  }

  // 4. Lambda functions
  console.log("\n  [4/5] Lambda Functions");
  const expectedFns = [
    "toriino-auth", "toriino-users", "toriino-courses", "toriino-sessions",
    "toriino-mentors", "toriino-earnings", "toriino-reviews", "toriino-notifications",
    "toriino-ai-transcripts", "toriino-ai-summaries", "toriino-ai-chat",
    "toriino-ai-twins", "toriino-ai-memory", "toriino-agora-recording",
    "toriino-transcribe-processor", "toriino-admin",
  ];
  try {
    const r = await lambda.send(new ListFunctionsCommand({ MaxItems: 100 }));
    const existing = new Set(r.Functions.map(f => f.FunctionName));
    let missing = 0;
    for (const fn of expectedFns) {
      if (existing.has(fn)) pass(fn);
      else { skip(`${fn} — not yet deployed`); missing++; }
    }
    if (missing > 0) skip(`${missing} Lambdas missing — run deploy.js and deploy-ai.js`);
  } catch (e) {
    error(`Cannot list Lambda functions: ${e.message}`);
  }

  // 5. API Gateway
  console.log("\n  [5/5] API Gateway");
  try {
    const r = await apigw.send(new GetRestApiCommand({ restApiId: REST_API_ID }));
    pass(`API Gateway: ${r.name} (${REST_API_ID})`);
    pass(`URL: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod`);
  } catch (e) {
    skip(`API Gateway ${REST_API_ID} not accessible: ${e.message}`);
  }

  // Summary
  console.log("\n==============================================");
  console.log(`  ✓ ${ok} passed  ⚠ ${warn} warnings  ✗ ${fail} failed`);
  console.log("==============================================");

  if (fail > 0) {
    console.log("\n  Fix the failed checks above before deploying.\n");
  } else if (warn > 0) {
    console.log("\n  Deployment order:");
    console.log("    1. node deploy.js              — core infra + base Lambdas");
    console.log("    2. node deploy-ai.js --gemini-key=KEY  — AI + admin Lambdas");
    console.log("    3. node deploy-routes.js       — wire all routes to API Gateway");
    console.log("    4. node setup-admin.js --email=you@example.com --password=Temp123!");
    console.log("");
  } else {
    console.log("\n  All checks passed! Run deploy-routes.js to wire new routes.\n");
  }
}

main().catch(console.error);
