#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=d1-helpers.sh
source "${ROOT}/scripts/d1-helpers.sh"

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

update_wrangler_database_id() {
  local placeholder="$1"
  local database_id="$2"
  local tmp="${WRANGLER_CONFIG}.tmp"

  sed "s/\"database_id\": \"${placeholder}\"/\"database_id\": \"${database_id}\"/" "$WRANGLER_CONFIG" >"$tmp"
  mv "$tmp" "$WRANGLER_CONFIG"
}

remove_duplicate_d1_bindings() {
  bun -e "
    const fs = require('node:fs')
    const path = process.argv[1]
    const text = fs.readFileSync(path, 'utf8')
    const lines = text.split('\n')
    const out = []
    let inD1 = false
    let depth = 0
    let block = []
    let blockDepth = 0

    const flushBlock = () => {
      const joined = block.join('\n')
      const isDuplicateProttype =
        /\"binding\": \"prottype\"/.test(joined) &&
        /\"database_name\": \"prottype\"/.test(joined) &&
        !/\"binding\": \"DB\"/.test(joined)
      if (!isDuplicateProttype) {
        out.push(...block)
      }
      block = []
    }

    for (const line of lines) {
      if (!inD1 && /\"d1_databases\"/.test(line)) {
        inD1 = true
        out.push(line)
        continue
      }

      if (inD1 && block.length === 0 && /^\s*\{/.test(line)) {
        blockDepth = (line.match(/\{/g) || []).length - (line.match(/\}/g) || []).length
        block = [line]
        if (blockDepth <= 0) {
          flushBlock()
          inD1 = false
        }
        continue
      }

      if (block.length > 0) {
        block.push(line)
        blockDepth += (line.match(/\{/g) || []).length
        blockDepth -= (line.match(/\}/g) || []).length
        if (blockDepth <= 0) {
          flushBlock()
        }
        continue
      }

      out.push(line)
      if (inD1 && /^\s*\],/.test(line)) {
        inD1 = false
      }
    }

    fs.writeFileSync(path, out.join('\n'))
  " "$WRANGLER_CONFIG"
}

require_cloudflare_env

DEVELOP_ID="$(ensure_remote_d1 prottype)"
STAGING_ID="$(ensure_remote_d1 prottype-staging)"
PRODUCTION_ID="$(ensure_remote_d1 prottype-production)"

remove_duplicate_d1_bindings

update_wrangler_database_id "00000000-0000-0000-0000-000000000001" "$DEVELOP_ID"
update_wrangler_database_id "00000000-0000-0000-0000-000000000002" "$STAGING_ID"
update_wrangler_database_id "00000000-0000-0000-0000-000000000003" "$PRODUCTION_ID"

bun run prettier --write "$WRANGLER_CONFIG" >/dev/null

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
