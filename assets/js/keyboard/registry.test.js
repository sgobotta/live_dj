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

  it('dispatches to the bindings of the topmost scope only', () => {
    const lower = vi.fn()
    const upper = vi.fn()

    pushScope({bindings: {a: lower}, id: 'lower'})
    pushScope({bindings: {a: upper}, id: 'upper'})

    dispatchKeydown(window, {key: 'a'})

    expect(lower).not.toHaveBeenCalled()
    expect(upper).toHaveBeenCalledTimes(1)
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
