import type { Result } from '@/core/result'

import type { Todo, TodoId } from './todo'

export interface ITodoRepository {
  findByUserId(userId: string): Promise<Result<Todo[], Error>>
  findById(id: TodoId, userId: string): Promise<Result<Todo | null, Error>>
  save(todo: Todo): Promise<Result<Todo, Error>>
  delete(id: TodoId, userId: string): Promise<Result<void, Error>>
}
