#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PR_NUMBER="${1:?Usage: deploy-preview.sh <pr-number> [result-file]}"
RESULT_FILE="${2:-${TMPDIR:-/tmp}/preview-result-${PR_NUMBER}.env}"
MESSAGE="Preview for PR #${PR_NUMBER}"

ALIAS="pr-${PR_NUMBER}"
DATABASE_NAME="prottype-pr-${PR_NUMBER}"
LOG_FILE="${TMPDIR:-/tmp}/wrangler-preview-${PR_NUMBER}.log"
OUTPUT_JSON="${TMPDIR:-/tmp}/wrangler-preview-${PR_NUMBER}.json"

log() {
  echo "$*" >&2
}

load_env() {
  local file="$1"
  local key value
  while IFS='=' read -r key value; do
    [[ -z "$key" ]] && continue
    export "$key=$value"
  done <"$file"
}

write_result() {
  local preview_url="$1"
  local database_id="$2"
  cat >"$RESULT_FILE" <<EOF
preview_url=${preview_url}
database_name=${DATABASE_NAME}
database_id=${database_id}
EOF
}

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

build_fallback_preview_url() {
  local from_log
  from_log="$(
    grep -oE 'https://[a-z0-9-]+-prottype\.[a-z0-9-]+\.workers\.dev' "$LOG_FILE" \
      | head -1 \
      || true
  )"
  if [[ -n "$from_log" ]]; then
    echo "$from_log"
    return 0
  fi

  local subdomain
  subdomain="$(
    grep -oE '[a-z0-9-]+\.workers\.dev' "$LOG_FILE" \
      | head -1 \
      | sed 's/\.workers\.dev$//' \
      || true
  )"
  if [[ -n "$subdomain" ]]; then
    echo "https://${ALIAS}-prottype.${subdomain}.workers.dev"
    return 0
  fi

  return 1
}

ENV_FILE="${TMPDIR:-/tmp}/preview-d1-${PR_NUMBER}.env"
bash scripts/preview-d1.sh ensure "${PR_NUMBER}" >"$ENV_FILE"
load_env "$ENV_FILE"
bash scripts/preview-d1.sh migrate "${PR_NUMBER}"

log "Building preview for PR #${PR_NUMBER} (D1: ${DATABASE_NAME})"
bun run build >&2

BUILT_CONFIG="${ROOT}/dist/prottype/wrangler.json"
if [[ ! -f "$BUILT_CONFIG" ]]; then
  log "FAIL: ${BUILT_CONFIG} not found after build"
  exit 1
fi

config_path="$(
  bash scripts/render-wrangler-preview-config.sh "${PR_NUMBER}" "${database_id}" \
    | grep '^config_path=' \
    | cut -d= -f2-
)"
if [[ -z "$config_path" || ! -f "$config_path" ]]; then
  log "FAIL: could not render preview wrangler config"
  exit 1
fi

log "Ensuring Worker prottype exists"
bash scripts/ensure-worker.sh prottype "${BUILT_CONFIG}"

export NO_COLOR=1
export FORCE_COLOR=0
export WRANGLER_OUTPUT_FILE_PATH="$OUTPUT_JSON"

log "Uploading preview version (alias: ${ALIAS})"
upload_preview() {
  rm -f "$OUTPUT_JSON"
  bunx wrangler versions upload \
    --config "$config_path" \
    --preview-alias "$ALIAS" \
    --message "$MESSAGE" \
    2>&1 | tee "$LOG_FILE" >&2
  return "${PIPESTATUS[0]}"
}

if ! upload_preview; then
  if grep -qE '10007|does not exist on your account' "$LOG_FILE"; then
    log "Worker prottype が未作成のため初回 deploy 後に再試行します"
    bash scripts/ensure-worker.sh prottype "${BUILT_CONFIG}"
    upload_preview
  else
    exit 1
  fi
fi

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
  PREVIEW_URL="$(build_fallback_preview_url || true)"
fi

if [[ -z "$PREVIEW_URL" ]]; then
  log "FAIL: Could not extract preview URL from wrangler output"
  log "Hint: set preview_urls = true in wrangler.jsonc and enable Preview URLs on the Worker"
  exit 1
fi

if [[ -z "${database_id:-}" ]]; then
  log "FAIL: database_id is empty after D1 ensure"
  exit 1
fi

write_result "$PREVIEW_URL" "$database_id"
log "Preview ready: ${PREVIEW_URL}"
echo "preview_result_file=${RESULT_FILE}"
