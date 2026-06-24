import { Button } from '@/components/ui/button'
import type { HomePageProps } from '@/db/zod/shared/forms'

export function HomeView({ auth }: HomePageProps) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-3xl font-bold tracking-tight">prottype</h1>
      <p className="text-muted-foreground max-w-md text-center">
        Cloudflare Workers + Hono + Inertia.js + React 19 + D1 + Better Auth
      </p>
      {auth.user ? (
        <div className="flex flex-col items-center gap-3">
          <p className="text-sm">Signed in as {auth.user.name}</p>
          <Button asChild>
            <a href="/todos">Open Todos</a>
          </Button>
        </div>
      ) : (
        <div className="flex gap-3">
          <Button asChild>
            <a href="/api/auth/sign-in/email">Sign in</a>
          </Button>
          <Button variant="outline" asChild>
            <a href="/api/auth/sign-up/email">Sign up</a>
          </Button>
        </div>
      )}
    </main>
  )
}
