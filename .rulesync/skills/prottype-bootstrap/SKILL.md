---
name: prottype-bootstrap
description: >-
  prottype の立ち上げ手順。clone 後のローカル開発セットアップ、または空ディレクトリからの 0→1 再現。
  Hono, Inertia, React 19, D1, Drizzle, Better Auth, rulesync, QA skills, 多環境デプロイ・PR Preview（D1 分離）を含む。
  新規プロジェクト立ち上げ、既存リポジトリの初期セットアップ、再現性検証時に使う。
---

# prottype ブートストラップ

## 既存リポジトリの立ち上げ（clone 後）

README と同じ手順。ローカル開発だけなら Cloudflare リモート設定は不要。

```bash
git clone <repository-url> && cd prottype
bun install
cp .dev.vars.example .dev.vars   # BETTER_AUTH_* を編集
bun run db:setup
bun run rulesync                 # Cursor skills / rules 同期
bun run dev                      # http://localhost:5173
```

検収: `bun run ci` が PASS。

Cloudflare デプロイ・PR Preview を使う場合は README の「Cloudflare リモート環境のセットアップ」および skill `workers-deploy` を参照。

---

## 0→1 再現（空ディレクトリ）

空ディレクトリから本リポジトリ相当の構成を再現する手順。**clone しない。**

## 前提

- Bun 1.2+
- Node 20+（npx 用）
- 作業ディレクトリは空（または `mkdir prottype && cd prottype`）

## フェーズ概要

| Phase | 内容                              | 完了判定                                   |
| ----- | --------------------------------- | ------------------------------------------ |
| 1     | Wrangler + Hono 最小 Worker       | `wrangler dev` 相当が起動                  |
| 2     | Vite + Inertia + React + Tailwind | `bun run dev` で Landing                   |
| 3     | D1 + Drizzle + Better Auth        | `bun run db:setup` 成功                    |
| 4     | rulesync + 全 skills + docs       | `bun run rulesync` で `.cursor/` 生成      |
| 5     | 多環境 wrangler + QA 構成         | `wrangler.jsonc` に env.staging/production |
| 6     | 検収                              | 下記 Acceptance を全 PASS                  |

## Phase 1 — 最小 Worker

```bash
bun init -y
bun add hono
bun add -d wrangler typescript
```

`wrangler.jsonc`: `main: ./app/server.ts`, `compatibility_date` 最新, `nodejs_compat`

`app/server.ts`: Hono hello → 後で Phase 2 で差し替え

## Phase 2 — フルスタック FE

依存は **exact pin**（`package.json` 参照）。主要:

```
@cloudflare/vite-plugin @hono/inertia @hono/zod-validator
@inertiajs/react react react-dom vite-ssr-components
@tailwindcss/vite tailwindcss drizzle-orm drizzle-zod zod@4
better-auth @better-auth/drizzle-adapter
```

Zod は **4.x を exact pin**（例: `"zod": "4.4.3"`）。`import { z } from 'zod'` = v4 API。

作成ファイル（最低限）:

```
app/server.ts          # inertia + auth + routes
app/client.tsx
app/root-view.tsx
app/pages/Home.tsx
app/components/home/home-view.tsx
app/components/ui/button.tsx
app/routes/home/index.ts
app/routes/types.ts
app/styles.css
app/utils/cn.ts
vite.config.ts         # react, tailwind, inertiaPages, cloudflare, ssrPlugin
tsconfig.json          # paths @/* → app/*
components.json        # shadcn new-york
eslint.config.js       # import 境界（prottype-stack 参照）
.prettierrc
```

`vite.config.ts` の `inertiaPages`: `pagesDir: app/pages`, `outFile: app/pages.gen.ts`

## Phase 3 — D1 + Auth

`wrangler.jsonc` に `d1_databases`（binding `DB`）

