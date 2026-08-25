// Explicit grid navigation for a keyboard scope (see registry.js).
//
// A grid is declared as `rows`, a function returning an array of arrays of
// either CSS selectors (resolved against `container` at nav time) or
// elements directly. It's a function - not a plain array - so it can be
// re-invoked on every arrow press and always reflect the current DOM,
// which is what lets a grid survive LiveView patches that replace or
// reorder its elements without any cache-invalidation bookkeeping. Rows
// may be ragged (different lengths); moving vertically clamps the column
// to the target row's own length rather than requiring a rectangle.
export function createGrid({
  container,
  edgeBehavior = 'clamp',
  navKeyAttr = 'data-nav-key',
  rows
}) {
  let lastKey = null

  function resolvedContainer() {
    return typeof container === 'string'
      ? document.querySelector(container)
      : container
  }

  function resolveCell(cell, root) {
    return typeof cell === 'string' ? root.querySelector(cell) : cell
  }

  function resolveGrid() {
    const root = resolvedContainer()
    if (!root) return []

    return rows()
      .map((row) => row.map((cell) => resolveCell(cell, root)).filter(Boolean))
      .filter((row) => row.length > 0)
  }

  function currentCoords(grid) {
    const active = document.activeElement
    for (let row = 0; row < grid.length; row += 1) {
      const col = grid[row].indexOf(active)
      if (col !== -1) return [row, col]
    }
    return null
  }

  function focusCell(cell) {
    lastKey = cell.getAttribute(navKeyAttr)
    cell.focus()
    cell.scrollIntoView({block: 'nearest', inline: 'nearest'})
  }

  return {
    move(key) {
      const grid = resolveGrid()
      if (grid.length === 0) return false

      const [row, col] = currentCoords(grid) ?? [0, 0]
      const [nextRow, nextCol] = nextCoords(key, row, col, grid, edgeBehavior)
      const cell = grid[nextRow]?.[nextCol]
      if (!cell) return false

      focusCell(cell)
      return true
    },

    // Call from a consumer's own updated()/patch hook: if a LiveView patch
    // dropped focus to <body> (its target element was replaced), re-focus
    // whichever element now carries the last-focused identity attribute.
    reconcileFocus() {
      if (lastKey === null) return
      if (document.activeElement !== document.body) return

      const root = resolvedContainer()
      const selector = `[${navKeyAttr}="${CSS.escape(lastKey)}"]`
      const target = root?.querySelector(selector)
      if (target) focusCell(target)
    }
  }
}

export function stepIndex(index, delta, length, edgeBehavior) {
  const next = index + delta
  if (next >= 0 && next < length) return next
  if (edgeBehavior === 'wrap') return (next + length) % length
  return index
}

export function nextCoords(key, row, col, grid, edgeBehavior) {
  if (key === 'arrowup' || key === 'arrowdown') {
    const delta = key === 'arrowdown' ? 1 : -1
    const nextRow = stepIndex(row, delta, grid.length, edgeBehavior)
    const nextCol = Math.min(col, grid[nextRow].length - 1)
    return [nextRow, nextCol]
  }

  const delta = key === 'arrowright' ? 1 : -1
  const nextCol = stepIndex(col, delta, grid[row].length, edgeBehavior)
  return [row, nextCol]
}
