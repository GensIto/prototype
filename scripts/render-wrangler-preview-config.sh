#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: render-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_ID="${2:?Usage: render-wrangler-preview-config.sh <pr-number> <database-id>}"
DATABASE_NAME="prottype-pr-${PR_NUMBER}"
OUT="${3:-${ROOT}/wrangler.preview.pr-${PR_NUMBER}.jsonc}"

mkdir -p "$(dirname "$OUT")"

cat >"$OUT" <<EOF
{
  "\$schema": "node_modules/wrangler/config-schema.json",
  "name": "prottype",
  "main": "./app/server.ts",
  "compatibility_date": "2026-06-24",
  "compatibility_flags": ["nodejs_compat"],
  "preview_urls": true,
  "vars": {
    "ENVIRONMENT": "preview"
  },
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "${DATABASE_NAME}",
      "database_id": "${DATABASE_ID}",
      "migrations_dir": "migrations"
    }
  ],
  "observability": {
    "enabled": true,
    "head_sampling_rate": 1
  }
}
EOF

echo "config_path=${OUT}"
