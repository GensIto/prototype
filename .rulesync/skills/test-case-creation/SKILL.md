---
name: test-case-creation
description: >-
  新機能のテストケース作成。Issue・受入条件・ソースコード（app/modules, routes, db/schema）を
  起点に Vitest 単体テストと手動テストケース CSV を設計する。7人のQAペルソナを適用。
  出典: https://zenn.dev/nexta_/articles/be13a2395a5d2a
---

# 新機能テストケース作成

## いつ使う

- 新機能・新 PBI のテスト設計
- 仕様の出どころ = **Issue / 受入条件 + ソースコード**

## 正解の基準

要件（受入条件）を満たしていること。実装が正しいことではない（P7 が検証する）。

## ワークフロー

1. Issue / 受入条件を読み、Test Basis を確定
2. 関連ソースを読む（`app/modules/`, `app/routes/`, `app/db/schema/`）
3. **7人のQAペルソナ**（skill `qa-personas`）で観点を出す
4. 出力を2系統に分ける:
   - **Vitest**: `app/modules/**/*.test.ts`, `app/core/**/*.test.ts`（TDD / skill `lightweight-ddd-tdd`）
   - **手動ケース CSV**: `qa/artifacts/YYYY-MM/<issue-id>/test-cases.csv`
5. 完了後 `qa/master/<feature>.csv` にマージ（DEPRECATED 行は削除しない）

## Vitest 優先ルール

| 対象                                           | 置き場所                                  | ペルソナ   |
| ---------------------------------------------- | ----------------------------------------- | ---------- |
| 純粋関数・ドメイン名前空間（`todo.create` 等） | `app/modules/<domain>/*.test.ts`          | P3, P7     |
| リポジトリ（インメモリ）                       | `app/modules/<domain>/adapters/*.test.ts` | P4         |
| Zod スキーマ（`zTodoTitle` 等）                | `app/db/zod/**/*.test.ts`                 | P3         |
| HTTP / Inertia 統合                            | 手動ケース CSV                            | P1, P2, P6 |

Zod とドメインの二重検証がある場合、**両方**テストする（スキーマ単体 + `zodToResult` 経由のドメイン）。

## 手動テスト CSV 形式

区切り: セミコロン / UTF-8 / セル内改行: `<br>`

```csv
要件ID;要件説明;Test Basis;テストケースID;テストタイトル;優先度;テストタイプ;品質特性;リスク;テスト観点;Test Data;前提条件;実施画面;操作手順;期待結果;コードモジュール;自動化(YES/NO);回帰(YES/NO);最終更新日;結果
```

品質特性は [ISO/IEC 25010](https://www.iso.org/standard/35733.html)（機能適切性・使用性・信頼性・セキュリティ等）を偏りなく埋める。

### 1行の例

```csv
ISSUE-42;未ログイン時は Landing を表示;ISSUE-42;TC-HOME-001;Landing：未認証でトップ表示;高;機能テスト;使用性;認証漏れ;P1/P6;—;未ログイン;Landing;1. / にアクセス;Landing が表示され dashboard へリダイレクトされない;app/routes/home;NO;YES;2026-06-24;未実施
```

## コードモジュール欄

- 確認済み: 実パス（例 `app/modules/auth/middleware.ts`）
- 未確認: `※要コード確認（未実施）`

## やらないこと

- レビュー・修正（→ skill `qa-review`）
- 根拠のない期待結果の捏造
- `pages/` / `components/` から domain ロジックのテストを書く（ESLint 境界違反）

## 関連

- [docs/qa.md](../../docs/qa.md)
- skill `qa-personas`, `lightweight-ddd-tdd`, `qa-review`
