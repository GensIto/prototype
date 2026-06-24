#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TOKEN_URL="https://dash.cloudflare.com/profile/api-tokens"
TOKEN_TEMPLATE_HINT="Create Custom Token → Account: Workers Scripts Edit + D1 Edit"

require_wrangler_login() {
  if ! bunx wrangler whoami --json >/dev/null 2>&1; then
    echo "FAIL: wrangler に未ログインです。先に実行してください:" >&2
    echo "  bunx wrangler login" >&2
    exit 1
  fi
}

fetch_account_id() {
  bunx wrangler whoami --json \
    | bun -e "
        const fs = require('node:fs')
        const data = JSON.parse(fs.readFileSync(0, 'utf8'))
        const accounts = data.accounts ?? []
        if (accounts.length === 0) process.exit(1)
        if (accounts.length === 1) {
          process.stdout.write(String(accounts[0].id))
          process.exit(0)
        }
        const filter = process.env.CLOUDFLARE_ACCOUNT_ID
        if (filter) {
          const match = accounts.find((a) => a.id === filter)
          if (match) {
            process.stdout.write(String(match.id))
            process.exit(0)
          }
        }
        console.error('複数アカウントがあります。CLOUDFLARE_ACCOUNT_ID で対象を指定するか、whoami 出力から選んでください:')
        for (const account of accounts) {
          console.error(\`  \${account.name}: \${account.id}\`)
        }
        process.exit(1)
      "
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "FAIL: GitHub CLI (gh) が見つかりません。" >&2
    echo "  brew install gh && gh auth login" >&2
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "FAIL: gh に未ログインです。先に実行してください:" >&2
    echo "  gh auth login" >&2
    exit 1
  fi
}

read_api_token() {
  if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "$CLOUDFLARE_API_TOKEN"
    return 0
  fi

  echo "Cloudflare API トークンを入力してください（Workers Scripts Edit + D1 Edit）:" >&2
  echo "作成: ${TOKEN_URL}" >&2
  echo "  ${TOKEN_TEMPLATE_HINT}" >&2
  read -r -s token
  echo >&2
  if [[ -z "$token" ]]; then
    echo "FAIL: API トークンが空です" >&2
    exit 1
  fi
  echo "$token"
}

print_manual_steps() {
  local account_id="$1"
  echo
  echo "=== 手動登録（gh を使わない場合）==="
  echo "GitHub → リポジトリ Settings → Secrets and variables → Actions"
  echo
  echo "  CLOUDFLARE_ACCOUNT_ID = ${account_id}"
  echo "  CLOUDFLARE_API_TOKEN  = （${TOKEN_URL} で作成したトークン）"
  echo
  echo "登録後、PR の Actions を Re-run してください。"
}

main() {
  require_wrangler_login
  ACCOUNT_ID="$(fetch_account_id)"

  echo "Account ID: ${ACCOUNT_ID}"

  if [[ "${1:-}" == "--print-only" ]]; then
    print_manual_steps "$ACCOUNT_ID"
    exit 0
  fi

  API_TOKEN="$(read_api_token)"

  if [[ "${1:-}" == "--manual" ]]; then
    print_manual_steps "$ACCOUNT_ID"
    exit 0
  fi

  require_gh
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

  echo "Registering secrets on ${REPO} ..."
  printf '%s' "$API_TOKEN" | gh secret set CLOUDFLARE_API_TOKEN --repo "$REPO"
  printf '%s' "$ACCOUNT_ID" | gh secret set CLOUDFLARE_ACCOUNT_ID --repo "$REPO"

  echo "Done."
  echo "  CLOUDFLARE_ACCOUNT_ID → ${ACCOUNT_ID}"
  echo "  CLOUDFLARE_API_TOKEN  → registered"
  echo
  echo "PR の Actions を Re-run して preview ジョブを確認してください。"
}

main "$@"
