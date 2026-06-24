# Todo 機能 — 実装サンプル

軽量 DDD + TDD + Inertia の **参照実装**。新機能追加時はこの構成を踏襲する。

## レイヤー対応

```
app/db/schema/todo/          Drizzle スキーマ（Infrastructure）
app/modules/todo/
  todo.ts                    ドメイン名前空間（todo.create / toggle / fromRow）
  todo.test.ts               Vitest（TDD）
  repository.ts              ITodoRepository（Port）
  adapters/d1-todo-repository.ts  class implements ITodoRepository
  serialize.ts               Domain → View DTO
app/db/zod/todo/views.ts     Inertia props + zTodoTitle（入力検証）
app/routes/todos/            HTTP（thin controller）
app/pages/Todos/Index.tsx    Inertia エントリ（薄い）
app/components/todos/        Feature UI
```

## ドメイン API

```typescript
todo.create({ userId, title, id })  // zodToResult(zTodoTitle, title) + 組み立て
todo.toggle(entity)                 // 不変更新
todo.fromRow({ id, userId, ... })   // Row → Entity（分割代入）
todo.parseId(string)                // Branded TodoId
```

## バリデーション

- ルール定義: `zTodoTitle`（`app/db/zod/todo/views.ts`）— 単一ソース
- HTTP: `zCreateTodoBody` → `@hono/zod-validator`
- ドメイン: `zodToResult(zTodoTitle, input.title)` — 不変条件の再検証
- 手書き `validateTitle` は使わない

## データフロー

1. `GET /todos` — `requireAuth` → `ITodoRepository` → `serializeTodos` → Inertia
2. `POST /todos` — `todo.create` → save → redirect
3. `POST /todos/:id/toggle` — `todo.toggle` → save
4. `DELETE /todos/:id` — repository.delete

## 認可

- 全 Todo ルートに `requireAuth`
- repository は常に `userId` でスコープ（P3 悪意・P4 整合）

## ローカル確認

```bash
bun run db:generate && bun run db:migrate:local
bun run dev
# Sign up → /todos
```

## 関連スキル

- `lightweight-ddd-tdd` — Result 型・ITodoRepository・todo 名前空間
- `prottype-stack` — import 境界・z プレフィックス・Zod 4・zodToResult
- `test-case-creation` / `qa-review` — 手動ケース・レビュー
