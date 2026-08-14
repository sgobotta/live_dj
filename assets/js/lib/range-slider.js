function getValuePercent(inputEl) {
  const min = parseFloat(inputEl.min) || 0
  const max = parseFloat(inputEl.max) || 100
  const value = parseFloat(inputEl.value) || 0
  const range = max - min
  const percent = range > 0 ? ((value - min) / range) * 100 : 0
  return Math.min(100, Math.max(0, percent))
}

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

  const percent = getValuePercent(inputEl)
  if (fillEl) fillEl.style.width = `${percent}%`
  if (thumbEl) thumbEl.style.left = `${percent}%`
}

// Wires up a translucent preview segment spanning from the current value to
// wherever the pointer is hovering, when hovering ahead of (to the right of)
// the current value — mirrors the common "scrub preview" affordance. No-op
// when hovering at or behind the current value.
export function attachRangeSliderHoverPreview(inputEl) {
  const wrapper = inputEl.closest('.custom-slider')
  if (!wrapper) return

  const hoverFillEl = wrapper.querySelector('.custom-slider-hover-fill')
  if (!hoverFillEl) return

  const onMove = (e) => {
    const rect = wrapper.getBoundingClientRect()
    if (rect.width === 0) return

    const hoverPercent = Math.min(
      100,
      Math.max(0, ((e.clientX - rect.left) / rect.width) * 100)
    )
    const valuePercent = getValuePercent(inputEl)

    if (hoverPercent > valuePercent) {
      hoverFillEl.style.left = `${valuePercent}%`
      hoverFillEl.style.width = `${hoverPercent - valuePercent}%`
    } else {
      hoverFillEl.style.width = '0%'
    }
  }

  const onLeave = () => {
    hoverFillEl.style.width = '0%'
  }

  wrapper.addEventListener('mousemove', onMove)
  wrapper.addEventListener('mouseleave', onLeave)
}
