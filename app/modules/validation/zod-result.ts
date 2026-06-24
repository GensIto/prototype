import type { ZodSafeParseResult, ZodType } from 'zod'

import { err, ok, type Result, ValidationError } from '@/core/result'

export function zodToResult<T>(schema: ZodType<T>, data: unknown): Result<T, ValidationError> {
  const parsed = schema.safeParse(data)
  if (parsed.success) {
    return ok(parsed.data)
  }

  return err(new ValidationError(parsed.error.issues[0]?.message ?? 'Validation failed'))
}

export function safeParseToResult<T>(parsed: ZodSafeParseResult<T>): Result<T, ValidationError> {
  if (parsed.success) {
    return ok(parsed.data)
  }

  return err(new ValidationError(parsed.error.issues[0]?.message ?? 'Validation failed'))
}
