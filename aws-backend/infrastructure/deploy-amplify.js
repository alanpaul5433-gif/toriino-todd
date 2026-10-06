/**
 * Deploys the Toriino Admin Panel to AWS Amplify Hosting
 *
 * Usage: node deploy-amplify.js
 *
 * Creates an Amplify app connected to the GitHub repo,
 * sets environment variables, and triggers first deployment.
 */

const {
  AmplifyClient,
  CreateAppCommand,
  CreateBranchCommand,
  StartJobCommand,
  GetJobCommand,
  ListAppsCommand,
} = require("@aws-amplify/client-amplify");

const { STSClient, GetCallerIdentityCommand } = require("@aws-sdk/client-sts");
const fs = require("fs");
const path = require("path");

const REGION = "us-east-1";
const GITHUB_REPO = "https://github.com/alanpaul5433-gif/toriino-todd";
const BRANCH = "master";

const amplify = new AmplifyClient({ region: REGION });
const sts = new STSClient({ region: REGION });

const configPath = path.join(__dirname, "aws-config.json");
const config = fs.existsSync(configPath) ? JSON.parse(fs.readFileSync(configPath, "utf8")) : {};

async function main() {
  console.log("==============================================");
  console.log("  TORIINO — Deploy Admin Panel to AWS Amplify");
  console.log("==============================================\n");

  const identity = await sts.send(new GetCallerIdentityCommand({}));
  console.log(`  Account: ${identity.Account}\n`);

  // Check if app already exists
  const existing = await amplify.send(new ListAppsCommand({ maxResults: 100 }));
  const existingApp = existing.apps?.find(a => a.name === "toriino-admin");

  if (existingApp) {
    console.log(`  [found] Amplify app already exists: ${existingApp.appId}`);
    console.log(`  URL: https://${BRANCH}.${existingApp.defaultDomain}`);
    console.log("\n  To redeploy, push to GitHub and Amplify will auto-deploy.\n");
    return;
  }

  // Create Amplify app
  console.log("  Creating Amplify app...");
  const app = await amplify.send(new CreateAppCommand({
    name: "toriino-admin",
    platform: "WEB_COMPUTE", // SSR support for Next.js
    repository: GITHUB_REPO,
    environmentVariables: {
      NEXT_PUBLIC_API_BASE: "https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod",
      NEXT_PUBLIC_COGNITO_REGION: "us-east-1",
      NEXT_PUBLIC_COGNITO_USER_POOL_ID: config.cognitoUserPoolId || "us-east-1_CAiea51iC",
      NEXT_PUBLIC_COGNITO_CLIENT_ID: config.cognitoClientId || "jcpvch4o651070m0a2jvuhh22",
      _LIVE_UPDATES: JSON.stringify([{ name: "Next.js version", pkg: "next-version", type: "internal", version: "latest" }]),
    },
    buildSpec: `version: 1
frontend:
  phases:
    preBuild:
      commands:
        - cd admin-panel && npm install
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: admin-panel/.next
    files:
      - '**/*'
  cache:
    paths:
      - admin-panel/node_modules/**/*`,
    customRules: [
      { source: "/<*>", target: "/index.html", status: "404-200" },
    ],
  }));

  const appId = app.app.appId;
  console.log(`  [created] App ID: ${appId}`);

  // Create branch
  await amplify.send(new CreateBranchCommand({
    appId,
    branchName: BRANCH,
    framework: "Next.js - SSR",
    stage: "PRODUCTION",
  }));
  console.log(`  [created] Branch: ${BRANCH}`);

  const appUrl = `https://${BRANCH}.${app.app.defaultDomain}`;
  console.log("\n==============================================");
  console.log("  AMPLIFY APP CREATED");
  console.log("==============================================");
  console.log(`\n  App ID  : ${appId}`);
  console.log(`  URL     : ${appUrl}`);
  console.log("\n  IMPORTANT: Connect GitHub to allow Amplify to deploy.");
  console.log("  Go to: https://console.aws.amazon.com/amplify");
  console.log(`  → Select 'toriino-admin' → Connect repository → GitHub\n`);
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
