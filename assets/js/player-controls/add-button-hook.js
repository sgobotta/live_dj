const BROWSE_SUFFIX = '/browse'

export default {
  _applyState() {
    const active = this._active
    this.el.classList.toggle('bg-zinc-300', !active)
    this.el.classList.toggle('dark:bg-zinc-700', !active)
    this.el.classList.toggle('bg-zinc-200', active)
    this.el.classList.toggle('dark:bg-zinc-800', active)
    this.el.classList.toggle('text-zinc-900', !active)
    this.el.classList.toggle('dark:text-zinc-100', !active)
    this.el.classList.toggle('text-green-500', active)
    this.el.classList.toggle('dark:text-green-500', active)
    this.el.classList.toggle(
      'shadow-[2.0px_2.0px_1px_0.5px_rgba(24,24,27,0.5)]', !active)
    this.el.classList.toggle(
      'dark:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.4)]', !active)
    this.el.classList.toggle(
      'shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]', active)
    this.el.classList.toggle(
      'dark:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]', active)
  },
  destroyed() {
    window.removeEventListener('phx:page-loading-stop', this._navHandler)
  },
  mounted() {
    this._active = window.location.pathname.endsWith(BROWSE_SUFFIX)
    this._applyState()

    this._navHandler = () => {
      this._active = window.location.pathname.endsWith(BROWSE_SUFFIX)
      this._applyState()
    }
    window.addEventListener('phx:page-loading-stop', this._navHandler)
  },
  updated() {
    this._applyState()
  }
}
