# prottype アーキテクチャ

Hono・Inertia.js・React 19・D1・Better Auth を使った **単一 Cloudflare Worker** アプリケーション。

## レイヤー構成

| レイヤー       | パス                            | 責務                                  |
| -------------- | ------------------------------- | ------------------------------------- |
| Presentation   | `app/pages/`, `app/components/` | Inertia UI                            |
| HTTP           | `app/server.ts`, `app/routes/`  | ルーティング、middleware、HTTP 入出力 |
| Domain         | `app/modules/`                  | ビジネスロジック                      |
| Infrastructure | `app/db/`, Cloudflare bindings  | 永続化、外部 API                      |

## リクエストパイプライン

1. `authMiddleware` — リクエスト単位の Better Auth + セッション
2. `inertia()` — Inertia プロトコル + HTML シェル
3. Route handlers — `modules/` を呼ぶ thin controller
4. Domain modules — 純粋関数 + Result 型（軽量 DDD）

## 型・DTO

- Drizzle schema: `app/db/schema/`
- View DTO（Inertia props）: `app/db/zod/` — drizzle-zod / Zod で定義
- ページ内での型の手書き重複は禁止。DTO を import する

## import 境界（ESLint で強制）

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
- `routes/` から `app/db` を直接 import しない
- `package.json` の依存は **exact pin**（`^` / `~` 禁止）

## コーディングプラクティス

軽量 DDD + TDD + 関数型アプローチの詳細は `.cursor/skills/lightweight-ddd-tdd/SKILL.md` を参照。

## QA・テスト

7人のQAペルソナによるテスト設計・レビュー。詳細は [docs/qa.md](./qa.md) と `.cursor/skills/qa-*/` を参照。
