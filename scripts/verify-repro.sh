#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> rulesync"
bun run rulesync

echo "==> lint"
bun run lint

echo "==> test"
bun run test

echo "==> build"
bun run build

echo "==> file checklist"
REQUIRED=(
  app/server.ts
  app/core/result.ts
  app/core/result.test.ts
  .rulesync/skills/prottype-bootstrap/SKILL.md
  .rulesync/skills/qa-review/SKILL.md
  .rulesync/skills/prottype-stack/SKILL.md
  .cursor/skills/qa-review/SKILL.md
  docs/bootstrap-verify.md
  wrangler.jsonc
)

for f in "${REQUIRED[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    exit 1
  fi
done

grep -q 'env.staging' wrangler.jsonc
grep -q 'env.production' wrangler.jsonc

if grep -E '"[^"]+": "\^' package.json 2>/dev/null; then
  echo "FAIL: package.json contains ^ version ranges"
  exit 1
fi

echo "==> verify:repro OK"
