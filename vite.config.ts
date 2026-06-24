import path from 'node:path'

import { cloudflare } from '@cloudflare/vite-plugin'
import { inertiaPages } from '@hono/inertia/vite'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import ssrPlugin from 'vite-ssr-components/plugin'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    inertiaPages({
      pagesDir: 'app/pages',
      outFile: 'app/pages.gen.ts',
      serverModule: './server',
      exclude: ['Layout'],
    }),
    cloudflare(),
    ssrPlugin(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'app'),
    },
  },
})
