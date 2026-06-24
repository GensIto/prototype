#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: deploy-preview.sh <pr-number>}"
MESSAGE="${2:-Preview for PR #${PR_NUMBER}}"
ALIAS="pr-${PR_NUMBER}"
OUTPUT_FILE="${TMPDIR:-/tmp}/wrangler-preview-${PR_NUMBER}.log"

bun run build

bunx wrangler versions upload \
  --preview-alias "$ALIAS" \
  --message "$MESSAGE" \
  2>&1 | tee "$OUTPUT_FILE"

PREVIEW_URL="$(
  grep -oE 'Version Preview Alias URL: https://[^[:space:]]+' "$OUTPUT_FILE" \
    | head -1 \
    | sed 's/Version Preview Alias URL: //'
)"

if [[ -z "$PREVIEW_URL" ]]; then
  PREVIEW_URL="$(
    grep -oE 'Version Preview URL: https://[^[:space:]]+' "$OUTPUT_FILE" \
      | head -1 \
      | sed 's/Version Preview URL: //'
  )"
fi

if [[ -z "$PREVIEW_URL" ]]; then
  echo "FAIL: Could not extract preview URL from wrangler output"
  exit 1
fi

echo "preview_url=$PREVIEW_URL"
