/**
 * Deploys the Toriino Admin Panel to S3 + CloudFront
 *
 * Builds the Next.js static export, uploads to S3,
 * creates a CloudFront distribution, and prints the URL.
 *
 * Usage: node deploy-admin-hosting.js
 *
 * On subsequent deploys (code updates), run:
 *   node deploy-admin-hosting.js --update
 */

const {
  S3Client,
  CreateBucketCommand,
  PutBucketWebsiteCommand,
  PutBucketPolicyCommand,
  PutObjectCommand,
  HeadBucketCommand,
  ListObjectsV2Command,
  DeleteObjectsCommand,
} = require("@aws-sdk/client-s3");

const {
  CloudFrontClient,
  CreateDistributionCommand,
  ListDistributionsCommand,
  CreateInvalidationCommand,
} = require("@aws-sdk/client-cloudfront");

const { STSClient, GetCallerIdentityCommand } = require("@aws-sdk/client-sts");

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const { lookup: mimeLookup } = require("mime-types");

const REGION = "us-east-1";
const BUCKET_NAME = "toriino-admin-panel";
const PROJECT_ROOT = path.join(__dirname, "..", "..", "admin-panel");
const OUT_DIR = path.join(PROJECT_ROOT, "out");

const s3 = new S3Client({ region: REGION });
const cf = new CloudFrontClient({ region: "us-east-1" });
const sts = new STSClient({ region: REGION });

const isUpdate = process.argv.includes("--update");

// ─── Build ────────────────────────────────────────────────────────────────────

function build() {
  console.log("\n  Building admin panel...");
  execSync("npm run build", { cwd: PROJECT_ROOT, stdio: "inherit" });
  if (!fs.existsSync(OUT_DIR)) {
    throw new Error("Build failed — 'out' directory not found");
  }
  console.log("  [ok] Build complete\n");
}

// ─── S3 ───────────────────────────────────────────────────────────────────────

async function ensureBucket() {
  try {
    await s3.send(new HeadBucketCommand({ Bucket: BUCKET_NAME }));
    console.log(`  [found] S3 bucket: ${BUCKET_NAME}`);
  } catch {
    await s3.send(new CreateBucketCommand({ Bucket: BUCKET_NAME }));
    console.log(`  [created] S3 bucket: ${BUCKET_NAME}`);

    await s3.send(new PutBucketWebsiteCommand({
      Bucket: BUCKET_NAME,
      WebsiteConfiguration: {
        IndexDocument: { Suffix: "index.html" },
        ErrorDocument: { Key: "404/index.html" },
      },
    }));

    await s3.send(new PutBucketPolicyCommand({
      Bucket: BUCKET_NAME,
      Policy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
          Sid: "PublicRead",
          Effect: "Allow",
          Principal: "*",
          Action: "s3:GetObject",
          Resource: `arn:aws:s3:::${BUCKET_NAME}/*`,
        }],
      }),
    }));
  }
}

async function clearBucket() {
  const listed = await s3.send(new ListObjectsV2Command({ Bucket: BUCKET_NAME }));
  if (listed.Contents?.length) {
    await s3.send(new DeleteObjectsCommand({
      Bucket: BUCKET_NAME,
      Delete: { Objects: listed.Contents.map(o => ({ Key: o.Key })) },
    }));
    console.log(`  [cleared] Removed ${listed.Contents.length} old files`);
  }
}

async function uploadDir(dir, prefix = "") {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const localPath = path.join(dir, entry.name);
    const s3Key = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      await uploadDir(localPath, s3Key);
    } else {
      const body = fs.readFileSync(localPath);
      const contentType = mimeLookup(entry.name) || "application/octet-stream";
      await s3.send(new PutObjectCommand({
        Bucket: BUCKET_NAME,
        Key: s3Key,
        Body: body,
        ContentType: contentType,
        CacheControl: entry.name.endsWith(".html") ? "no-cache" : "public, max-age=31536000",
      }));
      process.stdout.write(".");
    }
  }
}

