// Stack-based keyboard scope registry.
//
// A "scope" is a consumer-declared set of key bindings plus an optional
// grid (see grid.js) for arrow-key navigation. Consumers push a scope when
// they become the thing the user is interacting with (a page becomes
// active, a modal opens, a panel expands) and pop it when that stops being
// true. Only the topmost scope on the stack ever sees a keydown, which is
// what gives suspend/restore behavior for free: a scope shadowed by one
// pushed on top of it simply isn't consulted until it's on top again, and
// its own state (grid cursor position, etc.) sits untouched in the
// meantime since it's never popped, only shadowed.
const ARROW_KEYS = new Set(['arrowdown', 'arrowleft', 'arrowright', 'arrowup'])
const IGNORED_TAGS = new Set(['INPUT', 'SELECT', 'TEXTAREA'])

let attached = false
let stack = []

function isEditableTarget(target) {
  return IGNORED_TAGS.has(target.tagName) || target.isContentEditable
}

function normalizeScope(scope) {
  return {
    allowModifiers: scope.allowModifiers ?? false,
    bindings: scope.bindings ?? {},
    grid: scope.grid ?? null,
    id: scope.id,
    ignoreInputs: scope.ignoreInputs ?? true
  }
}

function removeEntry(entry) {
  const index = stack.indexOf(entry)
  if (index !== -1) stack.splice(index, 1)
}

function handleKeydown(event) {
  const scope = stack[stack.length - 1]
  if (!scope) return

  const hasModifier = event.metaKey || event.ctrlKey || event.altKey
  if (!scope.allowModifiers && hasModifier) {
    return
  }

  if (scope.ignoreInputs && isEditableTarget(event.target)) return

  const key = event.key.toLowerCase()

  if (scope.grid && ARROW_KEYS.has(key)) {
    if (scope.grid.move(key)) event.preventDefault()
    return
  }

  const handler = scope.bindings[key]
  if (handler) {
    event.preventDefault()
    handler(event)
  }
}

function ensureListener() {
  if (attached) return
  attached = true
  window.addEventListener('keydown', handleKeydown)
}

// Pushes a scope onto the stack and returns a detach function. Prefer
// calling the returned function over popScope: it removes exactly the
// entry it created, so it can't accidentally pop a different scope that
// happens to share the same id.
export function pushScope(scope) {
  const entry = normalizeScope(scope)
  stack.push(entry)
  ensureListener()
  return () => removeEntry(entry)
}

// Convenience for call sites that don't hold onto the detach function -
// pops the most recently pushed scope with a matching id, if any.
export function popScope(id) {
  const index = stack.map((entry) => entry.id).lastIndexOf(id)
  if (index !== -1) stack.splice(index, 1)
}

export function _resetForTests() {
  stack = []
}
