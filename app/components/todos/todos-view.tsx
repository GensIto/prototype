import { Link } from '@inertiajs/react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { TodosPageProps } from '@/db/zod/todo/views'

export function TodosView({ auth, todos, errors }: TodosPageProps) {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-lg flex-col gap-6 p-8">
      <header className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Todos</h1>
          <p className="text-muted-foreground text-sm">{auth.user.name}</p>
        </div>
        <Button variant="outline" asChild>
          <a href="/">Home</a>
        </Button>
      </header>

      <form action="/todos" method="post" className="flex gap-2">
        <Input
          name="title"
          placeholder="What needs to be done?"
          aria-invalid={Boolean(errors.title)}
          defaultValue=""
        />
        <Button type="submit">Add</Button>
      </form>
      {errors.title ? <p className="text-destructive text-sm">{errors.title}</p> : null}

      <ul className="divide-border divide-y rounded-md border">
        {todos.length === 0 ? (
          <li className="text-muted-foreground p-4 text-sm">No todos yet.</li>
        ) : (
          todos.map((todo) => (
            <li key={todo.id} className="flex items-center gap-3 p-4">
              <Link
                href={`/todos/${todo.id}/toggle`}
                method="post"
                as="button"
                type="button"
                className={`flex h-5 w-5 shrink-0 items-center justify-center rounded border ${
                  todo.completed
                    ? 'bg-primary border-primary text-primary-foreground'
                    : 'border-input'
                }`}
                aria-label={todo.completed ? 'Mark incomplete' : 'Mark complete'}
              >
                {todo.completed ? '✓' : null}
              </Link>
              <span
                className={`flex-1 text-sm ${todo.completed ? 'text-muted-foreground line-through' : ''}`}
              >
                {todo.title}
              </span>
              <Link
                href={`/todos/${todo.id}`}
                method="delete"
                as="button"
                type="button"
                className="text-muted-foreground hover:text-destructive text-xs"
              >
                Delete
              </Link>
            </li>
          ))
        )}
      </ul>
    </main>
  )
}
