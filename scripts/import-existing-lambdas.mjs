// One-time CloudFormation resource import of the Lambdas that were created by hand
// before aws-backend/template.yaml existed (toriino-users, toriino-student-search,
// toriino-admin). After the import, `sam deploy` manages them under the same names —
// nothing is deleted or re-created.
//
// Idempotent: if the stack already exists it does nothing.
// Usage (from toriino-splash/): node scripts/import-existing-lambdas.mjs [stack-name]

import { execFileSync } from 'child_process';

const REGION = 'us-east-1';
const STACK = process.argv[2] || 'torino-backend';
const FUNCTIONS = {
  UsersFunction: 'toriino-users',
  StudentSearchFunction: 'toriino-student-search',
  AdminFunction: 'toriino-admin',
};

function aws(args, allowFail = false) {
  try {
    const out = execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
    });
    return out.trim() ? JSON.parse(out) : {};
  } catch (e) {
    if (allowFail) return { __error: String(e.stderr || e.message) };
    throw new Error(String(e.stderr || e.message));
  }
}

const existing = aws(['cloudformation', 'describe-stacks', '--stack-name', STACK], true);
if (!existing.__error) {
  console.log(`Stack ${STACK} exists (${existing.Stacks[0].StackStatus}) — import already done, skipping.`);
  process.exit(0);
}
if (!/does not exist/.test(existing.__error)) throw new Error(existing.__error);

// The import template only has to identify the resources; sam deploy sets the real
// properties (code, role, runtime, env) right after.
const resources = {};
for (const [logicalId, name] of Object.entries(FUNCTIONS)) {
  const cfg = aws(['lambda', 'get-function-configuration', '--function-name', name]);
  resources[logicalId] = {
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
const template = JSON.stringify({ AWSTemplateFormatVersion: '2010-09-09', Resources: resources });
const toImport = Object.entries(FUNCTIONS).map(([LogicalResourceId, FunctionName]) => ({
  ResourceType: 'AWS::Lambda::Function', LogicalResourceId, ResourceIdentifier: { FunctionName },
}));

const changeSet = `import-existing-${Date.now()}`;
console.log(`Creating IMPORT change set for ${Object.values(FUNCTIONS).join(', ')} into new stack ${STACK}…`);
aws(['cloudformation', 'create-change-set', '--stack-name', STACK, '--change-set-name', changeSet,
  '--change-set-type', 'IMPORT', '--resources-to-import', JSON.stringify(toImport), '--template-body', template]);
aws(['cloudformation', 'wait', 'change-set-create-complete', '--stack-name', STACK, '--change-set-name', changeSet]);
aws(['cloudformation', 'execute-change-set', '--stack-name', STACK, '--change-set-name', changeSet]);
aws(['cloudformation', 'wait', 'stack-import-complete', '--stack-name', STACK]);
console.log(`Imported. Stack ${STACK}: ${aws(['cloudformation', 'describe-stacks', '--stack-name', STACK]).Stacks[0].StackStatus}`);
