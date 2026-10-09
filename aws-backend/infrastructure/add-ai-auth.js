/**
 * Applies the existing CognitoAdminAuth authorizer to all AI routes:
 *   /ai/*, /sessions/*, /ai/memory/*
 * These routes need Cognito auth so the Lambda can read userId from
 * event.requestContext.authorizer.claims.sub
 *
 * Usage: node infrastructure/add-ai-auth.js
 */

const {
  APIGatewayClient,
  GetAuthorizersCommand,
  GetResourcesCommand,
  GetMethodCommand,
  UpdateMethodCommand,
  CreateDeploymentCommand,
} = require("@aws-sdk/client-api-gateway");

const REGION = "us-east-1";
const API_ID = "pq8cu94cfd";
const STAGE  = "prod";

const apig = new APIGatewayClient({ region: REGION });

const AI_PATH_PREFIXES = ["/ai/", "/sessions/"];

async function getAuthorizerId() {
  const r = await apig.send(new GetAuthorizersCommand({ restApiId: API_ID }));
  const found = r.items?.find(a => a.name === "CognitoAdminAuth");
  if (!found) throw new Error("CognitoAdminAuth authorizer not found — run add-admin-auth.js first");
  console.log(`  [found]   Authorizer: ${found.id} (${found.name})`);
  return found.id;
}

async function getAllResources() {
  let position, resources = [];
  do {
    const r = await apig.send(new GetResourcesCommand({ restApiId: API_ID, limit: 500, ...(position ? { position } : {}) }));
    resources.push(...(r.items || []));
    position = r.position;
  } while (position);
  return resources.filter(r => AI_PATH_PREFIXES.some(prefix => r.path?.startsWith(prefix)));
}

async function applyAuthorizer(authorizerId, resources) {
  const HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH"];
  let updated = 0;

  for (const resource of resources) {
    for (const method of HTTP_METHODS) {
      try {
        const m = await apig.send(new GetMethodCommand({ restApiId: API_ID, resourceId: resource.id, httpMethod: method }));
        if (m.authorizationType === "COGNITO_USER_POOLS") {
          console.log(`  [skip]    ${method.padEnd(7)} ${resource.path} — already secured`);
          continue;
        }
      } catch { continue; }

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
        console.log(`  [warn]    ${method.padEnd(7)} ${resource.path} — ${e.message}`);
      }
    }
  }
  return updated;
}

async function main() {
  console.log("\n================================================");
  console.log("  TORIINO — Add Cognito Auth to AI routes");
  console.log("================================================\n");

  console.log("  Step 1: Looking up Cognito authorizer...");
  const authorizerId = await getAuthorizerId();

  console.log("\n  Step 2: Finding AI resources...");
  const resources = await getAllResources();
  console.log(`  [found]   ${resources.length} resources under /ai/* and /sessions/*`);

  console.log("\n  Step 3: Applying authorizer...");
  const updated = await applyAuthorizer(authorizerId, resources);

  console.log("\n  Step 4: Redeploying...");
  await apig.send(new CreateDeploymentCommand({ restApiId: API_ID, stageName: STAGE, description: "Added Cognito auth to AI routes" }));
  console.log("  [ok]      Redeployed to prod");

  console.log("\n================================================");
  console.log("  DONE");
  console.log(`\n  ${updated} AI methods secured with Cognito auth.\n`);
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
