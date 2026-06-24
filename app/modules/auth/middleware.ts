import type { Context, Next } from 'hono'

import { type Auth, createAuth } from './create-auth'

export type AuthUser = {
  id: string
  name: string
  email: string
  image?: string | null
}

export type AppVariables = {
  auth: Auth
  user: AuthUser | null
  session: Auth['$Infer']['Session']['session'] | null
}

type Env = { Bindings: CloudflareBindings; Variables: AppVariables }

export async function authMiddleware(c: Context<Env>, next: Next) {
  const auth = createAuth(c.env, c.executionCtx)
  c.set('auth', auth)

  const session = await auth.api.getSession({ headers: c.req.raw.headers })
  c.set('user', session?.user ?? null)
  c.set('session', session?.session ?? null)

  await next()
}

export async function requireAuth(c: Context<Env>, next: Next) {
  if (!c.get('user')) {
    return c.redirect('/')
  }
  await next()
}
