import { Hono } from 'hono'

import type { RouteEnv } from '@/routes/types'

export const homeRoutes = new Hono<RouteEnv>()

homeRoutes.get('/', (c) => {
  const user = c.get('user')

  return c.render('Home', {
    auth: {
      user: user
        ? {
            id: user.id,
            name: user.name,
            email: user.email,
            image: user.image,
          }
        : null,
    },
  })
})
