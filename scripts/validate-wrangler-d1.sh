#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if grep -q '00000000-0000-0000-0000-00000000000[0-9]' "${ROOT}/wrangler.jsonc"; then
  echo "FAIL: wrangler.jsonc still uses placeholder D1 database_id values." >&2
  echo "Run: bash scripts/setup-remote-d1.sh" >&2
  exit 1
fi

echo "wrangler D1 database_id values look configured"
