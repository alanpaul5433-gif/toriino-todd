/**
 * Toriino Todd — Add Missing Routes to Existing API Gateway
 *
 * Adds AI routes and Admin routes to the already-deployed API Gateway
 * without recreating the entire API or touching existing routes.
 *
 * Existing API Gateway ID: pq8cu94cfd (us-east-1, stage: prod)
 *
 * Usage:
 *   node deploy-routes.js
 *
 * Prerequisites:
 *   - AWS credentials configured (aws configure or env vars)
 *   - All Lambda functions deployed (run deploy-ai.js first)
 */

const {
  APIGatewayClient,
  GetResourcesCommand,
  CreateResourceCommand,
  PutMethodCommand,
  PutIntegrationCommand,
  PutMethodResponseCommand,
  PutIntegrationResponseCommand,
  CreateDeploymentCommand,
} = require("@aws-sdk/client-api-gateway");

const {
  LambdaClient,
  AddPermissionCommand,
  GetFunctionCommand,
} = require("@aws-sdk/client-lambda");

const {
  STSClient,
  GetCallerIdentityCommand,
} = require("@aws-sdk/client-sts");

const fs = require("fs");
const path = require("path");

const REGION = "us-east-1";
const STAGE_NAME = "prod";
const REST_API_ID = "pq8cu94cfd"; // existing API Gateway
const PROJECT_PREFIX = "toriino";

const apigateway = new APIGatewayClient({ region: REGION });
const lambdaClient = new LambdaClient({ region: REGION });
const sts = new STSClient({ region: REGION });

// Load aws-config.json for Cognito authorizer ID
const configPath = path.join(__dirname, "aws-config.json");
const config = fs.existsSync(configPath)
  ? JSON.parse(fs.readFileSync(configPath, "utf8"))
  : {};

// ─── New Routes to Add ───────────────────────────────────────────────────────
// path -> { methods, lambda, auth }
// Use {param} notation for path parameters — API Gateway handles them automatically.

const NEW_ROUTES = {
  // AI Transcripts
  "/sessions/{id}/transcript": {
    methods: ["POST", "GET"],
    lambda: `${PROJECT_PREFIX}-ai-transcripts`,
    auth: true,
  },

  // AI Summaries
  "/sessions/{id}/summary": {
    methods: ["POST", "GET"],
    lambda: `${PROJECT_PREFIX}-ai-summaries`,
    auth: true,
  },

  // Agora Cloud Recording
  "/sessions/{id}/recording": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-agora-recording`,
    auth: true,
  },
  "/sessions/{id}/recording/start": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-agora-recording`,
    auth: true,
  },
  "/sessions/{id}/recording/stop": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-agora-recording`,
    auth: true,
  },

  // AI Chat
  "/ai/chat/{userId}": {
    methods: ["POST", "GET"],
    lambda: `${PROJECT_PREFIX}-ai-chat`,
    auth: true,
  },

  // AI Twins
  "/ai/twins/{userId}": {
    methods: ["POST", "GET"],
    lambda: `${PROJECT_PREFIX}-ai-twins`,
    auth: true,
  },
  "/ai/twins/{userId}/ask": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-ai-twins`,
    auth: true,
  },

  // AI Memory & Knowledge Graph
  "/ai/memory/{userId}": {
    methods: ["GET", "PUT"],
    lambda: `${PROJECT_PREFIX}-ai-memory`,
    auth: true,
  },
  "/ai/memory/{userId}/recommend": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-ai-memory`,
    auth: true,
  },
  "/ai/memory/{userId}/graph": {
    methods: ["GET", "POST"],
    lambda: `${PROJECT_PREFIX}-ai-memory`,
    auth: true,
  },

  // Admin — all public (admin Lambda does its own Cognito group check)
  "/admin/stats": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/users": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/users/{id}/status": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/users/{id}/role": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/users/{id}": {
    methods: ["DELETE"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/courses": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/courses/{id}/status": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/courses/{id}": {
    methods: ["DELETE"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/sessions": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/sessions/{id}/status": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/sessions/{id}/summary": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/mentors": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/mentors/{id}/approval": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/earnings": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/reviews": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/reviews/{targetId}/{reviewId}": {
    methods: ["DELETE"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/ai/stats": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
  "/admin/notifications/broadcast": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-admin`,
    auth: false,
  },
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function getLambdaArn(functionName) {
  const r = await lambdaClient.send(new GetFunctionCommand({ FunctionName: functionName }));
  return r.Configuration.FunctionArn;
}

// Build a map of existing API Gateway resources: path -> id
async function getExistingResources() {
  const map = {};
  let position;
  do {
    const r = await apigateway.send(
      new GetResourcesCommand({ restApiId: REST_API_ID, limit: 500, position })
    );
    for (const item of r.items || []) {
      map[item.path] = item.id;
    }
    position = r.position;
  } while (position);
  return map;
}

// Create a resource if it doesn't exist, returns its id
async function ensureResource(resourceMap, restApiId, routePath) {
  if (resourceMap[routePath]) return resourceMap[routePath];

  const parts = routePath.split("/").filter(Boolean);
  let parentPath = "/";
  let parentId = resourceMap["/"];

  for (let i = 0; i < parts.length; i++) {
    const currentPath = "/" + parts.slice(0, i + 1).join("/");
    if (resourceMap[currentPath]) {
      parentId = resourceMap[currentPath];
      parentPath = currentPath;
      continue;
    }

    const r = await apigateway.send(
      new CreateResourceCommand({
        restApiId,
        parentId,
        pathPart: parts[i],
      })
    );
    resourceMap[currentPath] = r.id;
    parentId = r.id;
    parentPath = currentPath;
    console.log(`    [resource] created ${currentPath}`);
  }

  return resourceMap[routePath];
}

