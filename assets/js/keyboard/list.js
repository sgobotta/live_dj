import {createGrid} from './grid'

// Convenience wrapper over createGrid for the common single-column case
// (a vertical list), so callers don't have to wrap their item list in a
// one-row-per-item grid themselves.
export function createListScope({container, edgeBehavior, items, navKeyAttr}) {
  return createGrid({
    container,
    edgeBehavior,
    navKeyAttr,
    rows: () => items().map((item) => [item])
  })
}
