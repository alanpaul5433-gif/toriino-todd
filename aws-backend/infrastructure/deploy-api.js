/**
 * Toriino Todd — API Gateway Deployment Script
 *
 * Creates REST API Gateway with Cognito authorizer
 * and routes to all Lambda functions.
 *
 * Usage: node deploy-api.js
 */

const {
  APIGatewayClient,
  CreateRestApiCommand,
  GetResourcesCommand,
  CreateResourceCommand,
  PutMethodCommand,
  PutIntegrationCommand,
  CreateAuthorizerCommand,
  CreateDeploymentCommand,
  PutMethodResponseCommand,
  PutIntegrationResponseCommand,
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
const PROJECT_PREFIX = "toriino";
const STAGE_NAME = "prod";

const apigateway = new APIGatewayClient({ region: REGION });
const lambdaClient = new LambdaClient({ region: REGION });
const sts = new STSClient({ region: REGION });

const configPath = path.join(__dirname, "aws-config.json");
if (!fs.existsSync(configPath)) {
  console.error("aws-config.json not found. Run deploy.js first.");
  process.exit(1);
}
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

// Route definitions: path -> { methods, lambda, auth }
const ROUTES = {
  // Auth (no Cognito auth required for login/register)
  "/auth/register": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/login": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/verify": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/refresh": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/forgot-password": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/reset-password": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: false,
  },
  "/auth/set-role": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: true,
  },
  "/auth/logout": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-auth`,
    auth: true,
  },

  // Users (all authenticated)
  "/users/profile": {
    methods: ["GET", "PUT"],
    lambda: `${PROJECT_PREFIX}-users`,
    auth: true,
  },
  "/users/role": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-users`,
    auth: true,
  },
  "/users/avatar": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-users`,
    auth: true,
  },
  "/users/account": {
    methods: ["DELETE"],
    lambda: `${PROJECT_PREFIX}-users`,
    auth: true,
  },

  // Courses
  "/courses": {
    methods: ["GET", "POST"],
    lambda: `${PROJECT_PREFIX}-courses`,
    auth: true,
  },
  "/courses/my-courses": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-courses`,
    auth: true,
  },
  "/courses/my-created": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-courses`,
    auth: true,
  },

  // Sessions
  "/sessions": {
    methods: ["GET", "POST"],
    lambda: `${PROJECT_PREFIX}-sessions`,
    auth: true,
  },

  // Mentors
  "/mentors": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-mentors`,
    auth: true,
  },
  "/mentors/availability": {
    methods: ["PUT"],
    lambda: `${PROJECT_PREFIX}-mentors`,
    auth: true,
  },
  "/mentors/intro-video": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-mentors`,
    auth: true,
  },

  // Reviews
  "/reviews": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-reviews`,
    auth: true,
  },

  // Notifications
  "/notifications": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-notifications`,
    auth: true,
  },
  "/notifications/fcm-token": {
    methods: ["POST"],
    lambda: `${PROJECT_PREFIX}-notifications`,
    auth: true,
  },

  // Earnings
  "/earnings": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-earnings`,
    auth: true,
  },
  "/earnings/history": {
    methods: ["GET"],
    lambda: `${PROJECT_PREFIX}-earnings`,
    auth: true,
  },
};

async function getAccountId() {
  const result = await sts.send(new GetCallerIdentityCommand({}));
  return result.Account;
}

async function getLambdaArn(functionName) {
  const result = await lambdaClient.send(
    new GetFunctionCommand({ FunctionName: functionName })
  );
  return result.Configuration.FunctionArn;
}

