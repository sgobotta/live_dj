import { bindings } from './bindings'

const actions = {
  'navigate-add': () => document.getElementById('add-btn')?.click(),
  'open-help': () => document.getElementById('help-btn')?.click(),
  'open-share': () => document.getElementById('share-btn')?.click(),
  'toggle-fullscreen': () => document.getElementById('fullscreen-btn')?.click(),
  'toggle-mute': () => document.getElementById('volume-mute-btn')?.click(),
  'toggle-play-pause': () =>
    (document.getElementById('pause-btn')
      ?? document.getElementById('play-btn'))?.click(),
  'toggle-theme': () => window.dispatchEvent(new Event('toggle-theme'))
}

const IGNORED_TAGS = new Set(['INPUT', 'TEXTAREA', 'SELECT'])

export default {
  destroyed() {
    window.removeEventListener('keydown', this._handler)
  },
  mounted() {
    this._handler = (e) => {
      if (this.el.dataset.active !== 'true') return
      if (IGNORED_TAGS.has(e.target.tagName) || e.target.isContentEditable) {
        return
      }
      if (e.metaKey || e.ctrlKey || e.altKey) return

      const action = bindings[e.key.toLowerCase()]
      if (action && actions[action]) {
        e.preventDefault()
        actions[action](this)
      }
    }
    window.addEventListener('keydown', this._handler)
  }
}
