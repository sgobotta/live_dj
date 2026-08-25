import {describe, expect, it} from 'vitest'
import {groupIntoRows} from './hook'

describe('groupIntoRows', () => {
  it('groups cells sharing a row by their top offset', () => {
    const rows = groupIntoRows([
      {cell: 'a', left: 0, top: 0},
      {cell: 'b', left: 100, top: 0},
      {cell: 'c', left: 0, top: 80}
    ])

    expect(rows).toEqual([['a', 'b'], ['c']])
  })

  it('orders rows top to bottom and cells left to right', () => {
    const rows = groupIntoRows([
      {cell: 'c', left: 0, top: 80},
      {cell: 'b', left: 100, top: 0},
      {cell: 'a', left: 0, top: 0}
    ])

    expect(rows).toEqual([['a', 'b'], ['c']])
  })

  it('tolerates sub-pixel differences within the same row', () => {
    const rows = groupIntoRows([
      {cell: 'a', left: 0, top: 40.2},
      {cell: 'b', left: 100, top: 40.6}
    ])

    expect(rows).toEqual([['a', 'b']])
  })
})
