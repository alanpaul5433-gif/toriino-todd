const { APIGatewayClient, PutGatewayResponseCommand, CreateDeploymentCommand } = require("@aws-sdk/client-api-gateway");

const client = new APIGatewayClient({ region: "us-east-1" });
const API_ID = "pq8cu94cfd";

async function run() {
  const corsParams = {
    "gatewayresponse.header.Access-Control-Allow-Origin": "'*'",
    "gatewayresponse.header.Access-Control-Allow-Headers": "'Content-Type,Authorization'",
    "gatewayresponse.header.Access-Control-Allow-Methods": "'GET,POST,PUT,DELETE,OPTIONS'",
  };

  for (const type of ["UNAUTHORIZED", "ACCESS_DENIED"]) {
    await client.send(new PutGatewayResponseCommand({
      restApiId: API_ID,
      responseType: type,
      responseParameters: corsParams,
      statusCode: type === "UNAUTHORIZED" ? "401" : "403",
    }));
    console.log(`[done] Gateway response CORS for ${type}`);
  }

  await client.send(new CreateDeploymentCommand({
    restApiId: API_ID,
    stageName: "prod",
    description: "Add CORS headers to 401/403 responses",
  }));
  console.log("[done] Redeployed to prod");
  console.log("\n✓ 401/403 responses now include CORS headers — browser will show proper errors instead of 'Failed to fetch'");
}

run().catch(console.error);