```
app/db/index.ts
app/db/schema/index.ts
app/db/schema/auth/index.ts    # better-auth CLI 生成可
app/modules/auth/create-auth.ts
app/modules/auth/middleware.ts
app/core/result.ts + result.test.ts
app/modules/validation/
  zod-result.ts              # zodToResult, safeParseToResult
  form-errors.ts             # zodToFormErrors
drizzle.config.ts
migrations/
env.d.ts                       # BETTER_AUTH_*, ENVIRONMENT
.dev.vars.example
```

```bash
cp .dev.vars.example .dev.vars
bun run db:setup   # auth:schema → db:generate → db:migrate:local
```

### Phase 3b — Todo 参照実装（推奨）

新機能追加時の雛形として Todo モジュールを追加する。詳細: [docs/example-todo.md](../../docs/example-todo.md)

```
app/db/schema/todo/
app/modules/todo/              # todo 名前空間, ITodoRepository, D1 adapter
app/db/zod/todo/views.ts       # zTodoTitle, zCreateTodoBody, zTodoView
app/db/zod/todo/views.test.ts
app/routes/todos/
app/pages/Todos/Index.tsx
app/components/todos/
docs/example-todo.md
```

Better Auth MCP（任意）: `bunx @better-auth/cli mcp --cursor`  
プロジェクト MCP 正本: `.rulesync/mcp.json`（Phase 4）

## Phase 4 — rulesync + skills + docs

```bash
bun add -d rulesync
```

```
rulesync.jsonc
.rulesync/
  rules/project.md
  mcp.json
  skills/
    prottype-stack/SKILL.md
    lightweight-ddd-tdd/SKILL.md
    workers-deploy/SKILL.md
    github-secrets-setup/SKILL.md
    qa-personas/SKILL.md
    test-case-creation/SKILL.md
    qa-review/SKILL.md
    migration-test-creation/SKILL.md
    better-auth-best-practices/SKILL.md
docs/stack.md architecture.md deploy.md qa.md bootstrap-verify.md
qa/master/ qa/artifacts/
```

各 skill の中身は **本リポジトリの `.rulesync/skills/<name>/SKILL.md` と同一** にする（検証時は tarball からコピー可）。

```bash
bun run rulesync
```

## Phase 5 — 多環境デプロイ

`wrangler.jsonc` トップ = develop、 `env.staging` / `env.production`  
各 env に `vars.ENVIRONMENT` と独立 `d1_databases`（binding `DB` 統一）

`package.json` scripts:

```
deploy:develop / deploy:staging / deploy:production / deploy:preview
format:check / rulesync:check / ci
db:migrate:remote[:staging|:production]
rulesync / verify:repro
```

