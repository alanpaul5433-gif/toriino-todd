/**
 * Enables USER_PASSWORD_AUTH on the Cognito App Client
 */
const { CognitoIdentityProviderClient, UpdateUserPoolClientCommand } = require("@aws-sdk/client-cognito-identity-provider");

const cognito = new CognitoIdentityProviderClient({ region: "us-east-1" });

const USER_POOL_ID = "us-east-1_CAiea51iC";
const CLIENT_ID = "jcpvch4o651070m0a2jvuhh22";

async function main() {
  console.log("\n  Enabling USER_PASSWORD_AUTH on Cognito app client...\n");

  await cognito.send(new UpdateUserPoolClientCommand({
    UserPoolId: USER_POOL_ID,
    ClientId: CLIENT_ID,
    ExplicitAuthFlows: [
      "ALLOW_USER_PASSWORD_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH",
      "ALLOW_USER_SRP_AUTH",
    ],
  }));

  console.log("  [ok] Done! Try signing in again at http://localhost:3001\n");
}

main().catch(e => { console.error(e.message); process.exit(1); });
