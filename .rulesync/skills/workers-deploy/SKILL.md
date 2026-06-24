---
name: workers-deploy
description: >-
  prottype の Cloudflare Workers 多環境デプロイ手順。
  develop / staging / production / preview（PR 単位）、GitHub Actions CI、
  wrangler.jsonc env 設定、D1・シークレットの環境分離、Workers Builds 設定時に使う。
---

# Workers 多環境デプロイ

参考: [Worker を複数環境に分けてデプロイする（Workers Builds 編）](https://zenn.dev/frontendflat/articles/workers-build-deploy)

## 環境マップ

| 環境       | Worker 名             | ブランチ  | コマンド                                              |
| ---------- | --------------------- | --------- | ----------------------------------------------------- |
| develop    | `prottype`            | `develop` | `bun run deploy:develop`                              |
| preview    | `prottype`（同一）    | PR        | GitHub Actions（推奨）または `bun run deploy:preview` |
| staging    | `prottype-staging`    | `staging` | `bun run deploy:staging`                              |
| production | `prottype-production` | `main`    | `bun run deploy:production`                           |

## wrangler.jsonc 規約

- トップレベル = **develop**（`ENVIRONMENT: development`）
- `env.staging` → Worker `prottype-staging`
- `env.production` → Worker `prottype-production`
- D1 binding 名 `DB` は全環境で統一、`database_id` で接続先を分離
- `vars` / `d1_databases` は継承されない → 各 env に明示記述
- 機密情報（`BETTER_AUTH_*`）は `wrangler secret put --env <env>` で登録（`vars` に書かない）

## デプロイ前チェックリスト

1. `wrangler.jsonc` の `database_id` が実環境と一致
2. 各 env にシークレット登録済み
3. `bun run db:migrate:remote[:staging|:production]` 実行済み
4. Workers Builds の Worker 名と wrangler の解決名が一致

## Workers Builds 設定（develop / preview）

`prottype` Worker の Builds 設定:

- 本番ブランチ: `develop`
- 非本番ブランチのビルド: **有効**
- デプロイコマンド: `bun run deploy:develop`
- 非本番ブランチのデプロイコマンド: `bun run deploy:preview`

preview は `wrangler versions upload` を使い、PR ごとに Preview URL を発行。本番トラフィックには影響しない。

**PR preview は GitHub Actions を正本とする**（Workers Builds の非本番ブランチ preview と併用可）。

## GitHub Actions（CI + PR Preview）

正本: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)

### トリガー

| イベント                               | ジョブ                |
| -------------------------------------- | --------------------- |
| PR / `main`・`develop`・`staging` push | `quality`             |
| 同一リポジトリの PR                    | `quality` → `preview` |

- `concurrency`: 同一 ref で in-progress をキャンセル
- フォーク PR は secrets 不可のため **preview はスキップ**

### quality ジョブ

```bash
bun install --frozen-lockfile
bun run lint
bun run format:check      # prettier --check .
bun run rulesync:check    # .rulesync/ → .cursor/ 同期確認
bun run test
bun run build
```

ローカル同等: `bun run ci`

### preview ジョブ

1. `quality` 成功後のみ実行
2. `scripts/deploy-preview.sh <pr-number>`:
   - `bun run build`
   - `wrangler versions upload --preview-alias pr-<番号> --message "Preview for PR #<番号>"`
   - stdout から `Version Preview Alias URL` を抽出 → `preview_url=...`
3. `actions/github-script` で PR コメント投稿（`<!-- prottype-preview -->` タグで更新）

Preview URL 形式: `https://pr-<番号>-prottype.<subdomain>.workers.dev`

### GitHub Secrets（必須）

| Secret                  | 用途                                       |
| ----------------------- | ------------------------------------------ |
| `CLOUDFLARE_API_TOKEN`  | Workers Scripts Edit 権限付き API トークン |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID                   |

develop Worker（`prottype`）に `BETTER_AUTH_*` 等が wrangler secret で登録済みであること。

### 関連ファイル

```
.github/workflows/ci.yml
scripts/deploy-preview.sh
scripts/rulesync-check.sh
.prettierignore
package.json   # format:check, rulesync:check, ci
```

## 手動デプロイ

```bash
bun run deploy:develop
bun run deploy:staging
bun run deploy:production
bun run deploy:preview    # PR preview（develop Worker 上）
```

## シークレット一括登録

```bash
wrangler secret bulk secrets.json
wrangler secret bulk secrets.json --env staging
wrangler secret bulk secrets.json --env production
```

## D1 マイグレーション

```bash
bun run db:migrate:remote              # develop
bun run db:migrate:remote:staging
bun run db:migrate:remote:production
```

## 注意

- Workers Builds 単体ではブランチの細かいフィルタ不可
- `wrangler.jsonc` を Source of truth とし、ダッシュボードでの手動変更は避ける
- 詳細: [docs/deploy.md](../../docs/deploy.md)
