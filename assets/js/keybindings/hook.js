import { bindings } from './bindings'

const actions = {
  'toggle-theme': () => window.dispatchEvent(new Event('toggle-theme'))
}

const IGNORED_TAGS = new Set(['INPUT', 'TEXTAREA', 'SELECT'])

export default {
  destroyed() {
    window.removeEventListener('keydown', this._handler)
  },
  mounted() {
    console.info('Keybindings hook mounted, active:', this.el.dataset.active)
    this._handler = (e) => {
      if (this.el.dataset.active !== 'true') return
      if (IGNORED_TAGS.has(e.target.tagName) || e.target.isContentEditable) {
        return
      }
      if (e.metaKey || e.ctrlKey || e.altKey) return

      const action = bindings[e.key.toLowerCase()]
      if (action && actions[action]) actions[action](this)
    }
    window.addEventListener('keydown', this._handler)
  }
}
