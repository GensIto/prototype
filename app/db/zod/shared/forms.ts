import { z } from 'zod'

export const zFormErrors = z.record(z.string(), z.string())

export const zUserView = z.object({
  id: z.string().optional(),
  name: z.string(),
  email: z.string(),
  image: z.string().nullable().optional(),
})

export type FormErrors = z.infer<typeof zFormErrors>
export type UserView = z.infer<typeof zUserView>

export type HomePageProps = {
  auth: {
    user: UserView | null
  }
}
