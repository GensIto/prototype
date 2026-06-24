---
name: workers-deploy
description: prottype の Cloudflare Workers 多環境デプロイ手順。 develop / staging / production / preview（PR 単位・D1 分離）、GitHub Actions CI、 wrangler.jsonc env 設定、D1・シークレットの環境分離、Workers Builds 設定時に使う。
---

# Workers 多環境デプロイ

参考: [Worker を複数環境に分けてデプロイする（Workers Builds 編）](https://zenn.dev/frontendflat/articles/workers-build-deploy)

## 環境マップ

| 環境       | Worker 名             | ブランチ  | D1                           | デプロイ方式        |
| ---------- | --------------------- | --------- | ---------------------------- | ------------------- |
| develop    | `prottype`            | `develop` | `prottype`                   | Workers Builds 自動 |
| preview    | `prottype`（同一）    | PR        | `prottype-pr-<番号>`（専用） | GitHub Actions      |
| staging    | `prottype-staging`    | `staging` | `prottype-staging`           | Workers Builds 自動 |
| production | `prottype-production` | `main`    | `prottype-production`        | Workers Builds 自動 |

## wrangler.jsonc 規約

- トップレベル = **develop**（`ENVIRONMENT: development`）
- `env.staging` → Worker `prottype-staging`
- `env.production` → Worker `prottype-production`
- D1 binding 名 `DB` は全環境で統一、`database_id` で接続先を分離
- `preview_urls: true` を設定（Preview URL 生成のため）
- `vars` / `d1_databases` は継承されない → 各 env に明示記述
- 機密情報（`BETTER_AUTH_*`）は `wrangler secret put --env <env>` で登録（`vars` に書かない）

## デプロイ前チェックリスト

1. `wrangler.jsonc` の `database_id` が実環境と一致
2. 各 env にシークレット登録済み
3. `bun run db:migrate:remote[:staging|:production]` 実行済み
4. Workers Builds の Worker 名と wrangler の解決名が一致

## Workers Builds 設定（develop / staging / production）

`prottype` Worker の Builds 設定:

- 本番ブランチ: `develop`
- 非本番ブランチのビルド: **無効**（PR preview は GitHub Actions が担当）
- デプロイコマンド: `bun run deploy:develop`

**PR preview は Workers Builds では行わない。** 非本番ブランチビルドを有効にすると develop D1 を使う preview が GHA と二重実行される。

## GitHub Actions（CI + PR Preview）

正本: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)

### トリガー

| イベント                               | ジョブ                       |
| -------------------------------------- | ---------------------------- |
| PR / `main`・`develop`・`staging` push | `quality`                    |
| 同一リポジトリの PR（open/sync）       | `quality` → `preview`        |
| PR クローズ（マージ / 未マージ）       | `preview-cleanup`（D1 削除） |

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

### preview ジョブ（D1 分離）

1. `quality` 成功後のみ実行
2. `scripts/preview-d1.sh ensure <pr>` — D1 `prottype-pr-<番号>` を作成（既存なら再利用）
3. `scripts/preview-d1.sh migrate <pr>` — マイグレーション適用
4. `scripts/render-wrangler-preview-config.sh` — PR 専用 wrangler 設定を生成
5. `scripts/ensure-worker.sh` — Worker `prottype` が未作成なら初回 `wrangler deploy`
6. `wrangler versions upload --preview-alias pr-<番号>` — Preview デプロイ
7. PR コメントに Preview URL / D1 名を投稿

Auth はリクエスト origin を `baseURL` に使うため Preview URL でもログイン可能。`BETTER_AUTH_SECRET` は develop Worker の secret を継承。

### preview-cleanup ジョブ

- PR **クローズ時**（マージ / 未マージ）に `scripts/preview-d1.sh delete <pr>` で D1 を削除

### GitHub Secrets（preview 用）

| Secret                  | 用途                                |
| ----------------------- | ----------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | D1 作成・削除、Workers Scripts Edit |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID            |

登録手順: skill **`github-secrets-setup`**

```bash
bunx wrangler login
gh auth login
bun run setup:github-secrets
```

- Account ID … `wrangler whoami --json` で取得（CLI 可）
- API トークン … [ダッシュボード](https://dash.cloudflare.com/profile/api-tokens) で Workers Scripts Edit + D1 Edit（CLI 不可）
- GitHub 登録 … `gh secret set`（`scripts/setup-github-secrets.sh`）

### 関連ファイル

```
.github/workflows/ci.yml
scripts/deploy-preview.sh
scripts/ensure-worker.sh
scripts/preview-d1.sh
scripts/render-wrangler-preview-config.sh
scripts/rulesync-check.sh
.prettierignore
package.json   # format:check, rulesync:check, ci
```

## 手動デプロイ

```bash
bun run deploy:develop
bun run deploy:staging
bun run deploy:production

# PR preview（要 CLOUDFLARE_* env）
bash scripts/deploy-preview.sh <pr-number>
bash scripts/preview-d1.sh delete <pr-number>
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
- D1 はアカウントあたりの上限あり。PR クローズ後の削除漏れに注意
- 詳細: [docs/deploy.md](../../docs/deploy.md)
