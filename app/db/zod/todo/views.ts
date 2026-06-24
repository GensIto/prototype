import { z } from 'zod'

export const zTodoTitle = z
  .string()
  .trim()
  .min(1, 'Title is required')
  .max(200, 'Title must be 200 characters or less')

export const zTodoView = z.object({
  id: z.string(),
  title: z.string(),
  completed: z.boolean(),
  createdAt: z.string(),
})

export const zCreateTodoBody = z.object({
  title: zTodoTitle,
})

export type TodoView = z.infer<typeof zTodoView>
export type CreateTodoBody = z.infer<typeof zCreateTodoBody>

export type TodosPageProps = {
  auth: {
    user: {
      id: string
      name: string
      email: string
    }
  }
  todos: TodoView[]
  errors: Record<string, string>
}
