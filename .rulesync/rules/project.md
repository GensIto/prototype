---
root: true
targets:
  - cursor
features:
  - rules
  - skills
  - mcp
---

# prottype プロジェクトルール

## 言語

- ユーザー向け UI 文言は日本語
- コード・コメント・コミットメッセージは英語

## アーキテクチャ

- 単一 Cloudflare Worker（`app/server.ts`）
- レイヤー境界は ESLint `no-restricted-imports` で強制
- 詳細は `docs/architecture.md` と skill `prottype-stack` を参照

## コーディング

- 軽量 DDD + TDD + FP（skill `lightweight-ddd-tdd` を参照）
- `app/core/result.ts` の Result 型をドメインエラーに使用
- 新機能はテストファーストで小さく始める

## QA・テスト設計

- 7人のQAペルソナ（skill `qa-personas`）で観点漏れを防ぐ
- 新機能: `test-case-creation` → `qa-review`（レビューは指摘のみ）
- 移行: `migration-test-creation` → `qa-review`
- 成果物: Vitest（`app/**/*.test.ts`）+ `qa/master/` / `qa/artifacts/`
- 詳細: [docs/qa.md](../docs/qa.md)

## 依存関係

- `package.json` は exact pin（`^` / `~` 禁止）
- shadcn/ui コンポーネントは `app/components/ui/` に追加

## AI 設定

- ソースオブトゥルース: `.rulesync/`
- 同期: `bun run rulesync`
