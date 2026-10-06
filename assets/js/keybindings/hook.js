import {bindings} from './bindings'
import {pushScope} from '../keyboard'

const actions = {
  'focus-chat': (hook) => hook.pushEvent('open_and_focus_chat', {}),
  'navigate-add': () => document.getElementById('add-btn')?.click(),
  'open-help': () => document.getElementById('help-btn')?.click(),
  'open-settings': () => document.getElementById('settings-btn')?.click(),
  'open-share': () => document.getElementById('share-btn')?.click(),
  'toggle-chat': () => document.getElementById('chat-btn')?.click(),
  'toggle-fullscreen': () => document.getElementById('fullscreen-btn')?.click(),
  'toggle-mute': () => document.getElementById('volume-mute-btn')?.click(),
  'toggle-play-pause': () =>
    document.getElementById('play-pause-btn')?.click(),
  'toggle-theme': () => window.dispatchEvent(new Event('toggle-theme'))
}

// Optional allow-list: `data-bindings="toggle-theme"` enables only those
// actions. Absent means every binding is active (full show-page set).
function parseAllowList(value) {
  return value ? new Set(value.split(/[\s,]+/).filter(Boolean)) : null
}

function buildBindings(hook, allowed) {
  const entries = {}

  Object.entries(bindings).forEach(([key, action]) => {
    const enabled = (!allowed || allowed.has(action)) && actions[action]
    if (enabled) entries[key] = () => actions[action](hook)
  })

  return entries
}

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    this.handleEvent('focus_chat_input', () => {
      document.getElementById('chat-input')?.focus()
    })

    this.isActive = false
    this.syncScope()
  },

  // The room/index pages toggle `data-active` on this same element (rather
  // than remounting the hook) as their live_action changes - e.g. a modal
  // opening. Mirror that as a real push/pop on the registry so the room's
  // bindings genuinely suspend while a scope above it is on top, instead of
  // relying on a per-keystroke flag check.
  syncScope() {
    const active = this.el.dataset.active === 'true'
    if (active === this.isActive) return
    this.isActive = active

    if (!active) {
      this.detach?.()
      this.detach = null
      return
    }

    const allowed = parseAllowList(this.el.dataset.bindings)
    this.detach = pushScope({
      bindings: buildBindings(this, allowed),
      id: this.el.id
    })
  },

  updated() {
    this.syncScope()
  }
}