詳細: skill `workers-deploy`, [Zenn Workers Builds](https://zenn.dev/frontendflat/articles/workers-build-deploy)

## Phase 5b — GitHub Actions（CI + PR Preview・D1 分離）

```
.github/workflows/ci.yml
scripts/deploy-preview.sh
scripts/preview-d1.sh
scripts/render-wrangler-preview-config.sh
scripts/rulesync-check.sh
.prettierignore
.gitignore                    # wrangler.preview.*.jsonc
```

`wrangler.jsonc` に `preview_urls: true` を設定。

`app/modules/auth/create-auth.ts` は Preview URL 対応のため、リクエスト origin を `baseURL` に使う（`middleware.ts` から `requestUrl` を渡す）。

`package.json` に追加:

```json
"format:check": "prettier --check .",
"rulesync:check": "bash scripts/rulesync-check.sh",
"ci": "bun run lint && bun run format:check && bun run rulesync:check && bun run test && bun run build"
```

`ci.yml` ジョブ構成:

| ジョブ            | トリガー                                                                 |
| ----------------- | ------------------------------------------------------------------------ |
| `quality`         | PR / main・develop・staging push                                         |
| `preview`         | 同一リポジトリ PR（open/sync）— PR 専用 D1 作成 → デプロイ → PR コメント |
| `preview-cleanup` | PR クローズ（マージ / 未マージ）— D1 削除                                |

GitHub Secrets（PR Preview 用）:

```bash
bunx wrangler login
gh auth login
bun run setup:github-secrets
```

| Secret                  | 用途                                                          |
| ----------------------- | ------------------------------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | D1 作成・削除、Workers preview upload（ダッシュボードで作成） |
| `CLOUDFLARE_ACCOUNT_ID` | `wrangler whoami` で取得                                      |

詳細: skill `github-secrets-setup`

Workers Builds: `prottype` Worker の **非本番ブランチビルドは無効**（GHA preview と二重実行を防ぐ）。

`ci.yml` の内容は本リポジトリ [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) と同一にする。詳細: skill `workers-deploy`。

## Phase 6 — Acceptance（検収）

**すべて PASS で「0から再現成功」。**

```bash
bun install
bun run ci    # lint + format:check + rulesync:check + test + build
```

または個別:

```bash
bun run rulesync
bun run lint
bun run format:check
bun run rulesync:check
bun run test
bun run build
```

### ファイル存在チェック

```bash
test -f app/server.ts
test -f app/core/result.ts
test -f .rulesync/skills/qa-review/SKILL.md
test -f .rulesync/skills/prottype-bootstrap/SKILL.md
test -f .cursor/skills/qa-review/SKILL.md
test -f docs/bootstrap-verify.md
test -f wrangler.jsonc
test -f .github/workflows/ci.yml
test -f scripts/deploy-preview.sh
test -f scripts/preview-d1.sh
test -f scripts/render-wrangler-preview-config.sh
test -f scripts/rulesync-check.sh
grep -q 'preview_urls' wrangler.jsonc
grep -q 'env.staging' wrangler.jsonc
grep -q 'env.production' wrangler.jsonc
grep -q 'format:check' package.json
grep -q 'rulesync:check' package.json
```

### 規約チェック

- [ ] `app/db/zod/` の Zod 定数は `z` プレフィックス（例 `zUserView`, `zTodoTitle`）
- [ ] `package.json` の `zod` は **4.x** exact pin（`^` / `~` なし）
- [ ] `app/modules/validation/zod-result.ts` が存在する
- [ ] ドメイン Port は `I<Domain>Repository`、操作は `<domain>.create` / `fromRow` 名前空間
- [ ] `.github/workflows/ci.yml` に `quality` + `preview` + `preview-cleanup` ジョブがある
- [ ] `bun run ci` が PASS
- [ ] `package.json` 依存に `^` / `~` なし
- [ ] ESLint import 境界が prottype-stack と一致
- [ ] qa-review は「指摘のみ・修正しない」

## 0から再現の検証実験（人間向け）

1. **Skills パックだけ用意** — 本 repo の `.rulesync/` を tarball 化（コードは含めない）
2. **空ディレクトリ** — `mkdir /tmp/prottype-zero && cd /tmp/prottype-zero`
3. **新規 Cursor セッション** — skills パックを `.rulesync/` に展開、または `prottype-bootstrap` のみ global skill として有効化
4. **プロンプト1回**:

   ```
   空ディレクトリです。prottype-bootstrap スキルに従い Phase 1〜6 を実行し、
   Acceptance を全 PASS させてください。clone は禁止。
   ```

5. **Acceptance を実行** — 失敗フェーズ = skill の穴

詳細: [docs/bootstrap-verify.md](../../docs/bootstrap-verify.md)

## 参照スキル・記事

| 項目                | 参照                                                                                                                                               |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 技術スタック        | skill `prottype-stack`, docs/stack.md                                                                                                              |
| DDD/TDD/FP          | skill `lightweight-ddd-tdd`, [docs/example-todo.md](../../docs/example-todo.md), [mizchi Zenn](https://zenn.dev/mizchi/articles/ai-ddd-tdd-prompt) |
| 多環境デプロイ / CI | skill `workers-deploy`, [docs/deploy.md](../../docs/deploy.md)                                                                                     |
| QA                  | skills `qa-personas`, `test-case-creation`, `qa-review`, [Nexta Zenn](https://zenn.dev/nexta_/articles/be13a2395a5d2a)                             |
| Better Auth         | skill `better-auth-best-practices`                                                                                                                 |
