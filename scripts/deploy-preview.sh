#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: deploy-preview.sh <pr-number>}"
MESSAGE="${2:-Preview for PR #${PR_NUMBER}}"
ALIAS="pr-${PR_NUMBER}"
LOG_FILE="${TMPDIR:-/tmp}/wrangler-preview-${PR_NUMBER}.log"
OUTPUT_JSON="${TMPDIR:-/tmp}/wrangler-preview-${PR_NUMBER}.json"

eval "$(bash scripts/preview-d1.sh ensure "${PR_NUMBER}")"
bash scripts/preview-d1.sh migrate "${PR_NUMBER}"

eval "$(bash scripts/render-wrangler-preview-config.sh "${PR_NUMBER}" "${database_id}")"

rm -f "$OUTPUT_JSON"
export NO_COLOR=1
export FORCE_COLOR=0
export WRANGLER_OUTPUT_FILE_PATH="$OUTPUT_JSON"

bun run build >&2

bunx wrangler versions upload \
  --config "$config_path" \
  --preview-alias "$ALIAS" \
  --message "$MESSAGE" \
  2>&1 | tee "$LOG_FILE" >&2

extract_url_from_json() {
  [[ -f "$OUTPUT_JSON" ]] || return 1
  bun -e "
    const fs = require('node:fs')
    const raw = fs.readFileSync(process.argv[1], 'utf8').trim()
    if (!raw) process.exit(1)
    const data = JSON.parse(raw.split('\n').at(-1))
    const url = data.preview_alias_url || data.preview_url
    if (url) process.stdout.write(String(url))
  " "$OUTPUT_JSON"
}

extract_url_from_log() {
  grep -oE 'Version Preview Alias URL: https://[^[:space:]]+' "$LOG_FILE" \
    | head -1 \
    | sed 's/Version Preview Alias URL: //' \
    || true
}

PREVIEW_URL="$(extract_url_from_json || true)"
if [[ -z "$PREVIEW_URL" ]]; then
  PREVIEW_URL="$(extract_url_from_log || true)"
fi
if [[ -z "$PREVIEW_URL" ]]; then
  PREVIEW_URL="$(
    grep -oE 'Version Preview URL: https://[^[:space:]]+' "$LOG_FILE" \
      | head -1 \
      | sed 's/Version Preview URL: //' \
      || true
  )"
fi

if [[ -z "$PREVIEW_URL" ]]; then
  echo "FAIL: Could not extract preview URL from wrangler output" >&2
  echo "Hint: set preview_urls = true in wrangler.jsonc and enable Preview URLs on the Worker" >&2
  exit 1
fi

echo "preview_url=${PREVIEW_URL}"
echo "database_name=${database_name}"
echo "database_id=${database_id}"
