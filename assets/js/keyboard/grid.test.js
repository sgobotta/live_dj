import {beforeEach, describe, expect, it} from 'vitest'
import {createGrid, nextCoords, stepIndex} from './grid'

describe('stepIndex', () => {
  it('moves within range', () => {
    expect(stepIndex(1, 1, 3, 'clamp')).toBe(2)
  })

  it('clamps at the upper edge', () => {
    expect(stepIndex(2, 1, 3, 'clamp')).toBe(2)
  })

  it('clamps at the lower edge', () => {
    expect(stepIndex(0, -1, 3, 'clamp')).toBe(0)
  })

  it('wraps past the upper edge', () => {
    expect(stepIndex(2, 1, 3, 'wrap')).toBe(0)
  })

  it('wraps past the lower edge', () => {
    expect(stepIndex(0, -1, 3, 'wrap')).toBe(2)
  })
})

describe('nextCoords', () => {
  const raggedGrid = [
    ['a', 'b', 'c'],
    ['d']
  ]

  it('moves down a column and clamps into a shorter row', () => {
    expect(nextCoords('arrowdown', 0, 2, raggedGrid, 'clamp')).toEqual([1, 0])
  })

  it('moves up a column back into a longer row', () => {
    expect(nextCoords('arrowup', 1, 0, raggedGrid, 'clamp')).toEqual([0, 0])
  })

  it('moves right within a row', () => {
    expect(nextCoords('arrowright', 0, 0, raggedGrid, 'clamp')).toEqual([0, 1])
  })

  it('clamps at the end of a row', () => {
    expect(nextCoords('arrowright', 0, 2, raggedGrid, 'clamp')).toEqual([0, 2])
  })

  it('wraps at the end of a row when configured to', () => {
    expect(nextCoords('arrowright', 0, 2, raggedGrid, 'wrap')).toEqual([0, 0])
  })
})

describe('createGrid', () => {
  let container

  beforeEach(() => {
    document.body.innerHTML = ''
    container = document.createElement('div')
    document.body.appendChild(container)
  })

  function addCell(row, navKey) {
    const cell = document.createElement('button')
    cell.dataset.row = String(row)
    cell.dataset.navKey = navKey
    cell.textContent = navKey
    container.appendChild(cell)
    return cell
  }

  it('focuses the next cell moving down a ragged grid', () => {
    const a1 = addCell(0, 'a1')
    addCell(0, 'a2')
    const b1 = addCell(1, 'b1')

    const grid = createGrid({
      container,
      rows: () => [
        [a1, container.querySelector('[data-nav-key="a2"]')],
        [b1]
      ]
    })

    a1.focus()
    expect(grid.move('arrowdown')).toBe(true)
    expect(document.activeElement).toBe(b1)
  })

  it('declines the key when focus is outside its container', () => {
    const a1 = addCell(0, 'a1')
    const outside = document.createElement('button')
    document.body.appendChild(outside)

    const grid = createGrid({container, rows: () => [[a1]]})

    outside.focus()
    expect(grid.move('arrowdown')).toBe(false)
    expect(document.activeElement).toBe(outside)
  })

  it('bootstraps to the first cell on a forward key from the container', () => {
    const a1 = addCell(0, 'a1')
    const b1 = addCell(1, 'b1')

    const grid = createGrid({container, rows: () => [[a1], [b1]]})

    container.tabIndex = 0
    container.focus()
    grid.move('arrowdown')
    expect(document.activeElement).toBe(a1)
  })

  it('bootstraps to the last cell on a backward key from the container', () => {
    const a1 = addCell(0, 'a1')
    const a2 = addCell(0, 'a2')

    const grid = createGrid({container, rows: () => [[a1, a2]]})

    container.tabIndex = 0
    container.focus()
    grid.move('arrowleft')
    expect(document.activeElement).toBe(a2)
  })

  it('returns false and does nothing when the grid is empty', () => {
    const grid = createGrid({container, rows: () => []})
    expect(grid.move('arrowdown')).toBe(false)
  })

  it('reconciles focus onto the element carrying the last nav key', () => {
    const first = addCell(0, 'x')

    const grid = createGrid({
      container,
      rows: () => [[container.querySelector('[data-nav-key="x"]')]]
    })

    first.focus()
    grid.move('arrowdown')

    // Simulate a LiveView patch replacing the focused element: the old
    // node is removed, a new one with the same identity attribute takes
    // its place, and focus drops to <body>.
    first.remove()
    const replacement = addCell(0, 'x')
    document.body.focus()

    grid.reconcileFocus()
    expect(document.activeElement).toBe(replacement)
  })
})
