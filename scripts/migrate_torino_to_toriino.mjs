/**
 * Idempotent migration: copy rows from torino-* tables to toriino-* tables.
 * Safe to run multiple times — uses PutItem (overwrite-safe with same PK).
 *
 * Usage:
 *   AWS_REGION=us-east-1 node scripts/migrate_torino_to_toriino.mjs [--dry-run]
 *
 * OWNER steps:
 *   1. Run once in a staging environment first.
 *   2. Verify row counts match.
 *   3. Run against prod with a low-traffic window.
 *   4. After migration, update Lambda env vars to point to toriino-* tables.
 *   5. Decommission torino-* tables only after prod traffic is fully off them.
 */

import {
  DynamoDBClient,
  ScanCommand,
  PutItemCommand,
  DescribeTableCommand,
} from '@aws-sdk/client-dynamodb';
import { marshall } from '@aws-sdk/util-dynamodb';

const REGION = process.env.AWS_REGION || 'us-east-1';
const DRY_RUN = process.argv.includes('--dry-run');

const db = new DynamoDBClient({ region: REGION });

const TABLE_PAIRS = [
  { src: 'torino-users',         dst: 'toriino-users' },
  { src: 'torino-courses',       dst: 'toriino-courses' },
  { src: 'torino-lessons',       dst: 'toriino-course-lessons' },
  { src: 'torino-enrollments',   dst: 'toriino-enrollments' },
  { src: 'torino-sessions',      dst: 'toriino-sessions' },
  { src: 'torino-mentors',       dst: 'toriino-mentors' },
  { src: 'torino-reviews',       dst: 'toriino-reviews' },
  { src: 'torino-earnings',      dst: 'toriino-earnings' },
  { src: 'torino-notifications', dst: 'toriino-notifications' },
  { src: 'torino-withdrawals',   dst: 'toriino-earnings' }, // withdrawals folded into earnings
];

async function tableExists(name) {
  try {
    await db.send(new DescribeTableCommand({ TableName: name }));
    return true;
  } catch {
    return false;
  }
}

async function scanAll(tableName) {
  const items = [];
  let lastKey;
  do {
    const result = await db.send(new ScanCommand({
      TableName: tableName,
      ExclusiveStartKey: lastKey,
    }));
    items.push(...(result.Items || []));
    lastKey = result.LastEvaluatedKey;
  } while (lastKey);
  return items;
}

async function migratePair({ src, dst }) {
  const srcExists = await tableExists(src);
  const dstExists = await tableExists(dst);

  if (!srcExists) {
    console.log(`  [SKIP] ${src} does not exist — nothing to migrate`);
    return { copied: 0, skipped: true };
  }
  if (!dstExists) {
    console.error(`  [ERROR] Destination ${dst} does not exist — create it first`);
    return { copied: 0, error: true };
  }

  const items = await scanAll(src);
  console.log(`  ${src} → ${dst}: ${items.length} items`);

  if (DRY_RUN) {
    console.log(`  [DRY-RUN] would copy ${items.length} items`);
    return { copied: items.length };
  }

  let copied = 0;
  for (const item of items) {
    await db.send(new PutItemCommand({ TableName: dst, Item: item }));
    copied++;
  }
  return { copied };
}

async function main() {
  console.log(`Migration ${DRY_RUN ? '[DRY-RUN] ' : ''}starting (region: ${REGION})\n`);
  let totalCopied = 0;
  let errors = 0;

  for (const pair of TABLE_PAIRS) {
    console.log(`${pair.src} → ${pair.dst}`);
    const result = await migratePair(pair);
    if (result.error) errors++;
    else if (!result.skipped) totalCopied += result.copied;
  }

  console.log(`\nMigration complete. Copied: ${totalCopied} rows. Errors: ${errors}`);
  if (errors > 0) process.exit(1);
}

main().catch(err => { console.error(err); process.exit(1); });
