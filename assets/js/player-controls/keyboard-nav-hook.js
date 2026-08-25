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
// elements, which already respond to arrow keys by adjusting their
// value. Only the specific directions listed per node are intercepted
// here for navigation; every other direction is left alone, so e.g.
// ArrowLeft still adjusts the seek position and ArrowUp/ArrowDown still
// adjust the volume.
const NODES = {
  add: {left: (state) => state.beforeAdd, right: 'mute'},
  fullscreen: {left: 'volume'},
  mute: {left: 'add', right: 'volume'},
  next: {down: 'seek', left: 'playPause', right: 'add'},
  playPause: {down: 'seek', left: 'previous', right: 'next'},
  previous: {down: 'seek', right: 'playPause'},
  seek: {right: 'add', up: (state) => state.transport},
  volume: {left: 'mute', right: 'fullscreen'}
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

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    const state = {beforeAdd: 'next', transport: 'playPause'}

    const move = (direction) => {
      if (!this.el.contains(document.activeElement)) return false

      const id = NODE_BY_ELEMENT_ID[document.activeElement.id]
      const nextId = id && nextNodeId(id, direction, state)
      if (!nextId) return false

      const nextEl = document.getElementById(IDS[nextId])
      if (!nextEl) return false

      if (TRANSPORT_NODES.has(id)) state.transport = id
      if (BEFORE_ADD_NODES.has(id)) state.beforeAdd = id

      nextEl.focus()
    }

    this.detach = pushScope({
      bindings: {
        arrowdown: () => move('down'),
        arrowleft: () => move('left'),
        arrowright: () => move('right'),
        arrowup: () => move('up')
      },
      id: 'player-controls'
    })
  }
}