async function deploy() {
  console.log("==============================================");
  console.log("  TORIINO — API Gateway Deployment");
  console.log("==============================================\n");

  const accountId = await getAccountId();
  console.log(`  Account: ${accountId}`);
  console.log(`  Region: ${REGION}`);

  // 1. Create REST API
  console.log("\n  Creating REST API...");
  const api = await apigateway.send(
    new CreateRestApiCommand({
      name: `${PROJECT_PREFIX}-api`,
      description: "Toriino Todd REST API",
      endpointConfiguration: { types: ["REGIONAL"] },
    })
  );
  const restApiId = api.id;
  console.log(`  API ID: ${restApiId}`);

  // 2. Create Cognito Authorizer
  console.log("  Creating Cognito Authorizer...");
  const authorizer = await apigateway.send(
    new CreateAuthorizerCommand({
      restApiId,
      name: "CognitoAuth",
      type: "COGNITO_USER_POOLS",
      providerARNs: [
        `arn:aws:cognito-idp:${REGION}:${accountId}:userpool/${config.cognitoUserPoolId}`,
      ],
      identitySource: "method.request.header.Authorization",
    })
  );
  const authorizerId = authorizer.id;
  console.log(`  Authorizer ID: ${authorizerId}`);

  // 3. Get root resource
  const resources = await apigateway.send(
    new GetResourcesCommand({ restApiId })
  );
  const rootId = resources.items.find((r) => r.path === "/").id;

  // 4. Create resources and methods
  console.log("\n  Creating routes...");
  const createdResources = {};

  for (const [routePath, routeConfig] of Object.entries(ROUTES)) {
    const parts = routePath.split("/").filter(Boolean);
    let parentId = rootId;

    // Create nested resources
    for (let i = 0; i < parts.length; i++) {
      const partPath = "/" + parts.slice(0, i + 1).join("/");
      if (createdResources[partPath]) {
        parentId = createdResources[partPath];
        continue;
      }

      try {
        const resource = await apigateway.send(
          new CreateResourceCommand({
            restApiId,
            parentId,
            pathPart: parts[i],
          })
        );
        createdResources[partPath] = resource.id;
        parentId = resource.id;
      } catch (error) {
        if (error.name === "ConflictException") {
          // Resource already exists, find it
          const allResources = await apigateway.send(
            new GetResourcesCommand({ restApiId })
          );
          const existing = allResources.items.find(
            (r) => r.path === partPath
          );
          if (existing) {
            createdResources[partPath] = existing.id;
            parentId = existing.id;
          }
        } else {
          throw error;
        }
      }
    }

    const resourceId = createdResources[routePath];
    const lambdaArn = await getLambdaArn(routeConfig.lambda);

    // Create methods
    for (const method of routeConfig.methods) {
      try {
        const methodParams = {
          restApiId,
          resourceId,
          httpMethod: method,
          authorizationType: routeConfig.auth ? "COGNITO_USER_POOLS" : "NONE",
        };
        if (routeConfig.auth) {
          methodParams.authorizerId = authorizerId;
        }

        await apigateway.send(new PutMethodCommand(methodParams));

        // Lambda proxy integration
        await apigateway.send(
          new PutIntegrationCommand({
            restApiId,
            resourceId,
            httpMethod: method,
            type: "AWS_PROXY",
            integrationHttpMethod: "POST",
            uri: `arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${lambdaArn}/invocations`,
          })
        );

        console.log(
          `    ${method} ${routePath} -> ${routeConfig.lambda} ${routeConfig.auth ? "(auth)" : "(public)"}`
        );
      } catch (error) {
        console.error(
          `    [error] ${method} ${routePath}: ${error.message}`
        );
      }
    }

    // Add OPTIONS for CORS
    try {
      await apigateway.send(
        new PutMethodCommand({
          restApiId,
          resourceId,
          httpMethod: "OPTIONS",
          authorizationType: "NONE",
        })
      );
      await apigateway.send(
        new PutIntegrationCommand({
          restApiId,
          resourceId,
          httpMethod: "OPTIONS",
          type: "MOCK",
          requestTemplates: {
            "application/json": '{"statusCode": 200}',
          },
        })
      );
      await apigateway.send(
        new PutMethodResponseCommand({
          restApiId,
          resourceId,
          httpMethod: "OPTIONS",
          statusCode: "200",
          responseParameters: {
            "method.response.header.Access-Control-Allow-Headers": false,
            "method.response.header.Access-Control-Allow-Methods": false,
            "method.response.header.Access-Control-Allow-Origin": false,
          },
        })
      );
      await apigateway.send(
        new PutIntegrationResponseCommand({
          restApiId,
          resourceId,
          httpMethod: "OPTIONS",
          statusCode: "200",
          responseParameters: {
            "method.response.header.Access-Control-Allow-Headers":
              "'Content-Type,Authorization'",
            "method.response.header.Access-Control-Allow-Methods":
              "'GET,POST,PUT,PATCH,DELETE,OPTIONS'",
            "method.response.header.Access-Control-Allow-Origin": "'*'",
          },
        })
      );
    } catch {
      // OPTIONS may already exist
    }

    // Grant API Gateway permission to invoke Lambda
    try {
      await lambdaClient.send(
        new AddPermissionCommand({
          FunctionName: routeConfig.lambda,
          StatementId: `apigateway-${routePath.replace(/\//g, "-")}-${Date.now()}`,
          Action: "lambda:InvokeFunction",
          Principal: "apigateway.amazonaws.com",
          SourceArn: `arn:aws:execute-api:${REGION}:${accountId}:${restApiId}/*`,
        })
      );
    } catch {
      // Permission may already exist
    }
  }

  // 5. Deploy to stage
  console.log(`\n  Deploying to stage: ${STAGE_NAME}...`);
  await apigateway.send(
    new CreateDeploymentCommand({
      restApiId,
      stageName: STAGE_NAME,
      description: "Initial deployment",
    })
  );

  const apiUrl = `https://${restApiId}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}`;

  // Save API URL to config
  config.apiUrl = apiUrl;
  config.restApiId = restApiId;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

  console.log("\n==============================================");
  console.log("  API GATEWAY DEPLOYED SUCCESSFULLY");
  console.log("==============================================");
  console.log(`\n  API URL: ${apiUrl}`);
  console.log(`\n  Test: curl ${apiUrl}/auth/login`);
  console.log(
    "\n  Update Flutter app_url.dart with this base URL."
  );
}

deploy().catch(console.error);
