const {
  S3Client,
  PutPublicAccessBlockCommand,
  PutBucketPolicyCommand,
} = require("@aws-sdk/client-s3");

const BUCKET = "toriino-admin-panel";
const s3 = new S3Client({ region: "us-east-1" });

async function main() {
  console.log("\n  Fixing S3 public access for admin panel bucket...\n");

  // Step 1: Disable Block Public Access
  await s3.send(new PutPublicAccessBlockCommand({
    Bucket: BUCKET,
    PublicAccessBlockConfiguration: {
      BlockPublicAcls: false,
      IgnorePublicAcls: false,
      BlockPublicPolicy: false,
      RestrictPublicBuckets: false,
    },
  }));
  console.log("  [ok] Block Public Access disabled");

  // Step 2: Re-apply public read bucket policy
  await s3.send(new PutBucketPolicyCommand({
    Bucket: BUCKET,
    Policy: JSON.stringify({
      Version: "2012-10-17",
      Statement: [{
        Sid: "PublicRead",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: `arn:aws:s3:::${BUCKET}/*`,
      }],
    }),
  }));
  console.log("  [ok] Public read bucket policy applied");

  console.log("\n  Done! Wait 1-2 minutes then reload:");
  console.log("  https://d3gfpgvykn0mv4.cloudfront.net\n");
}

main().catch(e => { console.error(`\n  [error] ${e.message}\n`); process.exit(1); });
