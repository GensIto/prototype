# prottype

Cloudflare Workers + Hono + Inertia.js + React 19 + D1 + Better Auth + Drizzle ORM

## セットアップ

```bash
bun install
cp .dev.vars.example .dev.vars   # シークレットを編集
bun run db:setup
bun run dev
```

## スクリプト

| コマンド                    | 説明                                    |
| --------------------------- | --------------------------------------- |
| `bun run dev`               | Vite 開発サーバー                       |
| `bun run build`             | 本番ビルド                              |
| `bun run deploy:develop`    | develop 環境へデプロイ                  |
| `bun run deploy:staging`    | staging 環境へデプロイ                  |
| `bun run deploy:production` | production 環境へデプロイ               |
| `bun run deploy:preview`    | PR preview（versions upload）           |
| `bun run test`              | Vitest 単体テスト                       |
| `bun run lint`              | ESLint                                  |
| `bun run format:check`      | Prettier チェック（CI 用）              |
| `bun run rulesync:check`    | `.rulesync/` と `.cursor/` 同期確認     |
| `bun run ci`                | lint + format + rulesync + test + build |
| `bun run db:setup`          | Auth スキーマ生成 + マイグレーション    |
| `bun run rulesync`          | `.rulesync/` → `.cursor/` へ同期        |

## ドキュメント

- [技術スタック](./docs/stack.md)
- [アーキテクチャ](./docs/architecture.md)
- [デプロイ・環境構成](./docs/deploy.md)
- [QA・テスト設計](./docs/qa.md)
- [Todo 実装サンプル](./docs/example-todo.md)

## AI エージェント設定

`.rulesync/` がソースオブトゥルース。`bun run rulesync` で `.cursor/` に生成される。

### 0から再現性の検証

clone ではなく **空ディレクトリ + skills だけ** で同じ構成を作れるか確認する手順:

- [docs/bootstrap-verify.md](./docs/bootstrap-verify.md)
- skill `prottype-bootstrap`
- 検収: `bun run verify:repro`
- skills パック作成: `bun run skills:pack`

## CI / PR Preview

GitHub Actions（[`.github/workflows/ci.yml`](./.github/workflows/ci.yml)）:

| トリガー                               | 内容                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| PR / `main`・`develop`・`staging` push | lint, format:check, rulesync:check, test, build                                                                 |
| PR（同一リポジトリ）                   | 上記 PASS 後、`wrangler versions upload --preview-alias pr-<番号>` で Preview デプロイ → PR コメントに URL 投稿 |

### 必要な GitHub Secrets

| Secret                  | 用途                                                                 |
| ----------------------- | -------------------------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | Workers への preview upload（`Account → Workers Scripts → Edit` 等） |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID                                             |

develop Worker（`prottype`）に `BETTER_AUTH_*` 等のシークレットが登録済みであること。Preview は本番トラフィックに影響しません。

詳細: [docs/deploy.md](./docs/deploy.md#github-actions)
