// Creates the backend's SSM SecureString parameters with the placeholder NOT_SET.
// Existing parameters are left untouched (never overwritten), and no value is ever
// read or printed. Lambdas treat NOT_SET as "not configured" and return 503.
// (CloudFormation cannot create SecureString parameters, hence this script.)
//
// Usage (from toriino-splash/): node scripts/ensure-ssm-params.mjs

import { execFileSync } from 'child_process';

const REGION = 'us-east-1';
const PREFIX = '/torino/prod/';
const NAMES = ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET', 'GEMINI_API_KEY', 'AGORA_CUSTOMER_ID', 'AGORA_CUSTOMER_SECRET'];

const aws = (args) => execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
  encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
});

for (const name of NAMES) {
  const full = PREFIX + name;
  const found = JSON.parse(aws(['ssm', 'describe-parameters', '--parameter-filters', `Key=Name,Option=Equals,Values=${full}`])).Parameters || [];
  if (found.length) {
    console.log(`exists   ${full} (${found[0].Type}) — left unchanged`);
    continue;
  }
  aws(['ssm', 'put-parameter', '--name', full, '--type', 'SecureString', '--value', 'NOT_SET',
    '--description', 'Placeholder NOT_SET until the owner sets the real value']);
  console.log(`created  ${full} (SecureString, NOT_SET)`);
}
