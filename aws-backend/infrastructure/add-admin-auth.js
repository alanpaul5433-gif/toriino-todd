/**
 * Adds a Cognito User Pool Authorizer to all /admin/* routes on API Gateway.
 * Redeploys to prod when done.
 *
 * Usage: node infrastructure/add-admin-auth.js
 */

const {
  APIGatewayClient,
  GetAuthorizersCommand,
  CreateAuthorizerCommand,
  GetResourcesCommand,
  GetMethodCommand,
  UpdateMethodCommand,
  CreateDeploymentCommand,
} = require("@aws-sdk/client-api-gateway");

const REGION     = "us-east-1";
const API_ID     = "pq8cu94cfd";
const USER_POOL  = "us-east-1_CAiea51iC";
const STAGE      = "prod";

const apig = new APIGatewayClient({ region: REGION });

// ─── 1. Ensure authorizer exists ──────────────────────────────────────────────

async function ensureAuthorizer() {
  const existing = await apig.send(new GetAuthorizersCommand({ restApiId: API_ID }));
  const found = existing.items?.find(a => a.name === "CognitoAdminAuth");
  if (found) {
    console.log(`  [found]   Authorizer: ${found.id} (${found.name})`);
    return found.id;
  }

  const created = await apig.send(new CreateAuthorizerCommand({
    restApiId: API_ID,
    name: "CognitoAdminAuth",
    type: "COGNITO_USER_POOLS",
    providerARNs: [`arn:aws:cognito-idp:${REGION}:888245942659:userpool/${USER_POOL}`],
    identitySource: "method.request.header.Authorization",
    authorizerResultTtlInSeconds: 300,
  }));

  console.log(`  [created] Authorizer: ${created.id} (CognitoAdminAuth)`);
  return created.id;
}

// ─── 2. Get all /admin resources ──────────────────────────────────────────────

async function getAdminResources() {
  let position, resources = [];
  do {
    const r = await apig.send(new GetResourcesCommand({
      restApiId: API_ID,
      limit: 500,
      ...(position ? { position } : {}),
    }));
    resources.push(...(r.items || []));
    position = r.position;
  } while (position);

  return resources.filter(r => r.path?.startsWith("/admin"));
}

// ─── 3. Apply authorizer to each HTTP method on each resource ─────────────────

async function applyAuthorizer(authorizerId, resources) {
  const HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH"];
  let updated = 0, skipped = 0;

  for (const resource of resources) {
    for (const method of HTTP_METHODS) {
      // Check if method exists on this resource
      try {
        await apig.send(new GetMethodCommand({
          restApiId: API_ID,
          resourceId: resource.id,
          httpMethod: method,
        }));
      } catch {
        continue; // method doesn't exist on this resource
      }

      // Apply authorizer
      try {
        await apig.send(new UpdateMethodCommand({
          restApiId: API_ID,
          resourceId: resource.id,
          httpMethod: method,
          patchOperations: [
            { op: "replace", path: "/authorizationType", value: "COGNITO_USER_POOLS" },
            { op: "replace", path: "/authorizerId",      value: authorizerId },
          ],
        }));
        console.log(`  [secured] ${method.padEnd(7)} ${resource.path}`);
        updated++;
      } catch (e) {
        console.log(`  [skip]    ${method.padEnd(7)} ${resource.path} — ${e.message}`);
        skipped++;
      }
    }
  }

  return { updated, skipped };
}

// ─── 4. Redeploy ──────────────────────────────────────────────────────────────

async function redeploy() {
  await apig.send(new CreateDeploymentCommand({
    restApiId: API_ID,
    stageName: STAGE,
    description: "Added Cognito authorizer to /admin/* routes",
  }));
  console.log(`  [ok]      Redeployed to stage: ${STAGE}`);
}

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\n================================================");
  console.log("  TORIINO — Add Cognito Auth to /admin routes");
  console.log("================================================\n");

  console.log("  Step 1: Setting up Cognito authorizer...");
  const authorizerId = await ensureAuthorizer();

  console.log("\n  Step 2: Finding /admin/* resources...");
  const resources = await getAdminResources();
  console.log(`  [found]   ${resources.length} resources under /admin`);

  console.log("\n  Step 3: Applying authorizer to all methods...");
  const { updated, skipped } = await applyAuthorizer(authorizerId, resources);

  console.log("\n  Step 4: Redeploying API...");
  await redeploy();

  console.log("\n================================================");
  console.log("  DONE");
  console.log("================================================");
  console.log(`\n  Methods secured : ${updated}`);
  console.log(`  Methods skipped : ${skipped}`);
  console.log(`\n  All /admin/* routes now require a valid Cognito JWT.`);
  console.log(`  Unauthorized requests will receive 401 Unauthorized.\n`);
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
