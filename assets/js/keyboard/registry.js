// Stack-based keyboard scope registry.
//
// A "scope" is a consumer-declared set of key bindings plus an optional
// grid (see grid.js) for arrow-key navigation. Consumers push a scope when
// they become the thing the user is interacting with (a page becomes
// active, a modal opens, a panel expands) and pop it when that stops being
// true.
//
// A keydown resolves top-down through the stack, per key: the first scope
// that actually claims the key (has a binding for it, or owns a grid whose
// container currently contains focus) wins, and resolution stops there.
// This is *not* "only the topmost scope is ever consulted" - that would
// make an always-mounted, arrows-only scope (e.g. a playlist) permanently
// block an always-mounted, letters-only scope (e.g. global shortcuts)
// simply by being pushed after it, even though the two never actually
// compete for the same key. Genuine exclusivity (a modal taking over the
// whole keyboard) instead comes from the lower scope detaching itself
// while the modal is open, per its own `data-active`/equivalent state -
// see keybindings/hook.js - so there's nothing left below to fall through
// to.
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

// Returns true if `scope` claimed the event (and performed its effect).
function tryScope(scope, event, key, editable, hasModifier) {
  if (!scope.allowModifiers && hasModifier) return false
  if (scope.ignoreInputs && editable) return false

  if (ARROW_KEYS.has(key) && scope.grid && scope.grid.move(key)) {
    event.preventDefault()
    return true
  }

  const handler = scope.bindings[key]
  if (handler) {
    // A handler can return `false` to decline after all (e.g. it only
    // wants this key in some circumstance it alone can determine, like an
    // input whose command palette isn't currently showing any options),
    // letting resolution fall through to the next scope down instead of
    // unconditionally treating "has a handler" as "claims the event".
    if (handler(event) === false) return false
    event.preventDefault()
    return true
  }

  return false
}

function handleKeydown(event) {
  const key = event.key.toLowerCase()
  const editable = isEditableTarget(event.target)
  const hasModifier = event.metaKey || event.ctrlKey || event.altKey

  const topDown = stack.slice().reverse()
  topDown.some((scope) => tryScope(scope, event, key, editable, hasModifier))
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
