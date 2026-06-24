---
name: github-secrets-setup
description: >-
  prottype の PR Preview 用 GitHub Secrets（CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID）登録手順。
  wrangler whoami で Account ID を取得し、gh secret set で登録。API トークン作成は Cloudflare ダッシュボードで行う。
  PR Preview / GitHub Actions preview ジョブの初回セットアップ時に使う。
---

# GitHub Secrets 登録（PR Preview 用）

PR Preview（`.github/workflows/ci.yml` の `preview` ジョブ）に必要な Secrets。

| Secret                  | 用途                                      |
| ----------------------- | ----------------------------------------- |
| `CLOUDFLARE_API_TOKEN`  | D1 作成・削除、`wrangler versions upload` |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare アカウント ID                  |

## wrangler でできること / できないこと

| 項目                | 方法                                                                            |
| ------------------- | ------------------------------------------------------------------------------- |
| Account ID 取得     | `bunx wrangler whoami --json`（要 `wrangler login`）                            |
| API トークン作成    | **CLI 不可** → [ダッシュボード](https://dash.cloudflare.com/profile/api-tokens) |
| GitHub Secrets 登録 | `gh secret set` または `bash scripts/setup-github-secrets.sh`                   |

## 1. Cloudflare API トークン（手動）

[My Profile → API Tokens](https://dash.cloudflare.com/profile/api-tokens) → **Create Custom Token**

**Account** 権限:

| Permission      | Access |
| --------------- | ------ |
| Workers Scripts | Edit   |
| D1              | Edit   |

Account Settings 等の追加権限は **不要**。

## 2. 自動登録（推奨）

前提: `wrangler login` 済み、`gh auth login` 済み、リポジトリ root で実行。

```bash
bash scripts/setup-github-secrets.sh
```

- `CLOUDFLARE_ACCOUNT_ID` → `wrangler whoami --json` から取得して `gh secret set`
- `CLOUDFLARE_API_TOKEN` → プロンプト入力（または環境変数 `CLOUDFLARE_API_TOKEN`）

### オプション

```bash
# Account ID だけ確認
bunx wrangler whoami

# 手動登録用に Account ID を表示
bash scripts/setup-github-secrets.sh --print-only

# トークン入力後、gh ではなく手順だけ表示
bash scripts/setup-github-secrets.sh --manual
```

## 3. 手動登録

GitHub → リポジトリ **Settings → Secrets and variables → Actions**

| Name                    | Value                                                |
| ----------------------- | ---------------------------------------------------- |
| `CLOUDFLARE_ACCOUNT_ID` | ダッシュボード右サイドバー、または `wrangler whoami` |
| `CLOUDFLARE_API_TOKEN`  | 手順 1 で作成したトークン                            |

## 4. 検証

Secrets 登録後、PR を push するか Actions タブで **Re-run jobs**。

`preview` ジョブの **Verify Cloudflare secrets** が PASS すれば OK。

## 関連

- skill `workers-deploy`
- [README.md](../../README.md#6-github-secretspr-preview-用)
- [docs/deploy.md](../../docs/deploy.md#github-actions)
