#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WRANGLER_CONFIG="${ROOT}/wrangler.jsonc"

require_cloudflare_env() {
  if [[ -n "${CLOUDFLARE_API_TOKEN:-}" && -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    return 0
  fi
  if bunx wrangler whoami >/dev/null 2>&1; then
    return 0
  fi
  echo "FAIL: Cloudflare credentials required (wrangler login or CLOUDFLARE_* env vars)" >&2
  exit 1
}

ensure_d1() {
  local name="$1"
  local id

  if id="$(
    bunx wrangler d1 info "$name" --json 2>/dev/null \
      | bun -e "
          const fs = require('node:fs')
          const input = fs.readFileSync(0, 'utf8').trim()
          if (!input) process.exit(1)
          const data = JSON.parse(input)
          const value = data.uuid ?? data.database_id
          if (!value) process.exit(1)
          process.stdout.write(String(value))
        "
  )"; then
    echo "exists: ${name} (${id})" >&2
    echo "${id}"
    return 0
  fi

  echo "creating: ${name}" >&2
  bunx wrangler d1 create "$name" >&2
  bunx wrangler d1 info "$name" --json \
    | bun -e "
        const fs = require('node:fs')
        const data = JSON.parse(fs.readFileSync(0, 'utf8'))
        const value = data.uuid ?? data.database_id
        if (!value) process.exit(1)
        process.stdout.write(String(value))
      "
}

update_wrangler_database_id() {
  local placeholder="$1"
  local database_id="$2"
  local tmp="${WRANGLER_CONFIG}.tmp"

  sed "s/\"database_id\": \"${placeholder}\"/\"database_id\": \"${database_id}\"/" "$WRANGLER_CONFIG" >"$tmp"
  mv "$tmp" "$WRANGLER_CONFIG"
}

require_cloudflare_env

DEVELOP_ID="$(ensure_d1 prottype)"
STAGING_ID="$(ensure_d1 prottype-staging)"
PRODUCTION_ID="$(ensure_d1 prottype-production)"

update_wrangler_database_id "00000000-0000-0000-0000-000000000001" "$DEVELOP_ID"
update_wrangler_database_id "00000000-0000-0000-0000-000000000002" "$STAGING_ID"
update_wrangler_database_id "00000000-0000-0000-0000-000000000003" "$PRODUCTION_ID"

echo "updated ${WRANGLER_CONFIG}"
echo "develop:    prottype            -> ${DEVELOP_ID}"
echo "staging:    prottype-staging    -> ${STAGING_ID}"
echo "production: prottype-production -> ${PRODUCTION_ID}"
echo
echo "Next:"
echo "  bun run db:migrate:remote"
echo "  bun run db:migrate:remote:staging"
echo "  bun run db:migrate:remote:production"
echo "  wrangler secret bulk secrets.json"
echo "  bun run deploy:develop"
