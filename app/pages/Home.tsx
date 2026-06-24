import { HomeView } from '@/components/home/home-view'
import type { HomePageProps } from '@/db/zod/shared/forms'

export default function Home(props: HomePageProps) {
  return <HomeView {...props} />
}
