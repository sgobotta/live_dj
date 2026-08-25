import {describe, expect, it, vi} from 'vitest'
import {adjustSlider, nextNodeId} from './keyboard-nav-hook'

describe('nextNodeId', () => {
  it('moves through the transport row', () => {
    expect(nextNodeId('previous', 'right', {})).toBe('playPause')
    expect(nextNodeId('playPause', 'left', {})).toBe('previous')
    expect(nextNodeId('playPause', 'right', {})).toBe('next')
    expect(nextNodeId('next', 'left', {})).toBe('playPause')
  })

  it('drops down to the seek bar from any transport button', () => {
    expect(nextNodeId('previous', 'down', {})).toBe('seek')
    expect(nextNodeId('playPause', 'down', {})).toBe('seek')
    expect(nextNodeId('next', 'down', {})).toBe('seek')
  })

  it('returns from the seek bar to the button that sent it there', () => {
    expect(nextNodeId('seek', 'up', {transport: 'previous'})).toBe('previous')
    expect(nextNodeId('seek', 'up', {transport: 'next'})).toBe('next')
  })

  it('moves right from next/seek into the add button', () => {
    expect(nextNodeId('next', 'right', {})).toBe('add')
    expect(nextNodeId('seek', 'right', {})).toBe('add')
  })

  it('returns from add to whichever of next/seek sent it there', () => {
    expect(nextNodeId('add', 'left', {beforeAdd: 'next'})).toBe('next')
    expect(nextNodeId('add', 'left', {beforeAdd: 'seek'})).toBe('seek')
  })

  it('moves through the action row', () => {
    expect(nextNodeId('add', 'right', {})).toBe('mute')
    expect(nextNodeId('mute', 'left', {})).toBe('add')
    expect(nextNodeId('mute', 'right', {})).toBe('volume')
    expect(nextNodeId('volume', 'left', {})).toBe('mute')
    expect(nextNodeId('volume', 'right', {})).toBe('fullscreen')
    expect(nextNodeId('fullscreen', 'left', {})).toBe('volume')
  })

  it('self-loops on the sliders where there is nowhere else to go', () => {
    // Claiming these (rather than declining) is what stops the native
    // range input from also adjusting its value on a plain arrow press.
    expect(nextNodeId('seek', 'left', {})).toBe('seek')
    expect(nextNodeId('seek', 'down', {})).toBe('seek')
    expect(nextNodeId('volume', 'up', {})).toBe('volume')
    expect(nextNodeId('volume', 'down', {})).toBe('volume')
  })

  it('declines directions that are genuinely unhandled', () => {
    expect(nextNodeId('previous', 'left', {})).toBe(null)
    expect(nextNodeId('fullscreen', 'right', {})).toBe(null)
  })
})

describe('adjustSlider', () => {
  function makeRangeInput({max = '100', min = '0', step = '5', value = '50'}) {
    const el = document.createElement('input')
    el.type = 'range'
    el.min = min
    el.max = max
    el.step = step
    el.value = value
    return el
  }

  it('steps the value by the element\'s own step', () => {
    const el = makeRangeInput({})
    adjustSlider(el, 'right')
    expect(el.value).toBe('55')

    adjustSlider(el, 'left')
    adjustSlider(el, 'left')
    expect(el.value).toBe('45')
  })

  it('falls back to a step of 1 when step is "any"', () => {
    const el = makeRangeInput({step: 'any', value: '10'})
    adjustSlider(el, 'right')
    expect(el.value).toBe('11')
  })

  it('clamps at min and max', () => {
    const atMax = makeRangeInput({value: '100'})
    adjustSlider(atMax, 'right')
    expect(atMax.value).toBe('100')

    const atMin = makeRangeInput({value: '0'})
    adjustSlider(atMin, 'left')
    expect(atMin.value).toBe('0')
  })

  it('dispatches bubbling input and change events', () => {
    const el = makeRangeInput({})
    document.body.appendChild(el)
    const onInput = vi.fn()
    const onChange = vi.fn()
    document.addEventListener('input', onInput)
    document.addEventListener('change', onChange)

    adjustSlider(el, 'right')

    expect(onInput).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledTimes(1)
    document.removeEventListener('input', onInput)
    document.removeEventListener('change', onChange)
  })
})
