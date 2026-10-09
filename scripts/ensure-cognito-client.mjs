// Makes sure the app's Cognito client cannot write custom:role. Without an explicit
// WriteAttributes list, every mutable attribute is client-writable, so any signed-in user could
// set their own role with Cognito UpdateUserAttributes and skip POST /auth/set-role.
// Roles are written only server-side (toriino-auth / toriino-admin use the Admin* APIs, which
// ignore client write permissions). ReadAttributes stays unset, so every attribute stays readable.
//
// Idempotent: the client is updated only when its WriteAttributes differ. UpdateUserPoolClient
// resets every omitted setting to its default, so all current settings are passed back as-is.
// Never prints the client secret.
//
// Usage (from toriino-splash/): node scripts/ensure-cognito-client.mjs

import { execFileSync } from 'child_process';

const REGION = 'us-east-1';
const USER_POOL_ID = 'us-east-1_CAiea51iC';
const CLIENT_NAME = 'Torino';
// Server-managed (custom:role) or Cognito-managed (verification flags, identities): never client-writable.
const NOT_WRITABLE = new Set(['custom:role', 'email_verified', 'phone_number_verified', 'identities']);

const aws = (args) => JSON.parse(execFileSync('aws', [...args, '--region', REGION, '--output', 'json'], {
  encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'],
}));

const clients = aws(['cognito-idp', 'list-user-pool-clients', '--user-pool-id', USER_POOL_ID, '--max-results', '60']).UserPoolClients || [];
const match = clients.filter((c) => c.ClientName === CLIENT_NAME);
if (match.length !== 1) {
  console.error(`ERROR: expected one client named "${CLIENT_NAME}", found ${match.length}`);
  process.exit(1);
}
const clientId = match[0].ClientId;
const client = aws(['cognito-idp', 'describe-user-pool-client', '--user-pool-id', USER_POOL_ID, '--client-id', clientId]).UserPoolClient;

const mutable = (aws(['cognito-idp', 'describe-user-pool', '--user-pool-id', USER_POOL_ID]).UserPool.SchemaAttributes || [])
  .filter((a) => a.Mutable).map((a) => a.Name);
const desired = mutable.filter((n) => !NOT_WRITABLE.has(n)).sort();
const current = [...(client.WriteAttributes || [])].sort();

if (client.WriteAttributes && JSON.stringify(current) === JSON.stringify(desired)) {
  console.log(`ok       Cognito client ${CLIENT_NAME}: custom:role not writable — left unchanged`);
  process.exit(0);
}

const { ClientSecret, CreationDate, LastModifiedDate, ...settings } = client; // eslint-disable-line no-unused-vars
const input = { ...settings, WriteAttributes: desired };
execFileSync('aws', ['cognito-idp', 'update-user-pool-client', '--cli-input-json', JSON.stringify(input), '--region', REGION, '--output', 'json'], {
  encoding: 'utf8', stdio: ['ignore', 'ignore', 'pipe'],
});

const after = aws(['cognito-idp', 'describe-user-pool-client', '--user-pool-id', USER_POOL_ID, '--client-id', clientId]).UserPoolClient;
if ((after.WriteAttributes || []).includes('custom:role') || !after.WriteAttributes) {
  console.error('ERROR: update did not apply — custom:role is still writable');
  process.exit(1);
}
for (const k of ['ExplicitAuthFlows', 'RefreshTokenValidity', 'AccessTokenValidity', 'IdTokenValidity', 'TokenValidityUnits',
  'PreventUserExistenceErrors', 'EnableTokenRevocation', 'AuthSessionValidity', 'ReadAttributes']) {
  if (JSON.stringify(after[k]) !== JSON.stringify(client[k])) {
    console.error(`ERROR: ${k} changed during the update`);
    process.exit(1);
  }
}
console.log(`updated  Cognito client ${CLIENT_NAME}: WriteAttributes = ${desired.length} attributes (custom:role removed); other settings unchanged`);
