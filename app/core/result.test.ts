import { describe, expect, it } from 'vitest'

import { err, ok, ValidationError } from '@/core/result'

describe('Result', () => {
  it('ok - 成功値をラップできる', () => {
    const result = ok(42)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe(42)
    }
  })

  it('err - エラーをラップできる', () => {
    const error = new ValidationError('invalid')
    const result = err(error)
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.message).toBe('invalid')
    }
  })
})
