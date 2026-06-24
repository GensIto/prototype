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
| `prottype`            | `develop`    | **有効**               | `bun run deploy:develop`    | `bun run deploy:preview`         |
| `prottype-staging`    | `staging`    | 無効                   | `bun run deploy:staging`    | —                                |
| `prottype-production` | `main`       | 無効                   | `bun run deploy:production` | —                                |

### preview（PR 単位）の仕組み

develop Worker（`prottype`）のみ非本番ブランチのビルドを有効にする。

- `develop` ブランチ push → `bun run deploy:develop` → develop 環境へデプロイ
- それ以外のブランチ（`feature/*` 等）push → `bun run deploy:preview` → `wrangler versions upload`
  - 本番トラフィックに影響しない Preview URL が PR に表示される

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

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) で CI と PR preview を実行する。

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
- `scripts/deploy-preview.sh` → `wrangler versions upload --preview-alias pr-<番号>`
- Preview URL を PR コメントに投稿（`<!-- prottype-preview -->` タグで更新）

### GitHub Secrets

| Name                    | 説明                                 |
| ----------------------- | ------------------------------------ |
| `CLOUDFLARE_API_TOKEN`  | API トークン（Workers Scripts Edit） |
| `CLOUDFLARE_ACCOUNT_ID` | アカウント ID                        |

Workers Builds と併用可能。PR preview のみ GitHub Actions、develop/staging/production は Workers Builds でもよい。

## 関連

- [Cloudflare Workers Builds](https://developers.cloudflare.com/workers/ci-cd/builds/)
- [Wrangler environments](https://developers.cloudflare.com/workers/wrangler/environments/)
