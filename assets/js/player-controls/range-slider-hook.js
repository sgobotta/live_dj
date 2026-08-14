import { syncRangeSliderVisual } from '../lib/range-slider'

// Keeps a .custom-slider's fill/thumb in sync with its native range input.
// Unlike the seek bar (driven entirely client-side by the Youtube hook),
// this slider's value is server-controlled via phx-change, so the visual
// needs to resync both on direct user input (for immediate feedback ahead
// of the debounced round trip) and after each LiveView patch.
export default {
  destroyed() {
    this.el.removeEventListener('input', this._onInput)
  },
  mounted() {
    syncRangeSliderVisual(this.el)
    this._onInput = () => syncRangeSliderVisual(this.el)
    this.el.addEventListener('input', this._onInput)
  },
  updated() {
    syncRangeSliderVisual(this.el)
  }
}
