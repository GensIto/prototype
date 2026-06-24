import { and, desc, eq } from 'drizzle-orm'

import { err, ok } from '@/core/result'
import { createDb } from '@/db'
import { todo as todoTable } from '@/db/schema/todo'
import type { ITodoRepository } from '@/modules/todo/repository'
import { type Todo, todo, type TodoId } from '@/modules/todo/todo'

class D1TodoRepository implements ITodoRepository {
  constructor(private readonly d1: D1Database) {}

  private db() {
    return createDb(this.d1)
  }

  async findByUserId(userId: string) {
    try {
      const rows = await this.db()
        .select()
        .from(todoTable)
        .where(eq(todoTable.userId, userId))
        .orderBy(desc(todoTable.createdAt))
      return ok(rows.map(todo.fromRow))
    } catch (error) {
      return err(error instanceof Error ? error : new Error('Failed to list todos'))
    }
  }

  async findById(id: TodoId, userId: string) {
    try {
      const rows = await this.db()
        .select()
        .from(todoTable)
        .where(and(eq(todoTable.id, id), eq(todoTable.userId, userId)))
        .limit(1)
      return ok(rows[0] ? todo.fromRow(rows[0]) : null)
    } catch (error) {
      return err(error instanceof Error ? error : new Error('Failed to find todo'))
    }
  }

  async save(entity: Todo) {
    try {
      await this.db()
        .insert(todoTable)
        .values({
          id: entity.id,
          userId: entity.userId,
          title: entity.title,
          completed: entity.completed,
          createdAt: entity.createdAt,
          updatedAt: entity.updatedAt,
        })
        .onConflictDoUpdate({
          target: todoTable.id,
          set: {
            title: entity.title,
            completed: entity.completed,
            updatedAt: entity.updatedAt,
          },
        })
      return ok(entity)
    } catch (error) {
      return err(error instanceof Error ? error : new Error('Failed to save todo'))
    }
  }

  async delete(id: TodoId, userId: string) {
    try {
      await this.db()
        .delete(todoTable)
        .where(and(eq(todoTable.id, id), eq(todoTable.userId, userId)))
      return ok(undefined)
    } catch (error) {
      return err(error instanceof Error ? error : new Error('Failed to delete todo'))
    }
  }
}

export function createD1TodoRepository(d1: D1Database): ITodoRepository {
  return new D1TodoRepository(d1)
}
