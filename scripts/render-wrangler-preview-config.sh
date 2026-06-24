#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: render-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_ID="${2:?Usage: render-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_NAME="prottype-pr-${PR_NUMBER}"
BASE_CONFIG="${ROOT}/dist/prottype/wrangler.json"
OUT="${3:-${ROOT}/dist/prottype/wrangler.preview.pr-${PR_NUMBER}.json}"

if [[ ! -f "$BASE_CONFIG" ]]; then
  echo "FAIL: ${BASE_CONFIG} not found. Run 'bun run build' first." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

bun -e "
const fs = require('node:fs')
const base = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'))
const databaseName = process.argv[2]
const databaseId = process.argv[3]
const outPath = process.argv[4]

const config = {
  name: base.name,
  main: base.main,
  compatibility_date: base.compatibility_date,
  compatibility_flags: base.compatibility_flags,
  preview_urls: true,
  no_bundle: base.no_bundle,
  vars: {
    ENVIRONMENT: 'preview',
  },
  d1_databases: [
    {
      binding: 'DB',
      database_name: databaseName,
      database_id: databaseId,
      migrations_dir: 'migrations',
    },
  ],
  observability: base.observability,
}

if (base.assets) {
  config.assets = base.assets
}

fs.writeFileSync(outPath, JSON.stringify(config, null, 2) + '\n')
" "$BASE_CONFIG" "$DATABASE_NAME" "$DATABASE_ID" "$OUT"

echo "config_path=${OUT}"
