// CloudFormation resource import of resources that were created by hand before
// aws-backend/template.yaml managed them: Lambdas, and the torino-app-storage bucket
// policy (CloudFormation refuses to *create* a policy on a bucket that already has one).
// After the import, `sam deploy` manages them under the same names — nothing is deleted
// or re-created (DeletionPolicy Retain); the bucket policy is then updated in place.
//
// Idempotent:
//   - stack missing  → creates it by importing every function in FUNCTIONS
//   - stack present  → imports only the functions it does not hold yet (none → no-op)
//
// Usage (from toriino-splash/): node scripts/import-existing-lambdas.mjs [stack-name]

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execFileSync } from 'child_process';

const REGION = 'us-east-1';
const STACK = process.argv[2] || 'torino-backend';
// Logical IDs must match aws-backend/template.yaml.
const FUNCTIONS = {
  UsersFunction: 'toriino-users',
  StudentSearchFunction: 'toriino-student-search',
  AdminFunction: 'toriino-admin',
  AiChatFunction: 'toriino-ai-chat',
  AiTwinsFunction: 'toriino-ai-twins',
  AiMemoryFunction: 'toriino-ai-memory',
  AiSummariesFunction: 'toriino-ai-summaries',
  TranscribeProcessorFunction: 'toriino-transcribe-processor',
};

function aws(args, allowFail = false) {
  try {
    const out = execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 * 1024 * 1024,
    });
    return out.trim() ? JSON.parse(out) : {};
  } catch (e) {
    if (allowFail) return { __error: String(e.stderr || e.message) };
    throw new Error(String(e.stderr || e.message));
  }
}

// Placeholder resource: only identifies the function; sam deploy sets the real properties.
function importResource(name) {
  const cfg = aws(['lambda', 'get-function-configuration', '--function-name', name]);
  return {
    Type: 'AWS::Lambda::Function',
    DeletionPolicy: 'Retain',
    UpdateReplacePolicy: 'Retain',
    Properties: {
      FunctionName: name,
      Role: cfg.Role,
      Handler: cfg.Handler,
      Runtime: cfg.Runtime,
      Code: { ZipFile: 'exports.handler = async () => ({ statusCode: 503 });' },
    },
  };
}

function runImport(template, toImport, params) {
  const changeSet = `import-existing-${Date.now()}`;
  const body = JSON.stringify(template);
  const args = ['cloudformation', 'create-change-set', '--stack-name', STACK, '--change-set-name', changeSet,
    '--change-set-type', 'IMPORT', '--capabilities', 'CAPABILITY_IAM', '--resources-to-import', JSON.stringify(toImport)];
  if (Buffer.byteLength(body) <= 51200) {
    // Via a file: an inline argument would hit the Windows command-line limit (~32 KB).
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'import-')), 'template.json');
    fs.writeFileSync(file, body);
    args.push('--template-body', `file://${file}`);
  } else {
    // Too big to send inline: stage it in the SAM-managed artifacts bucket.
    const bucket = aws(['cloudformation', 'describe-stacks', '--stack-name', 'aws-sam-cli-managed-default'])
      .Stacks[0].Outputs.find((o) => o.OutputKey === 'SourceBucket').OutputValue;
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'import-')), 'template.json');
    fs.writeFileSync(file, body);
    const key = `${STACK}/import/${changeSet}.json`;
    aws(['s3', 'cp', file, `s3://${bucket}/${key}`]);
    args.push('--template-url', `https://${bucket}.s3.${REGION}.amazonaws.com/${key}`);
  }
  if (params?.length) args.push('--parameters', JSON.stringify(params));
  aws(args);
  aws(['cloudformation', 'wait', 'change-set-create-complete', '--stack-name', STACK, '--change-set-name', changeSet]);
  aws(['cloudformation', 'execute-change-set', '--stack-name', STACK, '--change-set-name', changeSet]);
  aws(['cloudformation', 'wait', 'stack-import-complete', '--stack-name', STACK]);
  console.log(`Imported. Stack ${STACK}: ${aws(['cloudformation', 'describe-stacks', '--stack-name', STACK]).Stacks[0].StackStatus}`);
}

const existing = aws(['cloudformation', 'describe-stacks', '--stack-name', STACK], true);
if (existing.__error && !/does not exist/.test(existing.__error)) throw new Error(existing.__error);

if (existing.__error) {
  // New stack: import everything.
  const Resources = Object.fromEntries(Object.entries(FUNCTIONS).map(([id, name]) => [id, importResource(name)]));
  console.log(`Creating stack ${STACK} by importing ${Object.values(FUNCTIONS).join(', ')}…`);
  runImport({ AWSTemplateFormatVersion: '2010-09-09', Resources },
    Object.entries(FUNCTIONS).map(([LogicalResourceId, FunctionName]) => ({
      ResourceType: 'AWS::Lambda::Function', LogicalResourceId, ResourceIdentifier: { FunctionName } })));
  process.exit(0);
}

const inStack = new Set((aws(['cloudformation', 'list-stack-resources', '--stack-name', STACK]).StackResourceSummaries || [])
  .map((r) => r.LogicalResourceId));
const missing = Object.entries(FUNCTIONS).filter(([id, name]) => !inStack.has(id)
  && !aws(['lambda', 'get-function-configuration', '--function-name', name], true).__error);

// The bucket policy (logical ID MediaBucketPolicy in template.yaml), imported as it is today.
const BUCKET = 'torino-app-storage';
let bucketPolicy = null;
if (!inStack.has('MediaBucketPolicy')) {
  const r = aws(['s3api', 'get-bucket-policy', '--bucket', BUCKET], true);
  if (!r.__error) bucketPolicy = JSON.parse(r.Policy);
  else if (!/NoSuchBucketPolicy/.test(r.__error)) throw new Error(r.__error);
}

if (!missing.length && !bucketPolicy) {
  console.log(`Stack ${STACK}: all hand-made resources already imported — nothing to do.`);
  process.exit(0);
}

// Existing stack: current (processed) template + the new resources, nothing else changed.
const template = aws(['cloudformation', 'get-template', '--stack-name', STACK, '--template-stage', 'Processed']).TemplateBody;
const tpl = typeof template === 'string' ? JSON.parse(template) : template;
const toImport = [];
for (const [id, name] of missing) {
  tpl.Resources[id] = importResource(name);
  toImport.push({ ResourceType: 'AWS::Lambda::Function', LogicalResourceId: id, ResourceIdentifier: { FunctionName: name } });
}
if (bucketPolicy) {
  tpl.Resources.MediaBucketPolicy = {
    Type: 'AWS::S3::BucketPolicy',
    DeletionPolicy: 'Retain',
    UpdateReplacePolicy: 'Retain',
    Properties: { Bucket: BUCKET, PolicyDocument: bucketPolicy },
  };
  toImport.push({ ResourceType: 'AWS::S3::BucketPolicy', LogicalResourceId: 'MediaBucketPolicy', ResourceIdentifier: { Bucket: BUCKET } });
}
const params = (existing.Stacks[0].Parameters || []).map((p) => ({ ParameterKey: p.ParameterKey, UsePreviousValue: true }));
console.log(`Importing ${toImport.map((r) => r.ResourceIdentifier.FunctionName || `bucket policy of ${BUCKET}`).join(', ')} into existing stack ${STACK}…`);
runImport(tpl, toImport, params);
