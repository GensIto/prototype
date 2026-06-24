import { describe, expect, it } from 'vitest'

import { todo } from '@/modules/todo/todo'

describe('todo.create', () => {
  it('accepts a non-empty trimmed title', () => {
    const result = todo.create({
      userId: 'user-1',
      title: '  Buy milk  ',
      id: todo.parseId('todo-1'),
    })
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.title).toBe('Buy milk')
      expect(result.value.completed).toBe(false)
    }
  })

  it('rejects empty title', () => {
    const result = todo.create({
      userId: 'user-1',
      title: '   ',
      id: todo.parseId('todo-1'),
    })
    expect(result.ok).toBe(false)
  })

  it('rejects title over 200 characters', () => {
    const result = todo.create({
      userId: 'user-1',
      title: 'a'.repeat(201),
      id: todo.parseId('todo-1'),
    })
    expect(result.ok).toBe(false)
  })
})

describe('todo.toggle', () => {
  it('flips completed without mutating original', () => {
    const entity = todo.create({
      userId: 'user-1',
      title: 'Task',
      id: todo.parseId('todo-1'),
    })
    if (!entity.ok) throw entity.error

    const result = todo.toggle(entity.value)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.completed).toBe(true)
      expect(entity.value.completed).toBe(false)
    }
  })
})

describe('todo.fromRow', () => {
  it('maps a database row with destructuring', () => {
    const createdAt = new Date('2026-01-01T00:00:00.000Z')
    const updatedAt = new Date('2026-01-02T00:00:00.000Z')

    const entity = todo.fromRow({
      id: 'todo-1',
      userId: 'user-1',
      title: 'Task',
      completed: false,
      createdAt,
      updatedAt,
    })

    expect(entity.id).toBe('todo-1')
    expect(entity.userId).toBe('user-1')
    expect(entity.title).toBe('Task')
    expect(entity.createdAt).toBe(createdAt)
  })
})
