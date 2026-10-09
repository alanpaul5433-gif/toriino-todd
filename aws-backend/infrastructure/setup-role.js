/**
 * Creates toriino-lambda-role and updates aws-config.json
 */
const { IAMClient, CreateRoleCommand, AttachRolePolicyCommand, GetRoleCommand } = require("@aws-sdk/client-iam");
const { CognitoIdentityProviderClient, ListUserPoolClientsCommand } = require("@aws-sdk/client-cognito-identity-provider");
const fs = require("fs");
const path = require("path");

const iam = new IAMClient({ region: "us-east-1" });
const cognito = new CognitoIdentityProviderClient({ region: "us-east-1" });

const POOL_ID = "us-east-1_CAiea51iC";
const configPath = path.join(__dirname, "aws-config.json");

async function main() {
  console.log("\n  Setting up Lambda role and Cognito config...\n");

  // 1. Get or create Lambda role
  let roleArn = "";
  try {
    const r = await iam.send(new GetRoleCommand({ RoleName: "toriino-lambda-role" }));
    roleArn = r.Role.Arn;
    console.log(`  [found] Lambda role: ${roleArn}`);
  } catch {
    console.log("  Creating toriino-lambda-role...");
    const r = await iam.send(new CreateRoleCommand({
      RoleName: "toriino-lambda-role",
      AssumeRolePolicyDocument: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{ Effect: "Allow", Principal: { Service: "lambda.amazonaws.com" }, Action: "sts:AssumeRole" }],
      }),
      Description: "Execution role for Toriino Lambda functions",
    }));
    roleArn = r.Role.Arn;
    console.log(`  [created] ${roleArn}`);

    // Attach policies
    const policies = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
      "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
      "arn:aws:iam::aws:policy/AmazonS3FullAccess",
      "arn:aws:iam::aws:policy/AmazonCognitoPowerUser",
      "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess",
    ];
    for (const p of policies) {
      await iam.send(new AttachRolePolicyCommand({ RoleName: "toriino-lambda-role", PolicyArn: p }));
    }
    console.log("  [ok] Policies attached");
  }

  // 2. Get Cognito app client ID
  let clientId = "";
  try {
    const r = await cognito.send(new ListUserPoolClientsCommand({ UserPoolId: POOL_ID, MaxResults: 10 }));
    const client = r.UserPoolClients?.[0];
    if (client) {
      clientId = client.ClientId;
      console.log(`  [found] Cognito client: ${clientId} (${client.ClientName})`);
    }
  } catch (e) {
    console.warn(`  [warn] Could not get client ID: ${e.message}`);
  }

  // 3. Update config
  const config = fs.existsSync(configPath) ? JSON.parse(fs.readFileSync(configPath, "utf8")) : {};
  config.lambdaRoleArn = roleArn;
  config.cognitoUserPoolId = POOL_ID;
  config.cognitoClientId = clientId;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

  console.log("\n  aws-config.json updated:");
  console.log(`    lambdaRoleArn     : ${roleArn}`);
  console.log(`    cognitoUserPoolId : ${POOL_ID}`);
  console.log(`    cognitoClientId   : ${clientId}`);
  console.log("\n  Done! Now run:");
  console.log("    node infrastructure/deploy-ai.js --gemini-key=YOUR_KEY\n");
}

main().catch(e => { console.error(e.message); process.exit(1); });
