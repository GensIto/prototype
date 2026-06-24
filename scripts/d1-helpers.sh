#!/usr/bin/env bash
set -euo pipefail

# Shared D1 helpers. Do not use `wrangler d1 info` here — it reads database_id
# from wrangler.jsonc and fails while placeholders are still configured.

lookup_d1_id() {
  local name="$1"
  bunx wrangler d1 list --json 2>/dev/null \
    | bun -e "
        const fs = require('node:fs')
        const name = process.argv[1]
        const input = fs.readFileSync(0, 'utf8').trim()
        if (!input) process.exit(1)
        const dbs = JSON.parse(input)
        const match = dbs.find((db) => db.name === name)
        const id = match?.uuid ?? match?.database_id
        if (!id) process.exit(1)
        process.stdout.write(String(id))
      " "$name"
}

ensure_remote_d1() {
  local name="$1"

  if id="$(lookup_d1_id "$name" 2>/dev/null || true)" && [[ -n "$id" ]]; then
    echo "exists: ${name} (${id})" >&2
    echo "$id"
    return 0
  fi

  echo "creating: ${name}" >&2
  if ! bunx wrangler d1 create "$name" --update-config=false >&2; then
    echo "create skipped or failed for ${name}, checking list again..." >&2
  fi

  id="$(lookup_d1_id "$name")"
  echo "$id"
}