// ─── CloudFront ───────────────────────────────────────────────────────────────

async function getExistingDistribution() {
  const r = await cf.send(new ListDistributionsCommand({}));
  return r.DistributionList?.Items?.find(d =>
    d.Origins?.Items?.[0]?.DomainName?.includes(BUCKET_NAME)
  );
}

async function createDistribution() {
  const r = await cf.send(new CreateDistributionCommand({
    DistributionConfig: {
      CallerReference: `toriino-admin-${Date.now()}`,
      Comment: "Toriino Admin Panel",
      DefaultRootObject: "index.html",
      Origins: {
        Quantity: 1,
        Items: [{
          Id: "S3Origin",
          DomainName: `${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com`,
          CustomOriginConfig: {
            HTTPPort: 80,
            HTTPSPort: 443,
            OriginProtocolPolicy: "http-only",
          },
        }],
      },
      DefaultCacheBehavior: {
        TargetOriginId: "S3Origin",
        ViewerProtocolPolicy: "redirect-to-https",
        AllowedMethods: { Quantity: 2, Items: ["GET", "HEAD"] },
        CachedMethods: { Quantity: 2, Items: ["GET", "HEAD"] },
        Compress: true,
        ForwardedValues: {
          QueryString: false,
          Cookies: { Forward: "none" },
        },
        MinTTL: 0,
        DefaultTTL: 86400,
        MaxTTL: 31536000,
      },
      CustomErrorResponses: {
        Quantity: 1,
        Items: [{
          ErrorCode: 403,
          ResponseCode: "200",
          ResponsePagePath: "/index.html",
          ErrorCachingMinTTL: 0,
        }],
      },
      PriceClass: "PriceClass_100",
      Enabled: true,
    },
  }));
  return r.Distribution;
}

async function invalidateCache(distributionId) {
  await cf.send(new CreateInvalidationCommand({
    DistributionId: distributionId,
    InvalidationBatch: {
      CallerReference: `${Date.now()}`,
      Paths: { Quantity: 1, Items: ["/*"] },
    },
  }));
  console.log("  [ok] Cache invalidated");
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("==============================================");
  console.log("  TORIINO — Deploy Admin Panel to AWS");
  console.log("==============================================");

  const identity = await sts.send(new GetCallerIdentityCommand({}));
  console.log(`\n  Account: ${identity.Account}`);

  // 1. Build
  build();

  // 2. S3
  console.log("  Setting up S3 bucket...");
  await ensureBucket();
  if (isUpdate) await clearBucket();
  console.log("  Uploading files");
  await uploadDir(OUT_DIR);
  console.log("\n  [ok] Upload complete");

  // 3. CloudFront
  console.log("\n  Setting up CloudFront...");
  const existing = await getExistingDistribution();
  let domain, distId;

  if (existing) {
    domain = existing.DomainName;
    distId = existing.Id;
    console.log(`  [found] Distribution: ${distId}`);
    await invalidateCache(distId);
  } else {
    console.log("  Creating CloudFront distribution (takes ~5 min to go live)...");
    const dist = await createDistribution();
    domain = dist.DomainName;
    distId = dist.Id;
    console.log(`  [created] Distribution: ${distId}`);
  }

  // Save to config
  const configPath = path.join(__dirname, "aws-config.json");
  const config = fs.existsSync(configPath) ? JSON.parse(fs.readFileSync(configPath, "utf8")) : {};
  config.adminPanelUrl = `https://${domain}`;
  config.adminPanelBucket = BUCKET_NAME;
  config.adminPanelDistributionId = distId;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

  console.log("\n==============================================");
  console.log("  DONE");
  console.log("==============================================");
  console.log(`\n  Admin Panel URL: https://${domain}`);
  console.log("  (CloudFront takes ~5 minutes to go live globally)");
  console.log("\n  To redeploy after code changes:");
  console.log("    node infrastructure/deploy-admin-hosting.js --update\n");
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
