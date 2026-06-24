#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BACKUP="${1:?Usage: restore-wrangler-preview-config.sh <backup-path>}"
BUILT_CONFIG="${ROOT}/dist/prottype/wrangler.json"

if [[ -f "$BACKUP" ]]; then
  mv "$BACKUP" "$BUILT_CONFIG"
fi
