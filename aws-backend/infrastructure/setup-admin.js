/**
 * Toriino Todd — Admin User Setup Script
 *
 * Creates the 'Admins' Cognito group and adds a user to it.
 * Run this once to set up admin access for the web admin panel.
 *
 * Usage:
 *   node setup-admin.js --email=admin@example.com --password=TempPass123!
 *   node setup-admin.js --add-existing --email=existing@example.com
 *
 * Flags:
 *   --email=<email>       Email for the admin user (required)
 *   --password=<pass>     Temporary password for new user (required unless --add-existing)
 *   --add-existing        Add an already-existing Cognito user to Admins group
 *   --pool-id=<id>        Override Cognito User Pool ID (reads aws-config.json otherwise)
 */

const {
  CognitoIdentityProviderClient,
  CreateGroupCommand,
  GetGroupCommand,
  AdminCreateUserCommand,
  AdminAddUserToGroupCommand,
  ListUsersCommand,
  AdminSetUserPasswordCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const fs = require("fs");
const path = require("path");

const REGION = "us-east-1";
const cognito = new CognitoIdentityProviderClient({ region: REGION });

// Parse CLI flags
const args = process.argv.slice(2);
const flag = (name) => {
  const f = args.find((a) => a.startsWith(`--${name}=`));
  return f ? f.split("=").slice(1).join("=") : null;
};
const hasFlag = (name) => args.includes(`--${name}`);

const emailArg = flag("email");
const passwordArg = flag("password");
const addExisting = hasFlag("add-existing");
const poolIdArg = flag("pool-id");

// Load pool ID from config
const configPath = path.join(__dirname, "aws-config.json");
const config = fs.existsSync(configPath) ? JSON.parse(fs.readFileSync(configPath, "utf8")) : {};
const USER_POOL_ID = poolIdArg || config.cognitoUserPoolId || process.env.COGNITO_USER_POOL_ID;

if (!USER_POOL_ID) {
  console.error("\n  [error] Could not find Cognito User Pool ID.");
  console.error("  Run deploy.js first, or pass --pool-id=us-east-1_XXXXXXXX\n");
  process.exit(1);
}

if (!emailArg) {
  console.error("\n  [error] --email flag is required.\n");
  console.error("  Usage: node setup-admin.js --email=admin@example.com --password=TempPass123!\n");
  process.exit(1);
}

async function ensureAdminsGroup() {
  try {
    await cognito.send(new GetGroupCommand({ GroupName: "Admins", UserPoolId: USER_POOL_ID }));
    console.log("  [ok] Admins group already exists");
  } catch (e) {
    if (e.name === "ResourceNotFoundException") {
      await cognito.send(new CreateGroupCommand({
        GroupName: "Admins",
        UserPoolId: USER_POOL_ID,
        Description: "Platform administrators — access to the Toriino Admin Panel",
      }));
      console.log("  [created] Admins group");
    } else {
      throw e;
    }
  }
}

async function findUserByEmail(email) {
  const r = await cognito.send(new ListUsersCommand({
    UserPoolId: USER_POOL_ID,
    Filter: `email = "${email}"`,
    Limit: 1,
  }));
  return r.Users?.[0] || null;
}

async function createUser(email, password) {
  const existing = await findUserByEmail(email);
  if (existing) {
    console.log(`  [ok] User ${email} already exists (username: ${existing.Username})`);
    return existing.Username;
  }

  const r = await cognito.send(new AdminCreateUserCommand({
    UserPoolId: USER_POOL_ID,
    Username: email,
    TemporaryPassword: password,
    UserAttributes: [
      { Name: "email", Value: email },
      { Name: "email_verified", Value: "true" },
      { Name: "name", Value: email.split("@")[0] },
    ],
    MessageAction: "SUPPRESS", // don't send welcome email
  }));
  const username = r.User.Username;
  console.log(`  [created] User: ${email} (username: ${username})`);

  // Set permanent password so user doesn't have to change it on first login
  await cognito.send(new AdminSetUserPasswordCommand({
    UserPoolId: USER_POOL_ID,
    Username: username,
    Password: password,
    Permanent: true,
  }));
  console.log("  [ok] Password set as permanent");

  return username;
}

async function addToAdmins(username) {
  await cognito.send(new AdminAddUserToGroupCommand({
    UserPoolId: USER_POOL_ID,
    Username: username,
    GroupName: "Admins",
  }));
  console.log(`  [ok] Added ${username} to Admins group`);
}

async function main() {
  console.log("==============================================");
  console.log("  TORIINO — Admin User Setup");
  console.log("==============================================\n");
  console.log(`  Pool ID : ${USER_POOL_ID}`);
  console.log(`  Region  : ${REGION}`);
  console.log(`  Email   : ${emailArg}\n`);

  // 1. Ensure Admins group exists
  await ensureAdminsGroup();

  // 2. Create or find user
  let username;
  if (addExisting) {
    const user = await findUserByEmail(emailArg);
    if (!user) {
      console.error(`  [error] No user found with email ${emailArg}`);
      process.exit(1);
    }
    username = user.Username;
    console.log(`  [found] Existing user: ${username}`);
  } else {
    if (!passwordArg) {
      console.error("\n  [error] --password flag is required when creating a new user.");
      console.error("  Or use --add-existing to add an existing user.\n");
      process.exit(1);
    }
    username = await createUser(emailArg, passwordArg);
  }

  // 3. Add to Admins group
  await addToAdmins(username);

  console.log("\n==============================================");
  console.log("  DONE — Admin user is ready");
  console.log("==============================================");
  console.log(`\n  Email    : ${emailArg}`);
  if (!addExisting) {
    console.log(`  Password : ${passwordArg}`);
  }
  console.log("\n  Sign in at your admin panel URL.");
  console.log("  Make sure admin-panel/.env.local has:");
  console.log(`    NEXT_PUBLIC_COGNITO_USER_POOL_ID=${USER_POOL_ID}`);
  console.log("    NEXT_PUBLIC_COGNITO_CLIENT_ID=<your app client id>");
  console.log("\n  Find client ID: AWS Console → Cognito → User Pools → App clients\n");
}

main().catch((e) => {
  console.error(`\n  [fatal] ${e.message}\n`);
  process.exit(1);
});
