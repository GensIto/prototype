import { type Branded, ok, type Result, type ValidationError } from '@/core/result'
import type { todo as todoTable } from '@/db/schema/todo'
import { zTodoTitle } from '@/db/zod/todo/views'
import { zodToResult } from '@/modules/validation/zod-result'

export type TodoRow = typeof todoTable.$inferSelect

export type TodoId = Branded<string, 'TodoId'>

export type Todo = {
  id: TodoId
  userId: string
  title: string
  completed: boolean
  createdAt: Date
  updatedAt: Date
}

function parseId(id: string): TodoId {
  return id as TodoId
}

export const todo = {
  parseId,

  create(input: {
    userId: string
    title: string
    id: TodoId
    now?: Date
  }): Result<Todo, ValidationError> {
    const titleResult = zodToResult(zTodoTitle, input.title)
    if (!titleResult.ok) {
      return titleResult
    }

    const now = input.now ?? new Date()
    return ok({
      id: input.id,
      userId: input.userId,
      title: titleResult.value,
      completed: false,
      createdAt: now,
      updatedAt: now,
    })
  },

  toggle(entity: Todo, now = new Date()): Result<Todo, ValidationError> {
    return ok({
      ...entity,
      completed: !entity.completed,
      updatedAt: now,
    })
  },

  fromRow({ id, userId, title, completed, createdAt, updatedAt }: TodoRow): Todo {
    return {
      id: parseId(id),
      userId,
      title,
      completed,
      createdAt,
      updatedAt,
    }
  },
}
