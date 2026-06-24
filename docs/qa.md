# QA・テスト設計

[7人の意地悪なQA](https://zenn.dev/nexta_/articles/be13a2395a5d2a) をベースに、Vitest + 手動テストケース CSV の2系統で品質を担保する。

## ディレクトリ構成

```
qa/
├── master/              # 生きている正本（機能ごと CSV、常に最新）
│   └── design-patterns.csv   # 共通 UI パターン（移行用）
└── artifacts/           # Issue・移行ごとのスナップショット
    └── YYYY-MM/
        └── <issue-id>/
            ├── test-cases.csv
            └── requirement-coverage.csv   # 移行時のみ
```

- `master/` … 有効なケース一覧。廃止ケースは行を消さず `DEPRECATED` を付ける
- `artifacts/` … 「あのとき何をテストしたか」の履歴

Vitest は `app/**/*.test.ts` に置く（`bun run test`）。

## スキル一覧

| スキル                    | 用途                                 |
| ------------------------- | ------------------------------------ |
| `qa-personas`             | 7人のQAペルソナ（共通基盤）          |
| `test-case-creation`      | 新機能のテスト設計・作成             |
| `migration-test-creation` | 移行・既存仕様ベースの作成           |
| `qa-review`               | レビュー（**指摘のみ、修正しない**） |

同期: `bun run rulesync`

## 新機能トラック

```
1. test-case-creation  … Issue + ソースから Vitest / CSV 作成
2. qa-review           … 観点漏れ・根拠不足を指摘
3. bun run test        … Vitest 実行
```

## 移行トラック

```
1. migration-test-creation … 既存仕様を正本に CSV + 要件カバレッジ表
2. qa-review               … レビュー
```

## 原則

- AI は **テスト設計者**。実行・合否判断は人間
- 根拠のないケースを出さない（Test Basis = 一次情報）
- コード未確認は `※要コード確認（未実施）` と明記
- Zod スキーマ名は `z` プレフィックス（例: `zUserView`）

## 参考

- [Claude Code に「7人の意地悪なQA」を仕込んで…](https://zenn.dev/nexta_/articles/be13a2395a5d2a)
- [ISO/IEC 25010](https://www.iso.org/standard/35733.html) — 品質特性
