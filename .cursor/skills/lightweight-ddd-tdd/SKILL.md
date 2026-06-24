---
name: lightweight-ddd-tdd
description: '軽量 DDD + TDD + 関数型ドメインモデリングのコーディングプラクティス。 ドメインロジック実装、Result 型、値オブジェクト、リポジトリ、テストファースト開発時に使う。 出典: https://zenn.dev/mizchi/articles/ai-ddd-tdd-prompt'
---

# コーディングプラクティス（軽量 DDD + TDD + FP）

## 原則

### 関数型アプローチ (FP)

- 純粋関数を優先
- 不変データ構造を使用
- 副作用を分離
- 型安全性を確保

### ドメイン駆動設計 (DDD)

- 値オブジェクトとエンティティを区別
- 集約で整合性を保証
- リポジトリでデータアクセスを抽象化
- 境界付けられたコンテキストを意識

### テスト駆動開発 (TDD)

- Red-Green-Refactor サイクル
- テストを仕様として扱う
- 小さな単位で反復
- 継続的なリファクタリング

## 実装パターン

### 型定義

```typescript
// app/core/result.ts を使用
type Branded<T, B> = T & { _brand: B }
type Money = Branded<number, 'Money'>
type Email = Branded<string, 'Email'>
```

### 値オブジェクト

- 不変
- 値に基づく同一性
- 自己検証
- ドメイン操作を持つ

```typescript
function createMoney(amount: number): Result<Money, ValidationError> {
  if (amount < 0) return err(new ValidationError('負の金額不可'))
  return ok(amount as Money)
}
```

### エンティティ

- ID に基づく同一性
- 制御された更新
- 整合性ルールを持つ

### Result 型

`app/core/result.ts` の `Result`, `ok`, `err`, `ValidationError` を使う。

- 成功/失敗を明示
- 早期リターンパターンを使用
- エラー型を定義

### リポジトリ

- Port は `I<Domain>Repository`（例: `ITodoRepository`）
- Adapter は `class D1TodoRepository implements ITodoRepository`
- Factory `createD1TodoRepository()` で返す
- テスト用のインメモリ実装も `implements ITodoRepository`

```typescript
// app/modules/<domain>/repository.ts
export interface ITodoRepository {
  findById(id: TodoId): Promise<Result<Todo | null, Error>>
  save(todo: Todo): Promise<Result<Todo, Error>>
}

// app/modules/<domain>/adapters/d1-todo-repository.ts
class D1TodoRepository implements ITodoRepository { ... }
export function createD1TodoRepository(d1: D1Database): ITodoRepository {
  return new D1TodoRepository(d1)
}
```

### ドメイン名前空間

- 操作は `export const todo = { create, toggle, fromRow, parseId }` に集約
- 中身は純粋関数・不変・Result のまま（クラス Entity にしない）
- Row → Entity は `todo.fromRow`（分割代入でマッピング）
- ファクトリは `create`（`new` は使わない）

```typescript
export const todo = {
  create(input): Result<Todo, ValidationError> { ... },
  toggle(entity): Result<Todo, ValidationError> { ... },
  fromRow({ id, userId, title, ... }: TodoRow): Todo { ... },
  parseId(id: string): TodoId { ... },
}
```

### 入力検証（Zod）

- フィールドルールは **Zod スキーマを単一ソース** とする（手書き `validateXxx` は書かない）
- 定義場所: `app/db/zod/<domain>/`（例: `zTodoTitle`）
- HTTP 境界: `@hono/zod-validator` で早期 reject
- ドメイン: `zodToResult(schema, data)` で `Result<T, ValidationError>` に変換（不変条件の再検証）
- ルートとドメインで二重チェックしてよい — **ルール定義は1つ**（`zTodoTitle` 等）

```typescript
// app/db/zod/todo/views.ts
export const zTodoTitle = z.string().trim().min(1, 'Title is required').max(200, '...')

export const zCreateTodoBody = z.object({ title: zTodoTitle })

// app/modules/todo/todo.ts
import { zodToResult } from '@/modules/validation/zod-result'

const titleResult = zodToResult(zTodoTitle, input.title)
if (!titleResult.ok) return titleResult
// titleResult.value は string（schema から型推論）
```

- Zod → FormErrors: `zodToFormErrors`（`app/modules/validation/form-errors.ts`）
- 参照実装: [docs/example-todo.md](../../docs/example-todo.md)

### アダプターパターン

- 外部依存を抽象化
- インターフェースは呼び出し側（domain）で定義
- テスト時は容易に差し替え可能
- D1 実装は `app/db/` または `app/modules/<domain>/adapters/`

## 実装手順

1. **型設計** — まず型を定義。ドメインの言語を型で表現
2. **純粋関数から実装** — 外部依存のない関数を先に。テストを先に書く
3. **副作用を分離** — IO 操作は関数の境界に押し出す
4. **アダプター実装** — DB / 外部 API を抽象化。テスト用モックを用意

## プラクティス

- 小さく始めて段階的に拡張
- 過度な抽象化を避ける
- コードよりも型を重視
- 複雑さに応じてアプローチを調整
- **エヴァンス式 DDD は使わない** — 本プロジェクトは軽量 DDD

## コードスタイル

- 関数優先（**Adapter の class のみ許容**）
- 不変更新パターンの活用
- 早期リターンで条件分岐をフラット化
- エラーとユースケースの列挙型定義

## テスト戦略

- 純粋関数の単体テストを優先（`app/modules/**/*.test.ts`, `app/core/**/*.test.ts`）
- インメモリ実装によるリポジトリテスト
- テスト可能性を設計に組み込む
- アサートファースト：期待結果から逆算
- 手動テストケース設計は skill `test-case-creation`、レビューは `qa-review`（7人のQAペルソナ = `qa-personas`）

## ファイル配置

```
app/core/result.ts                    # Result, Branded, ValidationError
app/modules/validation/
  zod-result.ts                       # zodToResult, safeParseToResult
  form-errors.ts                      # zodToFormErrors
app/modules/<domain>/                 # ドメイン名前空間 + repository.ts
app/modules/<domain>/adapters/        # class implements I<Domain>Repository
app/modules/<domain>/*.test.ts        # ドメインテスト
app/db/zod/<domain>/*.test.ts         # Zod スキーマテスト
```

## 参考

- [Zenn: 自分のコーディングスタイル(TDD/DDD/FP)をAIに叩き込む](https://zenn.dev/mizchi/articles/ai-ddd-tdd-prompt)
- [mizchi/ailab](https://github.com/mizchi/ailab) — ddd-sample-light
- [docs/qa.md](../../docs/qa.md) — QA スキル・ペルソナ
