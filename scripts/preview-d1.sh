#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=d1-helpers.sh
source "${ROOT}/scripts/d1-helpers.sh"

COMMAND="${1:?Usage: preview-d1.sh <ensure|migrate|delete> <pr-number>}"
PR_NUMBER="${2:?Usage: preview-d1.sh <command> <pr-number>}"

DB_NAME="prottype-pr-${PR_NUMBER}"

require_cloudflare_env() {
  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" || -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    echo "FAIL: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID are required" >&2
    echo "GitHub Actions: Settings → Secrets and variables → Actions に両方を登録してください" >&2
    exit 1
  fi
}

database_id() {
  lookup_d1_id "$DB_NAME"
}

ensure_database() {
  require_cloudflare_env

  id="$(ensure_remote_d1 "$DB_NAME")"
  echo "database_name=${DB_NAME}"
  echo "database_id=${id}"
}

migrate_database() {
  require_cloudflare_env
  bunx wrangler d1 migrations apply "$DB_NAME" --remote >&2
}

delete_database() {
  require_cloudflare_env

  if ! id="$(database_id)"; then
    echo "skip: database ${DB_NAME} not found" >&2
    return 0
  fi

  bunx wrangler d1 delete "$DB_NAME" --skip-confirmation >&2
  echo "deleted: ${DB_NAME} (${id})" >&2
}

case "$COMMAND" in
  ensure)
    ensure_database
    ;;
  migrate)
    migrate_database
    ;;
  delete)
    delete_database
    ;;
  *)
    echo "FAIL: unknown command: ${COMMAND}" >&2
    exit 1
    ;;
esac
