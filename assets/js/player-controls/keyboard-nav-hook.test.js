import {describe, expect, it} from 'vitest'
import {nextNodeId} from './keyboard-nav-hook'

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

  it('declines unhandled directions, leaving native slider behavior', () => {
    expect(nextNodeId('seek', 'left', {})).toBe(null)
    expect(nextNodeId('seek', 'down', {})).toBe(null)
    expect(nextNodeId('volume', 'up', {})).toBe(null)
    expect(nextNodeId('volume', 'down', {})).toBe(null)
    expect(nextNodeId('previous', 'left', {})).toBe(null)
    expect(nextNodeId('fullscreen', 'right', {})).toBe(null)
  })
})
