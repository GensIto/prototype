# 技術スタック

## ランタイム・インフラ

| 技術                                                             | 用途                                       |
| ---------------------------------------------------------------- | ------------------------------------------ |
| [Cloudflare Workers](https://developers.cloudflare.com/workers/) | アプリケーションランタイム                 |
| [D1](https://developers.cloudflare.com/d1/)                      | メタデータ（scenarios, documents, chunks） |
| [Wrangler](https://developers.cloudflare.com/workers/wrangler/)  | 開発・デプロイ・型生成                     |

## バックエンド

| 技術                                                                                         | 用途                     |
| -------------------------------------------------------------------------------------------- | ------------------------ |
| [Hono](https://hono.dev/)                                                                    | Web フレームワーク       |
| [@hono/inertia](https://github.com/honojs/middleware/tree/main/packages/inertia)             | Inertia アダプター       |
| [@hono/zod-validator](https://github.com/honojs/middleware/tree/main/packages/zod-validator) | ルート入力バリデーション |
| [Drizzle ORM](https://orm.drizzle.team/)                                                     | D1 向け ORM              |
| [drizzle-zod](https://orm.drizzle.team/docs/zod)                                             | スキーマ → Zod           |
| [Zod](https://zod.dev/)                                                                      | ランタイムバリデーション |
| [Better Auth](https://www.better-auth.com/)                                                  | 認証                     |

## フロントエンド

| 技術                                                                   | 用途                                      |
| ---------------------------------------------------------------------- | ----------------------------------------- |
| [React 19](https://react.dev/)                                         | UI                                        |
| [@inertiajs/react](https://inertiajs.com/)                             | サーバー駆動 SPA                          |
| [Tailwind CSS v4](https://tailwindcss.com/)                            | スタイル                                  |
| [shadcn/ui](https://ui.shadcn.com/)                                    | UI コンポーネント（`app/components/ui/`） |
| [Base UI](https://base-ui.com/)                                        | shadcn プリミティブ                       |
| [Lucide React](https://lucide.dev/)                                    | アイコン                                  |
| [vite-ssr-components](https://github.com/yusukebe/vite-ssr-components) | Vite HMR / アセットタグ                   |

## 開発ツール

| 技術                                                                                 | 用途                          |
| ------------------------------------------------------------------------------------ | ----------------------------- |
| [Vite](https://vite.dev/)                                                            | 開発・バンドル                |
| [@cloudflare/vite-plugin](https://developers.cloudflare.com/workers/vite-plugin/)    | Workers ローカル開発          |
| [TypeScript](https://www.typescriptlang.org/)                                        | 型安全                        |
| [ESLint 9](https://eslint.org/) + [typescript-eslint](https://typescript-eslint.io/) | Lint                          |
| [Prettier 3](https://prettier.io/)                                                   | フォーマット                  |
| [Vitest](https://vitest.dev/)                                                        | 単体テスト                    |
| [drizzle-kit](https://orm.drizzle.team/kit-docs/overview)                            | マイグレーション              |
| [rulesync](https://github.com/dyoshikawa/rulesync)                                   | AI エージェント設定の一元管理 |

## バリデーションの流れ

```
app/db/schema/<domain>/<table>.ts
        ↓ schema/<domain>/index.ts → schema/index.ts
        ↓ drizzle-zod（必要時）
app/db/zod/<domain>/
        ↓ FormErrors（app/modules/validation/）
app/modules/messages/          日本語文言
app/routes/*/actions.ts    @hono/zod-validator
app/pages/*.tsx            Inertia props
```

## パスエイリアス

| エイリアス | 実パス  |
| ---------- | ------- |
| `@/*`      | `app/*` |

## デプロイ環境

| 環境       | Worker                | ブランチ    |
| ---------- | --------------------- | ----------- |
| develop    | `prottype`            | `develop`   |
| preview    | `prottype`            | PR ブランチ |
| staging    | `prottype-staging`    | `staging`   |
| production | `prottype-production` | `main`      |

詳細: [deploy.md](./deploy.md)

## 関連ドキュメント

- [アーキテクチャ](./architecture.md)
- [デプロイ・環境構成](./deploy.md)
- [QA・テスト設計](./qa.md)
