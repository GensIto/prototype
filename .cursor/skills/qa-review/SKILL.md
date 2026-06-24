---
name: qa-review
description: 'テストケース・Vitest テストの品質レビュー。7人のQAペルソナで観点漏れを指摘する。 指摘のみで修正は行わない。test-case-creation 後のレビュー、PR 前のテスト設計確認時に使う。 出典: https://zenn.dev/nexta_/articles/be13a2395a5d2a'
---

# QA レビュー（指摘のみ）

## 責務

- **指摘する** — 観点漏れ・根拠不足・正常系偏り・仕様とのズレ
- **修正しない** — テストケースの追記・コード変更は行わない（作成者が対応）

## いつ使う

```
# 手動テスト CSV をレビュー
qa-review qa/artifacts/2026-06/ISSUE-42/test-cases.csv

# Vitest ファイルをレビュー
qa-review app/modules/<domain>/*.test.ts
```

## レビュー手順

1. Test Basis / 一次情報が各行（または describe ブロック）に紐づいているか
2. **7人のQAペルソナ**（skill `qa-personas`）ごとに最低1観点があるか
3. 正常系だけに偏っていないか（P3 悪意・P4 DB・P6 回帰）
4. 期待結果に推測が混ざっていないか（未確認は `※要コード確認` か）
5. ISO 25010 品質特性に偏りがないか（手動 CSV の場合）
6. prottype レイヤー境界に沿っているか（domain テストが UI に漏れていないか）

## 出力フォーマット

```markdown
# QA Review: <対象>

## サマリ

- 重大: N / 中: N / 軽微: N

## ペルソナ別カバレッジ

| ペルソナ | 状態 | 指摘 |
| P1 | ✅ / ⚠️ / ❌ | ... |
| ... | | |

## 指摘一覧

### [重大] TC-XXX / test名

- ペルソナ: P4
- 問題: 期待結果に D1 テーブル名がなく画面表示のみ
- 提案: app/db/schema/ の `<table>.<column>` を明記

### [中] ...
```

## チェックリスト（抜けやすい観点）

- [ ] 未認証 / 認証済み / セッション切れ（Better Auth）
- [ ] `@hono/zod-validator` 境界値・不正 JSON
- [ ] CI quality ゲート（lint / format:check / rulesync:check / test / build）が PR で通る設計か
- [ ] PR preview デプロイ後の手動確認観点（認証 URL・D1 データスコープ）
- [ ] D1 トランザクション・整合性（P4）
- [ ] Inertia 遷移・ブラウザバック（P6）
- [ ] develop / staging / production の env 差（skill `workers-deploy`）
- [ ] 受入条件との突合（P7）

## やらないこと

- テストケースの自動修正・追記
- 実装コードの変更
- 根拠なく「足りている」と判定すること

## 関連

- skill `qa-personas`, `test-case-creation`, `migration-test-creation`
- [docs/qa.md](../../docs/qa.md)
