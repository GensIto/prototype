---
name: migration-test-creation
description: '移行・既存仕様ベースのテストケース作成。既存仕様ドキュメントを正本とし 「仕様どおりに動くか」を1件ずつ確認する。主役ペルソナ P5・P7。 出典: https://zenn.dev/nexta_/articles/be13a2395a5d2a'
---

# 移行テストケース作成

## 新機能との違い

| 観点           | 新機能 (`test-case-creation`) | 移行 (本スキル)                     |
| -------------- | ----------------------------- | ----------------------------------- |
| 仕様の出どころ | Issue + ソース                | **既存仕様ドキュメント** + 既存挙動 |
| 正解の基準     | 要件を満たす                  | **仕様どおりに動く**                |
| 主役ペルソナ   | P1〜P7（P3, P4 重点）         | **P5 移行** + **P7 仕様懐疑**       |

## ワークフロー

1. 既存仕様（ヘルプ・旧システム仕様書等）の見出し単位で Test Basis を列挙
2. 各記載どおりに動くかを1件ずつテストケース化
3. 共通 UI パターン（一覧 Tab 遷移、行追加等）は `qa/master/design-patterns.csv` に切り出し重複を避ける
4. 出力:
   - `qa/artifacts/YYYY-MM/migration-<name>/test-cases.csv`
   - `qa/artifacts/YYYY-MM/migration-<name>/requirement-coverage.csv`（要件カバレッジ表）
5. 要件を分類: `テスト可` / `テスト可（保留：実装未検出）` / `テスト不可（仕様不足）`

## 要件カバレッジ CSV

```csv
要件ID;要件説明;出典（見出し）;分類;テストケースID;備考
```

「仕様がないから書けない」は **仕様ギャップ** として可視化する。

## 関連

- skill `qa-personas`, `qa-review`, `test-case-creation`
