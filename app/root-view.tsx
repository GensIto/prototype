import { type PageObject, type RootView, serializePage } from '@hono/inertia'
import { renderToString } from 'react-dom/server'
import { Link, Script, ViteClient } from 'vite-ssr-components/react'

const Document = ({ page }: { page: PageObject }) => (
  <html lang="ja">
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>prottype</title>
      <ViteClient />
      <Script src="/app/client.tsx" />
      <Link href="/app/styles.css" rel="stylesheet" />
    </head>
    <body>
      <script
        data-page="app"
        type="application/json"
        dangerouslySetInnerHTML={{ __html: serializePage(page) }}
      />
      <div id="app" />
    </body>
  </html>
)

export const rootView: RootView = (page) =>
  '<!DOCTYPE html>' + renderToString(<Document page={page} />)
