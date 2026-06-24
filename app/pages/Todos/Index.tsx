import { TodosView } from '@/components/todos/todos-view'
import type { TodosPageProps } from '@/db/zod/todo/views'

export default function Index(props: TodosPageProps) {
  return <TodosView {...props} />
}
