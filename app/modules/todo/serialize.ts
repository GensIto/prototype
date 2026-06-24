import type { TodoView } from '@/db/zod/todo/views'
import type { Todo } from '@/modules/todo/todo'

export function serializeTodo(todo: Todo): TodoView {
  return {
    id: todo.id,
    title: todo.title,
    completed: todo.completed,
    createdAt: todo.createdAt.toISOString(),
  }
}

export function serializeTodos(todos: Todo[]): TodoView[] {
  return todos.map(serializeTodo)
}
