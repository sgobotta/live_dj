import {beforeEach, describe, expect, it, vi} from 'vitest'
import {_resetForTests, popScope, pushScope} from './registry'

function dispatchKeydown(target, options) {
  const event = new KeyboardEvent('keydown', {bubbles: true, ...options})
  target.dispatchEvent(event)
}

describe('keyboard registry', () => {
  beforeEach(() => {
    _resetForTests()
    document.body.innerHTML = ''
  })

  it('lets the topmost scope win when both bind the same key', () => {
    const lower = vi.fn()
    const upper = vi.fn()

    pushScope({bindings: {a: lower}, id: 'lower'})
    pushScope({bindings: {a: upper}, id: 'upper'})

    dispatchKeydown(window, {key: 'a'})

    expect(lower).not.toHaveBeenCalled()
    expect(upper).toHaveBeenCalledTimes(1)
  })

  it('falls through to a lower scope for an unclaimed key', () => {
    const lower = vi.fn()
    const upper = vi.fn()

    pushScope({bindings: {m: lower}, id: 'lower'})
    pushScope({bindings: {a: upper}, id: 'upper'})

    dispatchKeydown(window, {key: 'm'})

    expect(lower).toHaveBeenCalledTimes(1)
    expect(upper).not.toHaveBeenCalled()
  })

  it('falls through past a grid scope that declines an arrow key', () => {
    const move = vi.fn(() => false)
    const lowerArrow = vi.fn()

    pushScope({bindings: {arrowdown: lowerArrow}, id: 'lower'})
    pushScope({grid: {move}, id: 'upper-nav'})

    dispatchKeydown(window, {key: 'ArrowDown'})

    expect(move).toHaveBeenCalledWith('arrowdown')
    expect(lowerArrow).toHaveBeenCalledTimes(1)
  })

  it('restores the scope below once the top one detaches', () => {
    const lower = vi.fn()
    const upper = vi.fn()

    pushScope({bindings: {a: lower}, id: 'lower'})
    const detach = pushScope({bindings: {a: upper}, id: 'upper'})

    detach()
    dispatchKeydown(window, {key: 'a'})

    expect(lower).toHaveBeenCalledTimes(1)
    expect(upper).not.toHaveBeenCalled()
  })

  it('popScope removes the most recently pushed scope with a given id', () => {
    const handler = vi.fn()

    pushScope({bindings: {a: handler}, id: 'modal'})
    popScope('modal')
    dispatchKeydown(window, {key: 'a'})

    expect(handler).not.toHaveBeenCalled()
  })

  it('ignores bindings while an editable element is focused by default', () => {
    const handler = vi.fn()
    const input = document.createElement('input')
    document.body.appendChild(input)

    pushScope({bindings: {a: handler}, id: 'global'})
    dispatchKeydown(input, {key: 'a'})

    expect(handler).not.toHaveBeenCalled()
  })

  it('lets a scope opt out of the editable-element guard', () => {
    const handler = vi.fn()
    const input = document.createElement('input')
    document.body.appendChild(input)

    pushScope({bindings: {a: handler}, id: 'palette', ignoreInputs: false})
    dispatchKeydown(input, {key: 'a'})

    expect(handler).toHaveBeenCalledTimes(1)
  })

  it('ignores bindings when a modifier key is held by default', () => {
    const handler = vi.fn()

    pushScope({bindings: {a: handler}, id: 'global'})
    dispatchKeydown(window, {ctrlKey: true, key: 'a'})

    expect(handler).not.toHaveBeenCalled()
  })

  it('falls through when a handler declines by returning false', () => {
    const upper = vi.fn(() => false)
    const lower = vi.fn()

    pushScope({bindings: {escape: lower}, id: 'lower'})
    pushScope({bindings: {escape: upper}, id: 'upper'})

    dispatchKeydown(window, {key: 'Escape'})

    expect(upper).toHaveBeenCalledTimes(1)
    expect(lower).toHaveBeenCalledTimes(1)
  })

  it('delegates arrow keys to the scope grid before bindings', () => {
    const move = vi.fn(() => true)
    const arrowBinding = vi.fn()

    pushScope({
      bindings: {arrowdown: arrowBinding},
      grid: {move},
      id: 'nav'
    })
    dispatchKeydown(window, {key: 'ArrowDown'})

    expect(move).toHaveBeenCalledWith('arrowdown')
    expect(arrowBinding).not.toHaveBeenCalled()
  })
})
