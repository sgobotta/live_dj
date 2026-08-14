// Syncs a custom-rendered fill/thumb pair to a native <input type="range">'s
// current value. The input stays functional (drag, click-to-seek, keyboard,
// touch, a11y) but is rendered fully transparent — see .custom-slider in
// assets/css/widgets/slider.css — so this is the only thing making the
// slider visible.
export function syncRangeSliderVisual(inputEl) {
  const wrapper = inputEl.closest('.custom-slider')
  if (!wrapper) return

  const fillEl = wrapper.querySelector('.custom-slider-fill')
  const thumbEl = wrapper.querySelector('.custom-slider-thumb')
  if (!fillEl && !thumbEl) return

  const min = parseFloat(inputEl.min) || 0
  const max = parseFloat(inputEl.max) || 100
  const value = parseFloat(inputEl.value) || 0
  const range = max - min
  const percent = range > 0 ? ((value - min) / range) * 100 : 0
  const clamped = Math.min(100, Math.max(0, percent))

  if (fillEl) fillEl.style.width = `${clamped}%`
  if (thumbEl) thumbEl.style.left = `${clamped}%`
}
