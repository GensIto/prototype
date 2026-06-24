#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: patch-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_ID="${2:?Usage: patch-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_NAME="prottype-pr-${PR_NUMBER}"
BUILT_CONFIG="${ROOT}/dist/prottype/wrangler.json"
BACKUP="${BUILT_CONFIG}.bak"

if [[ ! -f "$BUILT_CONFIG" ]]; then
  echo "FAIL: ${BUILT_CONFIG} not found. Run 'bun run build' first." >&2
  exit 1
fi

cp "$BUILT_CONFIG" "$BACKUP"

bun -e "
const fs = require('node:fs')
const configPath = process.argv[1]
const databaseName = process.argv[2]
const databaseId = process.argv[3]
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'))

config.vars = { ENVIRONMENT: 'preview' }
config.d1_databases = [
  {
    binding: 'DB',
    database_name: databaseName,
    database_id: databaseId,
    migrations_dir: 'migrations',
  },
]

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n')
" "$BUILT_CONFIG" "$DATABASE_NAME" "$DATABASE_ID"

echo "config_path=${BUILT_CONFIG}"
echo "backup_path=${BACKUP}"
