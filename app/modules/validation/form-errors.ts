import type { ZodError } from 'zod'

import type { FormErrors } from '@/db/zod/shared/forms'

export type { FormErrors }

export function zodToFormErrors(error: ZodError): FormErrors {
  const errors: FormErrors = {}
  for (const issue of error.issues) {
    const path = issue.path.join('.')
    if (!errors[path]) {
      errors[path] = issue.message
    }
  }
  return errors
}
