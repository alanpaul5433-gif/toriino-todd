/**
 * Generates aws-config.json by reading existing AWS resources.
 * Run this instead of deploy.js when infrastructure already exists.
 *
 * Usage: node generate-config.js
 */

const { IAMClient, GetRoleCommand } = require("@aws-sdk/client-iam");
const { CognitoIdentityProviderClient, ListUserPoolsCommand } = require("@aws-sdk/client-cognito-identity-provider");
const { STSClient, GetCallerIdentityCommand } = require("@aws-sdk/client-sts");
const fs = require("fs");
const path = require("path");

const REGION = "us-east-1";
const iam = new IAMClient({ region: REGION });
const cognito = new CognitoIdentityProviderClient({ region: REGION });
const sts = new STSClient({ region: REGION });

async function main() {
  console.log("\n  Generating aws-config.json from existing AWS resources...\n");

  // Account ID
  const identity = await sts.send(new GetCallerIdentityCommand({}));
  const accountId = identity.Account;
  console.log(`  Account ID : ${accountId}`);

  // Lambda role ARN
  let lambdaRoleArn = "";
  try {
    const role = await iam.send(new GetRoleCommand({ RoleName: "toriino-lambda-role" }));
    lambdaRoleArn = role.Role.Arn;
    console.log(`  Lambda Role: ${lambdaRoleArn}`);
  } catch {
    console.warn("  [warn] toriino-lambda-role not found — will be empty");
  }

  // Cognito User Pool
  let cognitoUserPoolId = "";
  let cognitoClientId = "";
  try {
    const pools = await cognito.send(new ListUserPoolsCommand({ MaxResults: 60 }));
    const pool = pools.UserPools.find(p => p.Name === "toriino-user-pool" || p.Name.toLowerCase().includes("toriino"));
    if (pool) {
      cognitoUserPoolId = pool.Id;
      console.log(`  Cognito Pool: ${cognitoUserPoolId}`);
    } else {
      console.warn("  [warn] No toriino Cognito user pool found");
      console.log("  Available pools:", pools.UserPools.map(p => `${p.Id} (${p.Name})`).join(", ") || "none");
    }
  } catch (e) {
    console.warn(`  [warn] Could not list Cognito pools: ${e.message}`);
  }

  const config = {
    accountId,
    lambdaRoleArn,
    cognitoUserPoolId,
    cognitoClientId,
    restApiId: "pq8cu94cfd",
    apiUrl: "https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod",
    region: REGION,
  };

  const configPath = path.join(__dirname, "aws-config.json");
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

  console.log("\n  aws-config.json created:");
  console.log(JSON.stringify(config, null, 4));
  console.log("\n  Done! Now run:");
  console.log("    node infrastructure/deploy-ai.js --gemini-key=YOUR_KEY\n");
}

main().catch(e => { console.error(e.message); process.exit(1); });
