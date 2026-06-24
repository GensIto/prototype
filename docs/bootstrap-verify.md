# 0から再現性の検証方法

**目的**: clone せず、skills（と bootstrap 手順）だけで prottype 相当のプロジェクトを立ち上げられるか確認する。

## なぜ clone では足りないか

clone は「既にできたものを複製」するだけ。再現性の本体は **`.rulesync/skills/` に手順が書いてあり、空ディレクトリ + AI が同じ結果を作れるか** です。

## 検証の3層

| 層                 | 何を確認する                               | 合格条件                           |
| ------------------ | ------------------------------------------ | ---------------------------------- |
| A. Skills 完全性   | bootstrap + 子 skills が手順として足りるか | Phase 6 Acceptance 全 PASS         |
| B. 手順の決定性    | 同じプロンプト2回で骨格が同じか            | ファイルツリー・scripts が実質一致 |
| C. AI 出力の安定性 | qa-review 等の観点が毎回揃うか             | P1〜P7 表が2回とも出る             |

この doc は **A** が主。B/C は別途 AI セッションで確認。

---

## 実験 A: 0からブートストラップ（推奨）

### 準備

```bash
# 1. skills パックだけ取り出す（アプリコードは含めない）
cd /path/to/prottype
tar czf /tmp/prottype-skills-pack.tgz .rulesync/ rulesync.jsonc docs/bootstrap-verify.md

# 2. 完全に空の作業場
mkdir /tmp/prottype-zero && cd /tmp/prottype-zero
```

### 実行

1. **新しい Cursor ウィンドウ**で `/tmp/prottype-zero` を開く
2. skills パックを展開 **しない**（pure 0から）か、**`.rulesync/` だけ**展開するかを選ぶ:

| モード        | 展開するもの                                        | 測定対象                       |
| ------------- | --------------------------------------------------- | ------------------------------ |
| **Strict**    | なし（`prottype-bootstrap` skill のみ global 登録） | skill 文章だけで足りるか       |
| **Pragmatic** | `.rulesync/` + `rulesync.jsonc`                     | skills コピー + 手順で足りるか |

3. **プロンプト（1回だけ）**:

```
空ディレクトリです。clone 禁止。
prottype-bootstrap スキルに従い Phase 1〜6 を実行し、
docs/bootstrap-verify.md の Acceptance を全 PASS させてください。
```

4. エージェント完了後、自分で検収:

```bash
bun run lint && bun run test && bun run build
bun run dev   # Landing 表示
```

### 合格 / 不合格

| 結果                       | 意味                                                             |
| -------------------------- | ---------------------------------------------------------------- |
| Acceptance 全 PASS         | **0から再現 OK** — skills は十分                                 |
| 特定 Phase で停止          | その Phase の skill に手順不足 → bootstrap または子 skill を追記 |
| build は通るが skills 欠落 | Phase 4 の skill 一覧 or 中身が不足                              |

失敗した Phase をメモし、`prottype-bootstrap` または該当 skill に追記 → **同じ実験を再実行**（これが改善ループ）。

---

## 実験 B: 決定性（任意）

同じ Strict モードで **別日・別チャット** に同じプロンプトを2回。

比較するもの:

- `package.json` の scripts 名
- `wrangler.jsonc` の env 構造
- `.rulesync/skills/` のファイル一覧
- `app/` のレイヤー構成（server, routes, modules, db, core）

大きくズレる場合 → bootstrap skill の「必須ファイル一覧」を具体化する。

---

## 実験 C: QA skills 安定性（任意）

0から立ち上げたプロジェクト（または本 repo）で:

```
qa-review スキルを使い app/core/result.test.ts をレビュー。
修正せず P1〜P7 表のみ。
```

2回実行し、ペルソナ表の行が揃うか確認。

---

## 自動検収スクリプト

```bash
bun run verify:repro
```

lint + test + build + 必須ファイル存在チェック。

---

## skills パックに含める最小セット

0から検証で **Pragmatic モード** を使う場合、コードなしで渡す最小単位:

```
.rulesync/          # 全 skills + rules + mcp.json
rulesync.jsonc
docs/bootstrap-verify.md
```

アプリ本体（`app/`, `vite.config.ts` 等）は **含めない**。エージェントが Phase 1〜6 で生成する。

---

## よくある失敗と対処

| 症状                 | 原因                               | 対処                                                   |
| -------------------- | ---------------------------------- | ------------------------------------------------------ |
| Inertia 真っ白       | pages.gen.ts / manifest タイミング | bootstrap に vite build 2回 or inertiaPages 注意を追記 |
| BETTER_AUTH 型エラー | env.d.ts 漏れ                      | Phase 3 チェックリスト強化                             |
| `.cursor/skills` 空  | rulesync 未実行                    | Phase 4 末尾に `bun run rulesync` 必須化               |
| QA 観点が毎回違う    | qa-personas 未読                   | bootstrap から qa-personas 参照を必須化                |

## 関連

- skill `prottype-bootstrap`
- [docs/qa.md](./qa.md)
