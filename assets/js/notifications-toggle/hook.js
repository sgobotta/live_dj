// Owns the on/off visual state of the notifications toggle switch and
// persists the preference to localStorage. Kept separate from the
// TrackNotifications hook (which lives in a different LiveView) so this
// stays a simple, self-contained UI control - the two communicate only
// through localStorage, checked fresh on every track change.
const STORAGE_KEY = 'livedj_track_notifications_enabled'

export default {
  isEnabled() {
    return localStorage.getItem(STORAGE_KEY) === 'true'
  },

  mounted() {
    this.render(this.isEnabled())

    this.el.addEventListener('click', () => {
      const next = !this.isEnabled()
      localStorage.setItem(STORAGE_KEY, String(next))
      this.render(next)
    })
  },

  render(enabled) {
    const knob = this.el.firstElementChild
    this.el.setAttribute('aria-checked', String(enabled))
    this.el.classList.toggle('bg-brand', enabled)
    this.el.classList.toggle('bg-tone-300', !enabled)
    this.el.classList.toggle('dark:bg-tone-600', !enabled)
    knob.classList.toggle('translate-x-6', enabled)
    knob.classList.toggle('translate-x-1', !enabled)
  }
}
