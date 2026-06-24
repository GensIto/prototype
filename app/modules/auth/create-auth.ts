import { drizzleAdapter } from '@better-auth/drizzle-adapter'
import { betterAuth } from 'better-auth'

import { createDb } from '@/db'
import * as schema from '@/db/schema'

type AuthExecutionContext = {
  waitUntil(promise: Promise<unknown>): void
}

export function createAuth(env: CloudflareBindings, ctx?: AuthExecutionContext) {
  const db = createDb(env.DB)

  return betterAuth({
    appName: 'prottype',
    baseURL: env.BETTER_AUTH_URL,
    secret: env.BETTER_AUTH_SECRET,
    trustedOrigins: [env.BETTER_AUTH_URL, 'http://localhost:5173', 'http://127.0.0.1:5173'],
    database: drizzleAdapter(db, {
      provider: 'sqlite',
      schema,
      transaction: false,
    }),
    emailAndPassword: { enabled: true },
    advanced: {
      useSecureCookies: env.BETTER_AUTH_URL.startsWith('https'),
      ipAddress: {
        ipAddressHeaders: ['cf-connecting-ip', 'x-forwarded-for'],
      },
      backgroundTasks: ctx
        ? {
            handler: (promise) => {
              ctx.waitUntil(promise.catch(console.error))
            },
          }
        : undefined,
    },
  })
}

export type Auth = ReturnType<typeof createAuth>
