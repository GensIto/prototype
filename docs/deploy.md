# デプロイ・環境構成

Workers Builds で **develop / staging / production / preview（PR 単位）** の 4 段階デプロイを行う。

参考: [Worker を複数環境に分けてデプロイする（Workers Builds 編）](https://zenn.dev/frontendflat/articles/workers-build-deploy)

## 環境一覧

| 環境       | 用途        | Worker 名                 | Git ブランチ   | デプロイ方式               |
| ---------- | ----------- | ------------------------- | -------------- | -------------------------- |
| develop    | 開発・統合  | `prottype`                | `develop`      | Workers Builds 自動        |
| preview    | PR レビュー | `prottype`（同一 Worker） | `feature/*` 等 | `wrangler versions upload` |
| staging    | QA・受入    | `prottype-staging`        | `staging`      | Workers Builds 自動        |
| production | 本番        | `prottype-production`     | `main`         | Workers Builds 自動        |

## wrangler.jsonc の構造

- **トップレベル** = develop 環境（Worker 名 `prottype`）
- **`env.staging`** → Worker 名 `prottype-staging`（`<name>-staging`）
- **`env.production`** → Worker 名 `prottype-production`（`<name>-production`）

継承ルール:

- 継承可能: `main`, `compatibility_date`, `compatibility_flags`, `observability` 等
- 継承不可（各 env で個別設定）: `vars`, `d1_databases` 等のバインディング

D1 は環境ごとに **binding 名 `DB` は統一**、**database_id で接続先を分離**。

## 初回セットアップ

### 1. D1 データベース作成

```bash
wrangler d1 create prottype
wrangler d1 create prottype-staging
wrangler d1 create prottype-production
```

出力された `database_id` を `wrangler.jsonc` の各 env に反映する。

### 2. リモートマイグレーション

```bash
bun run db:migrate:remote              # develop
bun run db:migrate:remote:staging
bun run db:migrate:remote:production
```

### 3. シークレット登録

`BETTER_AUTH_SECRET` / `BETTER_AUTH_URL` は環境ごとに異なる値を設定する。

```bash
# 個別登録
wrangler secret put BETTER_AUTH_SECRET
wrangler secret put BETTER_AUTH_SECRET --env staging
wrangler secret put BETTER_AUTH_SECRET --env production

# 一括登録（secrets.json を用意）
wrangler secret bulk secrets.json
wrangler secret bulk secrets.json --env staging
wrangler secret bulk secrets.json --env production
```

`secrets.example.json` をコピーして各環境用の JSON を作成する。

### 4. 手動デプロイ（Workers Builds 接続前）

Workers Builds では **先に wrangler deploy で Worker を作成**してから Git 連携する。

```bash
bun run deploy:develop
bun run deploy:staging
bun run deploy:production
```

## Workers Builds ダッシュボード設定

各 Worker を Cloudflare ダッシュボード → **Settings > Builds** で Git リポジトリに接続する。

**重要**: ダッシュボード上の Worker 名と `wrangler.jsonc` が解決する Worker 名が一致していること。

| Worker 名             | 本番ブランチ | 非本番ブランチのビルド | デプロイコマンド            | 非本番ブランチのデプロイコマンド |
| --------------------- | ------------ | ---------------------- | --------------------------- | -------------------------------- |
| `prottype`            | `develop`    | **無効**               | `bun run deploy:develop`    | —                                |
| `prottype-staging`    | `staging`    | 無効                   | `bun run deploy:staging`    | —                                |
| `prottype-production` | `main`       | 無効                   | `bun run deploy:production` | —                                |

### preview（PR 単位）の仕組み

PR Preview は **GitHub Actions** が担当する（Workers Builds ではない）。

1. `prottype-pr-<PR番号>` という D1 を作成（既存なら再利用）
2. マイグレーションを適用
3. PR 専用 `wrangler.preview.pr-<番号>.jsonc` で `wrangler versions upload`
4. PR コメントに Preview URL と D1 名を投稿
5. **PR クローズ時**（マージ / 未マージ）に D1 を削除

develop Worker（`prottype`）のシークレット（`BETTER_AUTH_*`）は Preview バージョンでも継承される。Auth の `baseURL` はリクエスト origin を使うため Preview URL でもログイン可能。

**Workers Builds の非本番ブランチビルドは無効** にすること。有効だと develop D1 を使う preview が二重実行される。

[Build branches 公式ドキュメント](https://developers.cloudflare.com/workers/ci-cd/builds/build-branches/)

## ローカル開発

```bash
cp .dev.vars.example .dev.vars
bun run db:setup
bun run dev
```

## 制約

Workers Builds のブランチ制御は「本番ブランチ 1 つ + 非本番ブランチ有効/無効」のみ。

- develop Worker の非本番ブランチビルド有効時、`staging` / `main` への push でも preview ビルドが走る可能性がある
- 細かいブランチフィルタが必要な場合は GitHub Actions + Wrangler を検討

## GitHub Actions

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) で CI と **PR 専用 Preview（D1 分離）** を実行する。

### CI（quality ジョブ）

- `bun run lint`
- `bun run format:check`
- `bun run rulesync:check` — `bun run rulesync` 後に `.cursor/` に diff がないこと
- `bun run test`
- `bun run build`

ローカルで同等チェック: `bun run ci`

### PR Preview（preview ジョブ）

- `quality` 成功後のみ実行
- フォーク PR は secrets 不可のため **スキップ**
- フロー:
  1. `scripts/preview-d1.sh ensure <pr>` — D1 `prottype-pr-<番号>` 作成
  2. `scripts/preview-d1.sh migrate <pr>` — マイグレーション適用
  3. `scripts/deploy-preview.sh <pr>` — Preview デプロイ
  4. PR コメントに Preview URL / D1 名を投稿

### Preview クリーンアップ（preview-cleanup ジョブ）

- PR **クローズ時**（マージ / 未マージ）に `scripts/preview-d1.sh delete <pr>` で D1 を削除

### GitHub Secrets

| Name                    | 説明                                                                                                           |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | D1 作成・削除、Workers Scripts Edit（[ダッシュボード](https://dash.cloudflare.com/profile/api-tokens) で作成） |
| `CLOUDFLARE_ACCOUNT_ID` | アカウント ID（`wrangler whoami` で取得）                                                                      |

登録:

```bash
bunx wrangler login
gh auth login
bun run setup:github-secrets
```

詳細: skill `github-secrets-setup`、[README.md](../README.md#6-github-secretspr-preview-用)

#### 手動で PR preview を試す場合

```bash
export CLOUDFLARE_API_TOKEN=...
export CLOUDFLARE_ACCOUNT_ID=...
bash scripts/deploy-preview.sh <pr-number>
bash scripts/preview-d1.sh delete <pr-number>   # 後片付け
```

## 関連

- [Cloudflare Workers Builds](https://developers.cloudflare.com/workers/ci-cd/builds/)
- [Wrangler environments](https://developers.cloudflare.com/workers/wrangler/environments/)
