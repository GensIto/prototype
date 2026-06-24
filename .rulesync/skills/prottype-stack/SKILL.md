---
name: prottype-stack
description: >-
  prottype プロジェクトの技術スタック・レイヤー構成・import 境界・バリデーション流れ。
  Cloudflare Workers, Hono, Inertia, React 19, D1, Drizzle, Better Auth, Tailwind v4, shadcn/ui
  で実装するとき、または app/ 配下のコードを書くときに使う。
---

# prottype 技術スタック

## ランタイム・インフラ

| 技術               | 用途                                       |
| ------------------ | ------------------------------------------ |
| Cloudflare Workers | アプリケーションランタイム                 |
| D1                 | メタデータ（scenarios, documents, chunks） |
| Wrangler           | 開発・デプロイ・型生成                     |

## バックエンド

| 技術                | 用途                                                           |
| ------------------- | -------------------------------------------------------------- |
| Hono                | Web フレームワーク                                             |
| @hono/inertia       | Inertia アダプター                                             |
| @hono/zod-validator | ルート入力バリデーション                                       |
| Drizzle ORM         | D1 向け ORM                                                    |
| drizzle-zod         | スキーマ → Zod                                                 |
| Zod 4               | ランタイムバリデーション（`import { z } from 'zod'` = v4 API） |
| Better Auth         | 認証                                                           |

## フロントエンド

| 技術                | 用途                                      |
| ------------------- | ----------------------------------------- |
| React 19            | UI                                        |
| @inertiajs/react    | サーバー駆動 SPA                          |
| Tailwind CSS v4     | スタイル                                  |
| shadcn/ui           | UI コンポーネント（`app/components/ui/`） |
| Lucide React        | アイコン                                  |
| vite-ssr-components | Vite HMR / アセットタグ                   |

## レイヤー構成

| レイヤー       | パス                            | 責務                     |
| -------------- | ------------------------------- | ------------------------ |
| Presentation   | `app/pages/`, `app/components/` | Inertia UI               |
| HTTP           | `app/server.ts`, `app/routes/`  | ルーティング、middleware |
| Domain         | `app/modules/`                  | ビジネスロジック         |
| Infrastructure | `app/db/`, bindings             | 永続化                   |

## リクエストパイプライン

1. `authMiddleware` — リクエスト単位の Better Auth + セッション
2. `inertia()` — Inertia プロトコル + HTML シェル
3. Route handlers — `modules/` を呼ぶ thin controller
4. Domain modules — 純粋関数 + Result 型

## バリデーションの流れ

```
app/db/schema/<domain>/<table>.ts
        ↓ drizzle-zod（必要時）
app/db/zod/<domain>/          # z プレフィックス（zTodoTitle, zCreateTodoBody, zTodoView）
        ↓
app/modules/validation/
  zod-result.ts               # zodToResult(schema, data) → Result<T, ValidationError>
  form-errors.ts              # zodToFormErrors → FormErrors
        ↓
app/routes/                   # @hono/zod-validator（HTTP 境界）
app/modules/<domain>/         # zodToResult（ドメイン不変条件の再検証）
app/pages/*.tsx               # Inertia props 型（db/zod から import）
```

### Zod 規約

- **Zod 4.x** を使用（3.25 移行期は使わない）。`package.json` は exact pin（例: `"zod": "4.4.3"`）
- スキーマ定数は **`z` プレフィックス**（例: `zTodoTitle`, `zUserView`）。型は `z.infer<typeof zTodoTitle>`
- フィールド単位スキーマ（`zTodoTitle`）を object スキーマ（`zCreateTodoBody`）とドメイン（`todo.create`）で **共有**
- ドメインから Zod へ: `zodToResult(zTodoTitle, input.title)` — **schema を渡して型推論**（`safeParse` 結果を直接渡すと `unknown` になりやすい）
- v4 型: `ZodType<T>`, `ZodSafeParseResult<T>`（v3 の `SafeParseReturnType` は非推奨）

```typescript
// app/modules/validation/zod-result.ts
export function zodToResult<T>(schema: ZodType<T>, data: unknown): Result<T, ValidationError>
export function safeParseToResult<T>(parsed: ZodSafeParseResult<T>): Result<T, ValidationError>
```

- 参照実装: [docs/example-todo.md](../../docs/example-todo.md)

## import 境界（ESLint 強制）

| レイヤー      | import 可能                       | import 禁止                              |
| ------------- | --------------------------------- | ---------------------------------------- |
| `pages/`      | `components/*`, `db/zod`          | `modules/*`, `db/schema/*`, `routes/*`   |
| `components/` | `components/ui`, `db/zod`         | `modules/*`, `routes/*`, `db/schema/*`   |
| `routes/`     | `modules/*`, `db/zod`             | `db/schema/*`, `pages/*`, `components/*` |
| `modules/`    | `db/schema`, `db/zod`, 他 modules | `pages/*`, `routes/*`, `components/*`    |

## 規約

- パスエイリアス: `@/*` → `app/*`
- Drizzle マイグレーション: `migrations/`、`prefix: timestamp`
- Workers 上で auth / db の **グローバル singleton 禁止**（リクエスト単位で生成）
- `package.json` 依存は **exact pin**（`^` / `~` 禁止）
- Inertia props 型は `app/db/zod/` を単一ソースとする
- Zod スキーマ定数は **`z` プレフィックス**（例: `zUserView`, `zTodoTitle`）。型は `z.infer<typeof zUserView>`
- ドメイン Port は `I<Domain>Repository`、Adapter は `class D1XxxRepository implements IXxxRepository`
- ドメイン操作は `export const xxx = { create, toggle, fromRow, parseId }` 名前空間（詳細: skill `lightweight-ddd-tdd`）

## 主要コマンド

```bash
bun run dev              # Vite 開発
bun run db:setup         # Auth schema + migrate
bun run test             # Vitest
bun run lint             # ESLint
bun run format:check     # Prettier（CI 用・変更なし）
bun run rulesync:check   # .rulesync/ と .cursor/ 同期確認
bun run ci               # lint + format:check + rulesync:check + test + build
bun run cf-typegen       # CloudflareBindings 型生成
bun run rulesync         # .rulesync → .cursor 同期
```

## CI（GitHub Actions）

[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — 詳細は skill `workers-deploy`

| ジョブ    | 内容                                                               |
| --------- | ------------------------------------------------------------------ |
| `quality` | lint → format:check → rulesync:check → test → build                |
| `preview` | quality 成功後、PR ごとに `wrangler versions upload` → PR コメント |

PR preview に必要な GitHub Secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`

## デプロイ環境

| 環境       | Worker                | ブランチ    | コマンド                           |
| ---------- | --------------------- | ----------- | ---------------------------------- |
| develop    | `prottype`            | `develop`   | `bun run deploy:develop`           |
| preview    | `prottype`            | PR ブランチ | GitHub Actions（`preview` ジョブ） |
| staging    | `prottype-staging`    | `staging`   | `bun run deploy:staging`           |
| production | `prottype-production` | `main`      | `bun run deploy:production`        |

詳細は skill `workers-deploy` および [docs/deploy.md](../../docs/deploy.md) を参照。

## 詳細

- [docs/stack.md](../../docs/stack.md)
- [docs/architecture.md](../../docs/architecture.md)
- [docs/deploy.md](../../docs/deploy.md)
- [docs/qa.md](../../docs/qa.md)
- [docs/example-todo.md](../../docs/example-todo.md) — Todo 参照実装
