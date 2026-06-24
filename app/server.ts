import { inertia } from '@hono/inertia'
import { Hono } from 'hono'

import { type AppVariables, authMiddleware } from '@/modules/auth/middleware'
import { homeRoutes } from '@/routes/home'
import { todosRoutes } from '@/routes/todos'

import { rootView } from './root-view'

type Env = {
  Bindings: CloudflareBindings
  Variables: AppVariables
}

const app = new Hono<Env>()

app.use('*', authMiddleware)

app.on(['GET', 'POST'], '/api/auth/*', (c) => {
  return c.get('auth').handler(c.req.raw)
})

app.use(
  inertia({
    rootView,
    version: '1',
  }),
)

app.route('/', homeRoutes)
app.route('/', todosRoutes)

export default app
