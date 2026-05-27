import { PALETTES, startNoise, stopNoise } from '../animation/noise'

const STORAGE_KEY = '_noise_filter'

function getPaletteIndex() {
  const idx = parseInt(localStorage.getItem(STORAGE_KEY) ?? '0', 10)
  return (idx >= 0 && idx < PALETTES.length) ? idx : 0
}

export default {
  _attachSwipe() {
    this._touchStartX = 0
    this._touchStartY = 0
    this._mouseStartX = 0

    this._onTouchStart = e => {
      this._touchStartX = e.touches[0].clientX
      this._touchStartY = e.touches[0].clientY
    }

    this._onTouchEnd = e => {
      const dx = e.changedTouches[0].clientX - this._touchStartX
      const dy = e.changedTouches[0].clientY - this._touchStartY
      if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 40) {
        this._slide(dx < 0 ? 1 : -1)
      }
    }

    this._onMouseDown = e => { this._mouseStartX = e.clientX }
    this._onMouseUp = e => {
      const dx = e.clientX - this._mouseStartX
      if (Math.abs(dx) > 50) this._slide(dx < 0 ? 1 : -1)
    }

    const opts = { passive: true }
    this.el.addEventListener('touchstart', this._onTouchStart, opts)
    this.el.addEventListener('touchend', this._onTouchEnd, opts)
    this.el.addEventListener('mousedown', this._onMouseDown)
    this.el.addEventListener('mouseup', this._onMouseUp)
  },

  _buildDots() {
    const wrap = document.createElement('div')
    wrap.style.cssText = [
      'position:absolute',
      'bottom:10px',
      'left:50%',
      'transform:translateX(-50%)',
      'display:flex',
      'gap:6px',
      'z-index:10',
      'pointer-events:none'
    ].join(';')
    this._dots = PALETTES.map(() => {
      const dot = document.createElement('span')
      dot.style.cssText = [
        'display:block',
        'width:6px',
        'height:6px',
        'border-radius:50%',
        'transition:background 0.25s'
      ].join(';')
      wrap.appendChild(dot)
      return dot
    })
    this.el.appendChild(wrap)
  },

  _detachSwipe() {
    this.el.removeEventListener('touchstart', this._onTouchStart)
    this.el.removeEventListener('touchend', this._onTouchEnd)
    this.el.removeEventListener('mousedown', this._onMouseDown)
    this.el.removeEventListener('mouseup', this._onMouseUp)
  },

  _slide(dir) {
    const len = PALETTES.length
    this.paletteIndex = (this.paletteIndex + dir + len) % len
    localStorage.setItem(STORAGE_KEY, String(this.paletteIndex))
    this._updateDots()

    const canvas = document.getElementById('player-spinner')
    if (canvas && !canvas.classList.contains('hidden')) {
      stopNoise(canvas)
      startNoise(canvas, PALETTES[this.paletteIndex])
    }
  },

  _updateDots() {
    this._dots.forEach((dot, i) => {
      dot.style.background = i === this.paletteIndex
        ? 'rgba(255,255,255,0.85)'
        : 'rgba(255,255,255,0.25)'
    })
  },

  destroyed() {
    this._detachSwipe()
  },

  mounted() {
    this.paletteIndex = getPaletteIndex()
    this._buildDots()
    this._updateDots()
    this._attachSwipe()
  }
}
