# prottype

Cloudflare Workers + Hono + Inertia.js + React 19 + D1 + Better Auth + Drizzle ORM

## 前提

- [Bun](https://bun.sh/) 1.2+（`package.json` の `packageManager` に合わせる）
- Node 20+（`npx` / Better Auth CLI 用）

## プロジェクトの立ち上げ（ローカル開発）

### 1. リポジトリを取得

```bash
git clone <repository-url>
cd prottype
```

### 2. 依存関係をインストール

```bash
bun install
```

### 3. 環境変数を設定

```bash
cp .dev.vars.example .dev.vars
```

`.dev.vars` を編集する:

| 変数                 | 例                          | 説明             |
| -------------------- | --------------------------- | ---------------- |
| `BETTER_AUTH_SECRET` | 32 文字以上のランダム文字列 | セッション暗号化 |
| `BETTER_AUTH_URL`    | `http://localhost:5173`     | ローカル開発 URL |

シークレット生成例:

```bash
openssl rand -base64 32
```

### 4. データベースをセットアップ

Auth スキーマ生成 → Drizzle マイグレーション → ローカル D1 に適用:

```bash
bun run db:setup
```

### 5. 開発サーバーを起動

```bash
bun run dev
```

ブラウザで `http://localhost:5173` を開く。サインアップ / サインイン → Todo CRUD まで試せる。

### 6. AI エージェント設定（Cursor 利用時）

`.rulesync/` がソースオブトゥルース。Skills / Rules を `.cursor/` に同期:

```bash
bun run rulesync
```

以降、`.rulesync/` を編集したら `bun run rulesync` を再実行する。CI では `bun run rulesync:check` で同期漏れを検知する。

---

## Cloudflare リモート環境のセットアップ（任意）

develop / staging / production へのデプロイ、PR Preview を使う場合のみ必要。

### 1. D1 データベースを作成

```bash
wrangler login   # 未ログインの場合
bun run setup:remote-d1
```

`wrangler.jsonc` のプレースホルダー `database_id`（`00000000-...`）を、Cloudflare 上の実 ID に自動反映する。

手動で行う場合:

```bash
wrangler d1 create prottype
wrangler d1 create prottype-staging
wrangler d1 create prottype-production
# 出力された database_id を wrangler.jsonc に反映
```

### 2. リモートマイグレーション

```bash
bun run db:migrate:remote              # develop
bun run db:migrate:remote:staging
bun run db:migrate:remote:production
```

### 3. シークレットを登録

`secrets.example.json` をコピーして各環境用の値を設定:

```bash
wrangler secret bulk secrets.json
wrangler secret bulk secrets.json --env staging
wrangler secret bulk secrets.json --env production
```

`BETTER_AUTH_URL` は各環境の Worker URL（例: `https://prottype.<account>.workers.dev`）に合わせる。

### 4. 初回デプロイ

```bash
bun run deploy:develop
bun run deploy:staging
bun run deploy:production
```

### 5. Workers Builds（develop / staging / production）

Cloudflare ダッシュボード → 各 Worker → **Settings > Builds** で GitHub リポジトリを接続。

| Worker                | 本番ブランチ | 非本番ブランチビルド | デプロイコマンド            |
| --------------------- | ------------ | -------------------- | --------------------------- |
| `prottype`            | `develop`    | **無効**             | `bun run deploy:develop`    |
| `prottype-staging`    | `staging`    | 無効                 | `bun run deploy:staging`    |
| `prottype-production` | `main`       | 無効                 | `bun run deploy:production` |

**PR Preview は GitHub Actions が担当**するため、`prottype` Worker の非本番ブランチビルドは無効にすること。

**Workers Builds の Worker 名は `wrangler.jsonc` の `name`（`prottype`）と一致させること。** ダッシュボード上が `prototype` など別名だとデプロイが失敗する。

### 6. GitHub Secrets（PR Preview 用）

リポジトリ Settings → Secrets and variables → Actions:

| Secret                  | 用途                                  |
| ----------------------- | ------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | D1 作成・削除、Workers preview upload |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID              |

---

## スクリプト

| コマンド                    | 説明                                    |
| --------------------------- | --------------------------------------- |
| `bun run dev`               | Vite 開発サーバー                       |
| `bun run build`             | 本番ビルド                              |
| `bun run deploy:develop`    | develop 環境へデプロイ                  |
| `bun run deploy:staging`    | staging 環境へデプロイ                  |
| `bun run deploy:production` | production 環境へデプロイ               |
| `bun run test`              | Vitest 単体テスト                       |
| `bun run lint`              | ESLint                                  |
| `bun run format:check`      | Prettier チェック（CI 用）              |
| `bun run rulesync:check`    | `.rulesync/` と `.cursor/` 同期確認     |
| `bun run ci`                | lint + format + rulesync + test + build |
| `bun run db:setup`          | Auth スキーマ生成 + マイグレーション    |
| `bun run rulesync`          | `.rulesync/` → `.cursor/` へ同期        |

---

## CI / PR Preview

GitHub Actions（[`.github/workflows/ci.yml`](./.github/workflows/ci.yml)）:

| トリガー                               | 内容                                                                 |
| -------------------------------------- | -------------------------------------------------------------------- |
| PR / `main`・`develop`・`staging` push | lint, format:check, rulesync:check, test, build                      |
| PR（同一リポジトリ）                   | 上記 PASS 後、**PR 専用 D1** を作成 → Preview デプロイ → PR コメント |
| PR クローズ（マージ / 未マージ）       | Preview 用 D1（`prottype-pr-<番号>`）を削除                          |

PR Preview は **D1 も PR 単位で分離** される。develop / staging / production の DB とはコンフリクトしない。

詳細: [docs/deploy.md](./docs/deploy.md#github-actions)

---

## トラブルシューティング

### `D1 binding 'DB' references database '00000000-...' which was not found`

**原因:** `wrangler.jsonc` の `database_id` がプレースホルダーのまま。Workers Builds / `deploy:develop` が存在しない D1 を参照している。

**対処:**

```bash
wrangler login
bun run setup:remote-d1
bun run db:migrate:remote
bun run deploy:develop
```

変更した `wrangler.jsonc` を commit / push する。

### Workers Builds が PR ブランチでも動いてしまう

`prottype` Worker → Settings → Builds → **非本番ブランチのビルドを無効**にする。PR Preview は GitHub Actions が担当。

---

## ドキュメント

- [技術スタック](./docs/stack.md)
- [アーキテクチャ](./docs/architecture.md)
- [デプロイ・環境構成](./docs/deploy.md)
- [QA・テスト設計](./docs/qa.md)
- [Todo 実装サンプル](./docs/example-todo.md)

## 0 から再現性の検証

clone ではなく **空ディレクトリ + skills だけ** で同じ構成を作れるか確認する手順:

- [docs/bootstrap-verify.md](./docs/bootstrap-verify.md)
- skill `prottype-bootstrap`
- 検収: `bun run verify:repro`
- skills パック作成: `bun run skills:pack`
