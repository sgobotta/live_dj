function getValuePercent(inputEl) {
  const min = parseFloat(inputEl.min) || 0
  const max = parseFloat(inputEl.max) || 100
  const value = parseFloat(inputEl.value) || 0
  const range = max - min
  const percent = range > 0 ? ((value - min) / range) * 100 : 0
  return Math.min(100, Math.max(0, percent))
}

// Positions the translucent preview segment from the (possibly just-updated)
// current value out to the last known pointer position, only when hovering
// ahead of the current value — mirrors the common "scrub preview"
// affordance. Re-deriving this from the stored pointer position (rather
// than only on mousemove) matters because a click/commit changes the value
// without necessarily firing a fresh mousemove, which would otherwise leave
// a stale preview segment computed against the old value, visibly
// overlapping and muting part of the newly-extended fill.
function syncHoverPreview(wrapper, inputEl, percent) {
  const hoverFillEl = wrapper.querySelector('.custom-slider-hover-fill')
  if (!hoverFillEl) return

  if (wrapper._hoverClientX === undefined) {
    hoverFillEl.style.width = '0%'
    return
  }

  const rect = wrapper.getBoundingClientRect()
  if (rect.width === 0) return

  const hoverPercent = Math.min(
    100,
    Math.max(0, ((wrapper._hoverClientX - rect.left) / rect.width) * 100)
  )

  if (hoverPercent > percent) {
    hoverFillEl.style.left = `${percent}%`
    hoverFillEl.style.width = `${hoverPercent - percent}%`
  } else {
    hoverFillEl.style.width = '0%'
  }
}

// Syncs a custom-rendered fill/thumb pair (and hover preview, see
// syncHoverPreview above) to a native <input type="range">'s current value.
// The input stays functional (drag, click-to-seek, keyboard, touch, a11y)
// but is rendered fully transparent — see .custom-slider in
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

  syncHoverPreview(wrapper, inputEl, percent)
}

// Wires up the hover-preview segment described above.
export function attachRangeSliderHoverPreview(inputEl) {
  const wrapper = inputEl.closest('.custom-slider')
  if (!wrapper) return
  if (!wrapper.querySelector('.custom-slider-hover-fill')) return

  const onMove = (e) => {
    wrapper._hoverClientX = e.clientX
    syncRangeSliderVisual(inputEl)
  }
  const onLeave = () => {
    wrapper._hoverClientX = undefined
    syncRangeSliderVisual(inputEl)
  }

  wrapper.addEventListener('mousemove', onMove)
  wrapper.addEventListener('mouseleave', onLeave)
}
