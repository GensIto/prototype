import { drizzleAdapter } from '@better-auth/drizzle-adapter'
import { betterAuth } from 'better-auth'

import { createDb } from '@/db'
import * as schema from '@/db/schema'

type AuthExecutionContext = {
  waitUntil(promise: Promise<unknown>): void
}

type CreateAuthOptions = {
  requestUrl?: string
}

function resolveAuthBaseUrl(env: CloudflareBindings, requestUrl?: string) {
  if (requestUrl) {
    return new URL(requestUrl).origin
  }

  return env.BETTER_AUTH_URL
}

export function createAuth(
  env: CloudflareBindings,
  ctx?: AuthExecutionContext,
  options?: CreateAuthOptions,
) {
  const db = createDb(env.DB)
  const baseURL = resolveAuthBaseUrl(env, options?.requestUrl)
  const trustedOrigins = [
    ...new Set([env.BETTER_AUTH_URL, baseURL, 'http://localhost:5173', 'http://127.0.0.1:5173']),
  ]

  return betterAuth({
    appName: 'prottype',
    baseURL,
    secret: env.BETTER_AUTH_SECRET,
    trustedOrigins,
    database: drizzleAdapter(db, {
      provider: 'sqlite',
      schema,
      transaction: false,
    }),
    emailAndPassword: { enabled: true },
    advanced: {
      useSecureCookies: baseURL.startsWith('https'),
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
