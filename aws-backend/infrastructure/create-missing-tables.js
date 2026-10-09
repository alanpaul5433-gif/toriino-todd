/**
 * Creates the DynamoDB tables that are missing:
 * toriino-reviews, toriino-enrollments, toriino-notifications
 */
const { DynamoDBClient, CreateTableCommand, DescribeTableCommand } = require("@aws-sdk/client-dynamodb");
const db = new DynamoDBClient({ region: "us-east-1" });

const TABLES = [
  {
    TableName: "toriino-reviews",
    KeySchema: [{ AttributeName: "targetId", KeyType: "HASH" }, { AttributeName: "reviewId", KeyType: "RANGE" }],
    AttributeDefinitions: [{ AttributeName: "targetId", AttributeType: "S" }, { AttributeName: "reviewId", AttributeType: "S" }],
    BillingMode: "PAY_PER_REQUEST",
  },
  {
    TableName: "toriino-enrollments",
    KeySchema: [{ AttributeName: "enrollmentId", KeyType: "HASH" }],
    AttributeDefinitions: [{ AttributeName: "enrollmentId", AttributeType: "S" }],
    BillingMode: "PAY_PER_REQUEST",
  },
  {
    TableName: "toriino-notifications",
    KeySchema: [{ AttributeName: "userId", KeyType: "HASH" }, { AttributeName: "sortKey", KeyType: "RANGE" }],
    AttributeDefinitions: [{ AttributeName: "userId", AttributeType: "S" }, { AttributeName: "sortKey", AttributeType: "S" }],
    BillingMode: "PAY_PER_REQUEST",
  },
];

async function main() {
  console.log("\n  Creating missing DynamoDB tables...\n");
  for (const table of TABLES) {
    try {
      await db.send(new DescribeTableCommand({ TableName: table.TableName }));
      console.log(`  [found]   ${table.TableName}`);
    } catch {
      await db.send(new CreateTableCommand(table));
      console.log(`  [created] ${table.TableName}`);
    }
  }
  console.log("\n  Done!\n");
}

main().catch(e => { console.error(e.message); process.exit(1); });
