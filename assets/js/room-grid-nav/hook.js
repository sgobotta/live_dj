import {createGrid, pushScope} from '../keyboard'

// The rooms grid's column count is a CSS breakpoint (grid-cols-2
// sm:grid-cols-3 - see custom_components.ex's room_grid/1), not something
// a static authored layout can know ahead of time. So, uniquely among
// this app's scopes, its rows are built by bucketing live layout instead
// of an explicit author-declared array - every other scope stays purely
// explicit.
export function groupIntoRows(entries) {
  const rows = []

  entries
    .slice()
    .sort((a, b) => a.top - b.top || a.left - b.left)
    .forEach(({cell, top}) => {
      const row = rows.find((candidate) => Math.abs(candidate.top - top) < 1)
      if (row) {
        row.cells.push(cell)
      } else {
        rows.push({cells: [cell], top})
      }
    })

  return rows.map((row) => row.cells)
}

function currentRows(container) {
  const entries = Array.from(container.querySelectorAll('a')).map((cell) => {
    const rect = cell.getBoundingClientRect()
    return {cell, left: rect.left, top: rect.top}
  })

  return groupIntoRows(entries)
}

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    const grid = createGrid({
      container: this.el,
      edgeBehavior: 'clamp',
      rows: () => currentRows(this.el)
    })
    this.detach = pushScope({grid, id: 'room-grid'})
  }
}
