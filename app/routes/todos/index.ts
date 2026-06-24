import { zValidator } from '@hono/zod-validator'
import { Hono } from 'hono'

import { zCreateTodoBody } from '@/db/zod/todo/views'
import { requireAuth } from '@/modules/auth/middleware'
import { createD1TodoRepository } from '@/modules/todo/adapters/d1-todo-repository'
import { serializeTodos } from '@/modules/todo/serialize'
import { todo } from '@/modules/todo/todo'
import type { RouteEnv } from '@/routes/types'

export const todosRoutes = new Hono<RouteEnv>()

todosRoutes.use('*', requireAuth)

todosRoutes.get('/todos', async (c) => {
  const user = c.get('user')!
  const repo = createD1TodoRepository(c.env.DB)
  const result = await repo.findByUserId(user.id)

  if (!result.ok) {
    throw result.error
  }

  return c.render('Todos/Index', {
    auth: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    },
    todos: serializeTodos(result.value),
    errors: {},
  })
})

todosRoutes.post('/todos', zValidator('form', zCreateTodoBody), async (c) => {
  const user = c.get('user')!
  const { title } = c.req.valid('form')
  const created = todo.create({
    userId: user.id,
    title,
    id: todo.parseId(crypto.randomUUID()),
  })

  if (!created.ok) {
    const repo = createD1TodoRepository(c.env.DB)
    const list = await repo.findByUserId(user.id)
    if (!list.ok) throw list.error

    return c.render('Todos/Index', {
      auth: {
        user: { id: user.id, name: user.name, email: user.email },
      },
      todos: serializeTodos(list.value),
      errors: { title: created.error.message },
    })
  }

  const repo = createD1TodoRepository(c.env.DB)
  const saved = await repo.save(created.value)
  if (!saved.ok) throw saved.error

  return c.redirect('/todos')
})

todosRoutes.post('/todos/:id/toggle', async (c) => {
  const user = c.get('user')!
  const id = todo.parseId(c.req.param('id'))
  const repo = createD1TodoRepository(c.env.DB)

  const found = await repo.findById(id, user.id)
  if (!found.ok) throw found.error
  if (!found.value) {
    return c.redirect('/todos')
  }

  const toggled = todo.toggle(found.value)
  if (!toggled.ok) throw toggled.error

  const saved = await repo.save(toggled.value)
  if (!saved.ok) throw saved.error

  return c.redirect('/todos')
})

todosRoutes.delete('/todos/:id', async (c) => {
  const user = c.get('user')!
  const id = todo.parseId(c.req.param('id'))
  const repo = createD1TodoRepository(c.env.DB)

  const deleted = await repo.delete(id, user.id)
  if (!deleted.ok) throw deleted.error

  return c.redirect('/todos')
})
