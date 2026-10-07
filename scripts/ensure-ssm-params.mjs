// Creates the backend's SSM parameters if missing: SecureString secrets with the placeholder
// NOT_SET, and plain String config values with their defaults (PLATFORM_FEE_PERCENT = 25 until
// the client confirms the rate).
// Existing parameters are left untouched (never overwritten), and no value is ever
// read or printed. Lambdas treat NOT_SET as "not configured" and return 503.
// (CloudFormation cannot create SecureString parameters, hence this script.)
//
// Usage (from toriino-splash/): node scripts/ensure-ssm-params.mjs

import { execFileSync } from 'child_process';

const REGION = 'us-east-1';
const PREFIX = '/torino/prod/';
const NAMES = ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET', 'GEMINI_API_KEY', 'AGORA_CUSTOMER_ID', 'AGORA_CUSTOMER_SECRET',
  'AGORA_APP_CERTIFICATE'];
// Not secret: one value for every price split (platform fee = price × %, teacher gets the rest).
// Unconfirmed placeholder plans: all inactive and without Stripe Price IDs, so none is offered
// until the client confirms prices/audiences and sets "active": true + a real "stripePriceId".
const PLANS = [];
for (const audience of ['student', 'teacher', 'mentor']) {
  for (const [id, name, months, price] of [['monthly', 'Monthly', 1, 9.99], ['quarterly', 'Quarterly', 3, 49.99], ['yearly', 'Yearly', 12, 99.99]]) {
    PLANS.push({ planId: `${audience}-${id}`, name, audience, months, price, currency: 'usd', stripePriceId: 'NOT_SET', active: false });
  }
}
const CONFIG = {
  PLATFORM_FEE_PERCENT: { value: '25', description: 'Platform fee percent of every course/session price (default 25 until the client confirms)' },
  SUBSCRIPTION_PLANS: { value: JSON.stringify(PLANS), description: 'Subscription plans (JSON). A plan is offered only when active=true and stripePriceId is set' },
  PREMIUM_FEATURES: { value: '[]', description: 'JSON list of features that require premium (ai_chat, ai_twins, ai_recommendations, ai_summary). Empty = nothing gated' },
};

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

for (const [name, { value, description }] of Object.entries(CONFIG)) {
  const full = PREFIX + name;
  const found = JSON.parse(aws(['ssm', 'describe-parameters', '--parameter-filters', `Key=Name,Option=Equals,Values=${full}`])).Parameters || [];
  if (found.length) {
    console.log(`exists   ${full} (${found[0].Type}) — left unchanged`);
    continue;
  }
  aws(['ssm', 'put-parameter', '--name', full, '--type', 'String', '--value', value, '--description', description]);
  console.log(`created  ${full} (String, ${value})`);
}
