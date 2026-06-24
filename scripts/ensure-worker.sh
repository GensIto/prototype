#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

WORKER_NAME="${1:-prottype}"
CONFIG="${2:-${ROOT}/wrangler.jsonc}"

require_cloudflare_env() {
  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" || -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    echo "FAIL: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID are required" >&2
    exit 1
  fi
}

worker_exists() {
  local output
  output="$(bunx wrangler deployments list --name "$WORKER_NAME" --json 2>&1)" || true

  if echo "$output" | grep -qE '10007|does not exist on your account'; then
    return 1
  fi

  echo "$output" | bun -e "
    const fs = require('node:fs')
    const raw = fs.readFileSync(0, 'utf8').trim()
    if (!raw) process.exit(1)
    try {
      JSON.parse(raw)
      process.exit(0)
    } catch {
      process.exit(1)
    }
  "
}

require_cloudflare_env

if worker_exists; then
  echo "exists: ${WORKER_NAME}" >&2
  exit 0
fi

echo "bootstrapping: ${WORKER_NAME}" >&2
echo "hint: 初回のみ develop D1 で deploy します。BETTER_AUTH_* は wrangler secret bulk で登録すると Preview でも Auth が動作します" >&2
bunx wrangler deploy --config "$CONFIG" >&2
echo "bootstrapped: ${WORKER_NAME}" >&2
