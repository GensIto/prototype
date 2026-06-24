#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bun run rulesync

if ! git diff --exit-code --quiet -- .cursor/; then
  echo "FAIL: .cursor/ is out of sync with .rulesync/. Run: bun run rulesync"
  git diff -- .cursor/
  exit 1
fi

echo "rulesync:check OK"
