/**
 * Toriino Todd — AWS Infrastructure Deployment Script
 *
 * Deploys all AWS resources:
 *  - Cognito User Pool (auth)
 *  - DynamoDB Tables (12 tables)
 *  - S3 Bucket (file uploads)
 *  - Lambda Functions (per domain)
 *  - API Gateway (REST)
 *
 * Usage: node deploy.js
 * Prerequisites: AWS CLI configured with valid credentials
 */

const {
  CognitoIdentityProviderClient,
  CreateUserPoolCommand,
  CreateUserPoolClientCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const {
  DynamoDBClient,
  CreateTableCommand,
  DescribeTableCommand,
} = require("@aws-sdk/client-dynamodb");

const {
  S3Client,
  CreateBucketCommand,
  PutBucketCorsCommand,
} = require("@aws-sdk/client-s3");

const {
  IAMClient,
  CreateRoleCommand,
  AttachRolePolicyCommand,
} = require("@aws-sdk/client-iam");

const {
  LambdaClient,
  CreateFunctionCommand,
} = require("@aws-sdk/client-lambda");

const {
  APIGatewayClient,
  CreateRestApiCommand,
} = require("@aws-sdk/client-api-gateway");

const fs = require("fs");
const path = require("path");

const REGION = "us-east-2";
const PROJECT_PREFIX = "toriino";

const cognito = new CognitoIdentityProviderClient({ region: REGION });
const dynamodb = new DynamoDBClient({ region: REGION });
const s3 = new S3Client({ region: REGION });
const iam = new IAMClient({ region: REGION });
const lambda = new LambdaClient({ region: REGION });
const apigateway = new APIGatewayClient({ region: REGION });

// ============================================================
// 1. COGNITO USER POOL
// ============================================================
async function createCognitoUserPool() {
  console.log("\n📦 Creating Cognito User Pool...");

  try {
    const result = await cognito.send(
      new CreateUserPoolCommand({
        PoolName: `${PROJECT_PREFIX}-user-pool`,
        AutoVerifiedAttributes: ["email"],
        UsernameAttributes: ["email"],
        Schema: [
          {
            Name: "email",
            Required: true,
            Mutable: true,
            AttributeDataType: "String",
          },
          {
            Name: "name",
            Required: true,
            Mutable: true,
            AttributeDataType: "String",
          },
          {
            Name: "role",
            Mutable: true,
            AttributeDataType: "String",
            StringAttributeConstraints: { MinLength: "1", MaxLength: "20" },
          },
        ],
        Policies: {
          PasswordPolicy: {
            MinimumLength: 8,
            RequireUppercase: true,
            RequireLowercase: true,
            RequireNumbers: true,
            RequireSymbols: false,
          },
        },
        AccountRecoverySetting: {
          RecoveryMechanisms: [{ Priority: 1, Name: "verified_email" }],
        },
        EmailConfiguration: {
          EmailSendingAccount: "COGNITO_DEFAULT",
        },
        VerificationMessageTemplate: {
          DefaultEmailOption: "CONFIRM_WITH_CODE",
          EmailSubject: "Toriino - Verify your email",
          EmailMessage: "Your verification code is {####}",
        },
      })
    );

    const userPoolId = result.UserPool.Id;
    console.log(`  User Pool ID: ${userPoolId}`);

    // Create App Client
    const clientResult = await cognito.send(
      new CreateUserPoolClientCommand({
        UserPoolId: userPoolId,
        ClientName: `${PROJECT_PREFIX}-app-client`,
        GenerateSecret: false,
        ExplicitAuthFlows: [
          "ALLOW_USER_PASSWORD_AUTH",
          "ALLOW_REFRESH_TOKEN_AUTH",
          "ALLOW_USER_SRP_AUTH",
        ],
        AccessTokenValidity: 1, // 1 hour
        IdTokenValidity: 1,
        RefreshTokenValidity: 30, // 30 days
        TokenValidityUnits: {
          AccessToken: "hours",
          IdToken: "hours",
          RefreshToken: "days",
        },
      })
    );

    const clientId = clientResult.UserPoolClient.ClientId;
    console.log(`  App Client ID: ${clientId}`);

    return { userPoolId, clientId };
  } catch (error) {
    console.error("  Error creating Cognito User Pool:", error.message);
    throw error;
  }
}

// ============================================================
// 2. DYNAMODB TABLES
// ============================================================
const TABLE_DEFINITIONS = [
  {
    TableName: `${PROJECT_PREFIX}-users`,
    KeySchema: [{ AttributeName: "userId", KeyType: "HASH" }],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
      { AttributeName: "email", AttributeType: "S" },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: "email-index",
        KeySchema: [{ AttributeName: "email", KeyType: "HASH" }],
        Projection: { ProjectionType: "ALL" },
        ProvisionedThroughput: { ReadCapacityUnits: 5, WriteCapacityUnits: 5 },
      },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-courses`,
    KeySchema: [{ AttributeName: "courseId", KeyType: "HASH" }],
    AttributeDefinitions: [
      { AttributeName: "courseId", AttributeType: "S" },
      { AttributeName: "teacherId", AttributeType: "S" },
      { AttributeName: "category", AttributeType: "S" },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: "teacher-index",
        KeySchema: [{ AttributeName: "teacherId", KeyType: "HASH" }],
        Projection: { ProjectionType: "ALL" },
        ProvisionedThroughput: { ReadCapacityUnits: 5, WriteCapacityUnits: 5 },
      },
      {
        IndexName: "category-index",
        KeySchema: [{ AttributeName: "category", KeyType: "HASH" }],
        Projection: { ProjectionType: "ALL" },
        ProvisionedThroughput: { ReadCapacityUnits: 5, WriteCapacityUnits: 5 },
      },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-course-lessons`,
    KeySchema: [
      { AttributeName: "courseId", KeyType: "HASH" },
      { AttributeName: "lessonId", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "courseId", AttributeType: "S" },
      { AttributeName: "lessonId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-enrollments`,
    KeySchema: [
      { AttributeName: "studentId", KeyType: "HASH" },
      { AttributeName: "courseId", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "studentId", AttributeType: "S" },
      { AttributeName: "courseId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-teachers`,
    KeySchema: [{ AttributeName: "userId", KeyType: "HASH" }],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-mentors`,
    KeySchema: [{ AttributeName: "userId", KeyType: "HASH" }],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-sessions`,
    KeySchema: [{ AttributeName: "sessionId", KeyType: "HASH" }],
    AttributeDefinitions: [
      { AttributeName: "sessionId", AttributeType: "S" },
      { AttributeName: "studentId", AttributeType: "S" },
      { AttributeName: "mentorId", AttributeType: "S" },
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: "student-index",
        KeySchema: [{ AttributeName: "studentId", KeyType: "HASH" }],
        Projection: { ProjectionType: "ALL" },
        ProvisionedThroughput: { ReadCapacityUnits: 5, WriteCapacityUnits: 5 },
      },
      {
        IndexName: "mentor-index",
        KeySchema: [{ AttributeName: "mentorId", KeyType: "HASH" }],
        Projection: { ProjectionType: "ALL" },
        ProvisionedThroughput: { ReadCapacityUnits: 5, WriteCapacityUnits: 5 },
      },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-availability`,
    KeySchema: [
      { AttributeName: "mentorId", KeyType: "HASH" },
      { AttributeName: "slotId", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "mentorId", AttributeType: "S" },
      { AttributeName: "slotId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-reviews`,
    KeySchema: [
      { AttributeName: "targetId", KeyType: "HASH" },
      { AttributeName: "reviewId", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "targetId", AttributeType: "S" },
      { AttributeName: "reviewId", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-notifications`,
    KeySchema: [
      { AttributeName: "userId", KeyType: "HASH" },
      { AttributeName: "sortKey", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
      { AttributeName: "sortKey", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-earnings`,
    KeySchema: [
      { AttributeName: "userId", KeyType: "HASH" },
      { AttributeName: "periodKey", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
      { AttributeName: "periodKey", AttributeType: "S" },
    ],
  },
  {
    TableName: `${PROJECT_PREFIX}-subscriptions`,
    KeySchema: [
      { AttributeName: "userId", KeyType: "HASH" },
      { AttributeName: "subscriptionId", KeyType: "RANGE" },
    ],
    AttributeDefinitions: [
      { AttributeName: "userId", AttributeType: "S" },
      { AttributeName: "subscriptionId", AttributeType: "S" },
    ],
  },
];

async function tableExists(tableName) {
  try {
    await dynamodb.send(new DescribeTableCommand({ TableName: tableName }));
    return true;
  } catch {
    return false;
  }
}

async function createDynamoDBTables() {
  console.log("\n📦 Creating DynamoDB Tables...");

  for (const tableDef of TABLE_DEFINITIONS) {
    const exists = await tableExists(tableDef.TableName);
    if (exists) {
      console.log(`  [skip] ${tableDef.TableName} already exists`);
      continue;
    }

    try {
      const params = {
        TableName: tableDef.TableName,
        KeySchema: tableDef.KeySchema,
        AttributeDefinitions: tableDef.AttributeDefinitions,
        BillingMode: "PAY_PER_REQUEST",
      };

      if (tableDef.GlobalSecondaryIndexes) {
        params.GlobalSecondaryIndexes = tableDef.GlobalSecondaryIndexes.map(
          (gsi) => ({
            ...gsi,
            ProvisionedThroughput: undefined, // Not needed with PAY_PER_REQUEST
          })
        );
      }

      await dynamodb.send(new CreateTableCommand(params));
      console.log(`  [created] ${tableDef.TableName}`);
    } catch (error) {
      console.error(`  [error] ${tableDef.TableName}: ${error.message}`);
    }
  }
}

// ============================================================
// 3. S3 BUCKET
// ============================================================
async function createS3Bucket() {
  console.log("\n📦 Creating S3 Bucket...");

  const bucketName = `${PROJECT_PREFIX}-uploads-${Date.now()}`;

  try {
    await s3.send(
      new CreateBucketCommand({
        Bucket: bucketName,
      })
    );
    console.log(`  Bucket created: ${bucketName}`);

    // Set CORS for direct uploads from app
    await s3.send(
      new PutBucketCorsCommand({
        Bucket: bucketName,
        CORSConfiguration: {
          CORSRules: [
            {
              AllowedHeaders: ["*"],
              AllowedMethods: ["GET", "PUT", "POST"],
              AllowedOrigins: ["*"],
              ExposeHeaders: ["ETag"],
              MaxAgeSeconds: 3600,
            },
          ],
        },
      })
    );
    console.log("  CORS configured");

    return bucketName;
  } catch (error) {
    console.error("  Error creating S3 bucket:", error.message);
    throw error;
  }
}

// ============================================================
// 4. LAMBDA EXECUTION ROLE
// ============================================================
async function createLambdaRole() {
  console.log("\n📦 Creating Lambda Execution Role...");

  const roleName = `${PROJECT_PREFIX}-lambda-role`;
  const assumeRolePolicy = JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: { Service: "lambda.amazonaws.com" },
        Action: "sts:AssumeRole",
      },
    ],
  });

  try {
    const result = await iam.send(
      new CreateRoleCommand({
        RoleName: roleName,
        AssumeRolePolicyDocument: assumeRolePolicy,
        Description: "Execution role for Toriino Lambda functions",
      })
    );

    const roleArn = result.Role.Arn;
    console.log(`  Role ARN: ${roleArn}`);

    // Attach policies
    const policies = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
      "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
      "arn:aws:iam::aws:policy/AmazonS3FullAccess",
      "arn:aws:iam::aws:policy/AmazonCognitoPowerUser",
    ];

    for (const policyArn of policies) {
      await iam.send(
        new AttachRolePolicyCommand({
          RoleName: roleName,
          PolicyArn: policyArn,
        })
      );
    }
    console.log("  Policies attached");

    return roleArn;
  } catch (error) {
    if (error.name === "EntityAlreadyExistsException") {
      console.log("  Role already exists, fetching ARN...");
      // Return existing role ARN
      const { IAMClient: _, GetRoleCommand } = require("@aws-sdk/client-iam");
      const result = await iam.send(
        new (require("@aws-sdk/client-iam").GetRoleCommand)({
          RoleName: roleName,
        })
      );
      return result.Role.Arn;
    }
    throw error;
  }
}

// ============================================================
// MAIN DEPLOYMENT
// ============================================================
async function deploy() {
  console.log("==============================================");
  console.log("  TORIINO TODD — AWS Infrastructure Deployment");
  console.log(`  Region: ${REGION}`);
  console.log("==============================================");

  const config = {};

  // 1. Cognito
  const cognitoResult = await createCognitoUserPool();
  config.cognitoUserPoolId = cognitoResult.userPoolId;
  config.cognitoClientId = cognitoResult.clientId;

  // 2. DynamoDB
  await createDynamoDBTables();

  // 3. S3
  config.s3Bucket = await createS3Bucket();

  // 4. Lambda Role
  config.lambdaRoleArn = await createLambdaRole();

  // Save config for Flutter app
  const configPath = path.join(__dirname, "aws-config.json");
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`\n✅ Config saved to: ${configPath}`);

  console.log("\n==============================================");
  console.log("  DEPLOYMENT COMPLETE");
  console.log("==============================================");
  console.log("\nNext steps:");
  console.log("  1. Deploy Lambda functions: npm run deploy:backend");
  console.log("  2. Set up API Gateway: node deploy-api.js");
  console.log("  3. Update Flutter app with config values");

  return config;
}

deploy().catch(console.error);
