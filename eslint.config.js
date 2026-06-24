import eslint from '@eslint/js'
import simpleImportSort from 'eslint-plugin-simple-import-sort'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: [
      'dist/**',
      'node_modules/**',
      'worker-configuration.d.ts',
      'migrations/**',
      'app/pages.gen.ts',
    ],
  },
  {
    plugins: {
      'simple-import-sort': simpleImportSort,
    },
    rules: {
      'simple-import-sort/imports': 'error',
      'simple-import-sort/exports': 'error',
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'inline-type-imports' },
      ],
    },
  },
  {
    files: ['app/pages/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/modules/*', '@/db/schema/*', '@/routes/*'],
        },
      ],
    },
  },
  {
    files: ['app/components/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/modules/*', '@/routes/*', '@/db/schema/*'],
        },
      ],
    },
  },
  {
    files: ['app/utils/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/modules/*', '@/routes/*', '@/pages/*', '@/components/*', '@/db/schema/*'],
        },
      ],
    },
  },
  {
    files: ['app/routes/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/db/schema/*', '@/pages/*', '@/components/*'],
        },
      ],
    },
  },
  {
    files: ['app/modules/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/pages/*', '@/routes/*', '@/components/*'],
        },
      ],
    },
  },
  {
    files: ['app/db/zod/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          patterns: ['@/modules/*', '@/routes/*', '@/pages/*', '@/components/*'],
        },
      ],
    },
  },
)