async function addCors(restApiId, resourceId) {
  try {
    await apigateway.send(new PutMethodCommand({
      restApiId, resourceId, httpMethod: "OPTIONS", authorizationType: "NONE",
    }));
    await apigateway.send(new PutIntegrationCommand({
      restApiId, resourceId, httpMethod: "OPTIONS", type: "MOCK",
      requestTemplates: { "application/json": '{"statusCode": 200}' },
    }));
    await apigateway.send(new PutMethodResponseCommand({
      restApiId, resourceId, httpMethod: "OPTIONS", statusCode: "200",
      responseParameters: {
        "method.response.header.Access-Control-Allow-Headers": false,
        "method.response.header.Access-Control-Allow-Methods": false,
        "method.response.header.Access-Control-Allow-Origin": false,
      },
    }));
    await apigateway.send(new PutIntegrationResponseCommand({
      restApiId, resourceId, httpMethod: "OPTIONS", statusCode: "200",
      responseParameters: {
        "method.response.header.Access-Control-Allow-Headers": "'Content-Type,Authorization'",
        "method.response.header.Access-Control-Allow-Methods": "'GET,POST,PUT,DELETE,OPTIONS'",
        "method.response.header.Access-Control-Allow-Origin": "'*'",
      },
    }));
  } catch {
    // OPTIONS may already exist — skip
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("==============================================");
  console.log("  TORIINO — Add Routes to Existing API Gateway");
  console.log("==============================================\n");
  console.log(`  API Gateway ID : ${REST_API_ID}`);
  console.log(`  Region         : ${REGION}`);
  console.log(`  Stage          : ${STAGE_NAME}\n`);

  const identity = await sts.send(new GetCallerIdentityCommand({}));
  const accountId = identity.Account;
  console.log(`  Account        : ${accountId}\n`);

  // Fetch all existing resources
  console.log("  Loading existing API resources...");
  const resourceMap = await getExistingResources();
  console.log(`  Found ${Object.keys(resourceMap).length} existing resources\n`);

  let added = 0;
  let skipped = 0;
  let errors = 0;

  for (const [routePath, cfg] of Object.entries(NEW_ROUTES)) {
    let lambdaArn;
    try {
      lambdaArn = await getLambdaArn(cfg.lambda);
    } catch {
      console.warn(`  [skip] ${routePath} — Lambda ${cfg.lambda} not deployed yet`);
      skipped++;
      continue;
    }

    const resourceId = await ensureResource(resourceMap, REST_API_ID, routePath);

    for (const method of cfg.methods) {
      try {
        const methodParams = {
          restApiId: REST_API_ID,
          resourceId,
          httpMethod: method,
          authorizationType: "NONE",
          requestParameters: {},
        };

        await apigateway.send(new PutMethodCommand(methodParams));

        await apigateway.send(new PutIntegrationCommand({
          restApiId: REST_API_ID,
          resourceId,
          httpMethod: method,
          type: "AWS_PROXY",
          integrationHttpMethod: "POST",
          uri: `arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${lambdaArn}/invocations`,
        }));

        // Grant API Gateway invoke permission
        try {
          await lambdaClient.send(new AddPermissionCommand({
            FunctionName: cfg.lambda,
            StatementId: `apigw-${routePath.replace(/[^a-zA-Z0-9]/g, "-")}-${method}-${Date.now()}`,
            Action: "lambda:InvokeFunction",
            Principal: "apigateway.amazonaws.com",
            SourceArn: `arn:aws:execute-api:${REGION}:${accountId}:${REST_API_ID}/*/*`,
          }));
        } catch {
          // Permission likely already exists
        }

        console.log(`  [OK] ${method.padEnd(7)} ${routePath}`);
        added++;
      } catch (e) {
        if (e.name === "ConflictException" || e.message?.includes("already exists")) {
          console.log(`  [skip] ${method.padEnd(7)} ${routePath} (already exists)`);
          skipped++;
        } else {
          console.error(`  [ERR] ${method.padEnd(7)} ${routePath}: ${e.message}`);
          errors++;
        }
      }
    }

    await addCors(REST_API_ID, resourceId);
  }

  // Redeploy to push all changes
  console.log(`\n  Deploying to stage '${STAGE_NAME}'...`);
  await apigateway.send(new CreateDeploymentCommand({
    restApiId: REST_API_ID,
    stageName: STAGE_NAME,
    description: `AI + Admin routes added ${new Date().toISOString()}`,
  }));

  const apiUrl = `https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}`;

  console.log("\n==============================================");
  console.log("  DONE");
  console.log("==============================================");
  console.log(`\n  Routes added  : ${added}`);
  console.log(`  Routes skipped: ${skipped}`);
  console.log(`  Errors        : ${errors}`);
  console.log(`\n  API URL: ${apiUrl}`);
  console.log(`\n  Test admin stats: curl ${apiUrl}/admin/stats`);
  console.log(`  Test AI chat:     curl -X POST ${apiUrl}/ai/chat/{userId}`);
}

main().catch(console.error);
