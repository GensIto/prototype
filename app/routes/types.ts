import type { AppVariables } from '@/modules/auth/middleware'

export type RouteEnv = {
  Bindings: CloudflareBindings
  Variables: AppVariables
}
