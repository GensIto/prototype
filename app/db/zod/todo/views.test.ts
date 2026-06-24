import { describe, expect, it } from 'vitest'

import { zTodoTitle } from '@/db/zod/todo/views'

describe('zTodoTitle', () => {
  it('trims and accepts a non-empty title', () => {
    const result = zTodoTitle.safeParse('  Buy milk  ')
    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data).toBe('Buy milk')
    }
  })

  it('rejects empty title', () => {
    const result = zTodoTitle.safeParse('   ')
    expect(result.success).toBe(false)
  })

  it('rejects title over 200 characters', () => {
    const result = zTodoTitle.safeParse('a'.repeat(201))
    expect(result.success).toBe(false)
  })
})
