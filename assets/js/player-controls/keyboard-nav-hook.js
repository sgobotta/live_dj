import {pushScope} from '../keyboard'

// Arrow-key navigation across the transport buttons, seek bar, add
// button, volume controls, and fullscreen button.
//
// This is an explicit neighbor graph rather than a grid: the seek bar's
// "up" and the add button's "left" each need to return to whichever of
// several possible neighbors last sent focus their way, rather than a
// fixed row/column relationship a grid could express. `state` below
// tracks just enough of that history to resolve those two cases.
//
// The seek bar and volume slider are native <input type="range">
// elements, which would otherwise respond to arrow keys by adjusting
// their value instead of moving focus - fighting this scope's own
// left/right/up/down navigation. Every direction on those two nodes is
// therefore claimed, self-looping (focusing the element it's already
// on) where there's nowhere else to go, which is enough for the
// registry to preventDefault the native behavior without this scope
// actually needing to move anywhere. Shift+Left/Shift+Right adjusts
// the value directly instead - see adjustSlider() below.
const NODES = {
  add: {left: (state) => state.beforeAdd, right: 'mute'},
  fullscreen: {left: 'volume'},
  mute: {left: 'add', right: 'volume'},
  next: {down: 'seek', left: 'playPause', right: 'add'},
  playPause: {down: 'seek', left: 'previous', right: 'next'},
  previous: {down: 'seek', right: 'playPause'},
  seek: {
    down: 'seek',
    left: 'seek',
    right: 'add',
    up: (state) => state.transport
  },
  volume: {down: 'volume', left: 'mute', right: 'fullscreen', up: 'volume'}
}

const IDS = {
  add: 'add-btn',
  fullscreen: 'fullscreen-btn',
  mute: 'volume-mute-btn',
  next: 'next-track-btn',
  playPause: 'play-pause-btn',
  previous: 'previous-track-btn',
  seek: 'player-controls-time-slider',
  volume: 'volume-slider'
}

const NODE_BY_ELEMENT_ID = Object.fromEntries(
  Object.entries(IDS).map(([nodeId, elementId]) => [elementId, nodeId])
)

const TRANSPORT_NODES = new Set(['next', 'playPause', 'previous'])
const BEFORE_ADD_NODES = new Set(['next', 'seek'])

// Pure enough to unit test without a DOM: given the id of the currently
// focused node, resolve which node a direction leads to (or null if this
// graph doesn't handle that direction from there).
export function nextNodeId(id, direction, state) {
  const target = NODES[id]?.[direction]
  if (!target) return null
  return typeof target === 'function' ? target(state) : target
}

function isRangeInput(el) {
  return el?.tagName === 'INPUT' && el.type === 'range'
}

// Replicates what the native arrow-key step on a range input would have
// done, now that those keys are claimed for navigation instead - reads
// step/min/max off the element itself and dispatches real input/change
// events (rather than relying on the browser), so existing listeners
// (the RangeSlider hook's visual sync, the volume form's phx-change, the
// seek bar's document-level input/change listeners in youtube/hook.js)
// all see it exactly as they would a genuine drag or native keypress.
export function adjustSlider(el, direction) {
  const min = Number(el.min) || 0
  const max = Number(el.max) || 100
  const step = Number(el.step)
  const amount = Number.isFinite(step) && step > 0 ? step : 1
  const value = Number(el.value) || 0
  const delta = direction === 'right' ? amount : -amount

  el.value = String(Math.min(max, Math.max(min, value + delta)))
  el.dispatchEvent(new Event('input', {bubbles: true}))
  el.dispatchEvent(new Event('change', {bubbles: true}))
}

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    const state = {beforeAdd: 'next', transport: 'playPause'}

    const move = (direction, event) => {
      const active = document.activeElement
      if (!this.el.contains(active)) return false

      const id = NODE_BY_ELEMENT_ID[active.id]
      if (!id) return false

      const isSlide = direction === 'left' || direction === 'right'
      if (event.shiftKey && isSlide && isRangeInput(active)) {
        adjustSlider(active, direction)
        return true
      }

      const nextId = nextNodeId(id, direction, state)
      if (!nextId) return false

      const nextEl = document.getElementById(IDS[nextId])
      if (!nextEl) return false

      if (TRANSPORT_NODES.has(id)) state.transport = id
      if (BEFORE_ADD_NODES.has(id)) state.beforeAdd = id

      nextEl.focus()
    }

    this.detach = pushScope({
      bindings: {
        arrowdown: (event) => move('down', event),
        arrowleft: (event) => move('left', event),
        arrowright: (event) => move('right', event),
        arrowup: (event) => move('up', event)
      },
      id: 'player-controls'
    })
  }
}
