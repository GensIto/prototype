import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  dialect: 'sqlite',
  driver: 'd1-http',
  schema: './app/db/schema/index.ts',
  out: './migrations',
  migrations: {
    prefix: 'timestamp',
  },
})
