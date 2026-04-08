/**
 * Toriino Todd — Lambda Deployment Script
 *
 * Zips and deploys each Lambda function to AWS.
 * Reads config from aws-config.json (created by deploy.js).
 *
 * Usage: node deploy-lambdas.js
 */

const {
  LambdaClient,
  CreateFunctionCommand,
  UpdateFunctionCodeCommand,
  GetFunctionCommand,
  UpdateFunctionConfigurationCommand,
} = require("@aws-sdk/client-lambda");

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const REGION = "us-east-2";
const PROJECT_PREFIX = "toriino";
const lambda = new LambdaClient({ region: REGION });

// Load config from deploy.js output
const configPath = path.join(__dirname, "aws-config.json");
if (!fs.existsSync(configPath)) {
  console.error("aws-config.json not found. Run deploy.js first.");
  process.exit(1);
}
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

const LAMBDA_FUNCTIONS = [
  {
    name: `${PROJECT_PREFIX}-auth`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "auth"),
    timeout: 15,
    memorySize: 256,
    envVars: {
      COGNITO_USER_POOL_ID: config.cognitoUserPoolId,
      COGNITO_CLIENT_ID: config.cognitoClientId,
    },
  },
  {
    name: `${PROJECT_PREFIX}-users`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "users"),
    timeout: 10,
    memorySize: 256,
    envVars: {
      USERS_TABLE: `${PROJECT_PREFIX}-users`,
      S3_BUCKET: config.s3Bucket,
    },
  },
  {
    name: `${PROJECT_PREFIX}-courses`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "courses"),
    timeout: 10,
    memorySize: 256,
    envVars: {
      COURSES_TABLE: `${PROJECT_PREFIX}-courses`,
      LESSONS_TABLE: `${PROJECT_PREFIX}-course-lessons`,
      ENROLLMENTS_TABLE: `${PROJECT_PREFIX}-enrollments`,
    },
  },
  {
    name: `${PROJECT_PREFIX}-sessions`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "sessions"),
    timeout: 10,
    memorySize: 256,
    envVars: {
      SESSIONS_TABLE: `${PROJECT_PREFIX}-sessions`,
    },
  },
  {
    name: `${PROJECT_PREFIX}-mentors`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "mentors"),
    timeout: 10,
    memorySize: 256,
    envVars: {
      MENTORS_TABLE: `${PROJECT_PREFIX}-mentors`,
      AVAILABILITY_TABLE: `${PROJECT_PREFIX}-availability`,
      S3_BUCKET: config.s3Bucket,
    },
  },
  {
    name: `${PROJECT_PREFIX}-reviews`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "reviews"),
    timeout: 10,
    memorySize: 128,
    envVars: {
      REVIEWS_TABLE: `${PROJECT_PREFIX}-reviews`,
    },
  },
  {
    name: `${PROJECT_PREFIX}-notifications`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "notifications"),
    timeout: 10,
    memorySize: 128,
    envVars: {
      NOTIFICATIONS_TABLE: `${PROJECT_PREFIX}-notifications`,
    },
  },
  {
    name: `${PROJECT_PREFIX}-earnings`,
    handler: "index.handler",
    dir: path.join(__dirname, "..", "lambda", "earnings"),
    timeout: 10,
    memorySize: 128,
    envVars: {
      EARNINGS_TABLE: `${PROJECT_PREFIX}-earnings`,
    },
  },
];

async function functionExists(functionName) {
  try {
    await lambda.send(
      new GetFunctionCommand({ FunctionName: functionName })
    );
    return true;
  } catch {
    return false;
  }
}

function zipLambda(dir, functionName) {
  const zipPath = path.join(__dirname, `${functionName}.zip`);

  // Use PowerShell Compress-Archive on Windows
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".js"));
  const filePaths = files.map((f) => path.join(dir, f)).join('","');

  execSync(
    `powershell -Command "Compress-Archive -Path '${filePaths}' -DestinationPath '${zipPath}' -Force"`,
    { stdio: "inherit" }
  );

  return fs.readFileSync(zipPath);
}

async function deployLambda(funcConfig) {
  const { name, handler, dir, timeout, memorySize, envVars } = funcConfig;
  const exists = await functionExists(name);

  console.log(
    `  ${exists ? "[updating]" : "[creating]"} ${name}...`
  );

  const zipBuffer = zipLambda(dir, name);

  if (exists) {
    await lambda.send(
      new UpdateFunctionCodeCommand({
        FunctionName: name,
        ZipFile: zipBuffer,
      })
    );
    await lambda.send(
      new UpdateFunctionConfigurationCommand({
        FunctionName: name,
        Environment: { Variables: envVars },
        Timeout: timeout,
        MemorySize: memorySize,
      })
    );
  } else {
    await lambda.send(
      new CreateFunctionCommand({
        FunctionName: name,
        Runtime: "nodejs20.x",
        Role: config.lambdaRoleArn,
        Handler: handler,
        Code: { ZipFile: zipBuffer },
        Timeout: timeout,
        MemorySize: memorySize,
        Environment: { Variables: envVars },
      })
    );
  }

  console.log(`  [done] ${name}`);
}

async function deployAll() {
  console.log("\n==============================================");
  console.log("  TORIINO — Deploying Lambda Functions");
  console.log("==============================================\n");

  for (const func of LAMBDA_FUNCTIONS) {
    try {
      await deployLambda(func);
    } catch (error) {
      console.error(`  [error] ${func.name}: ${error.message}`);
    }
  }

  console.log("\n  All Lambda functions deployed.");
  console.log("  Next: Run deploy-api.js to set up API Gateway.\n");
}

deployAll().catch(console.error);
