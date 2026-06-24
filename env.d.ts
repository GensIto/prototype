interface CloudflareBindings {
  ENVIRONMENT: 'development' | 'staging' | 'production'
  BETTER_AUTH_SECRET: string
  BETTER_AUTH_URL: string
}

interface ImportMeta {
  glob<T = unknown>(
    pattern: string,
    options?: {
      eager?: boolean
      import?: string
      query?: string | Record<string, string | number | boolean | null | undefined>
    },
  ): Record<string, () => Promise<T>>
}
