import {pushScope} from '../keyboard'

// Only act while this input itself is focused - it's always mounted (not
// conditionally rendered like a modal), so without this a scope pushed at
// mount time would try to claim arrow/enter/escape keys anywhere on the
// page, not just while the user is actually typing a chat command.
function whenFocused(hook, fn) {
  return (event) => {
    if (document.activeElement !== hook.el) return false
    return fn(event)
  }
}

export default {
  commandOptions() {
    return Array.from(
      document.querySelectorAll('#chat-command-list [role="option"]')
    )
  },

  destroyed() {
    this.observer?.disconnect()
    this.detach?.()
  },

  mounted() {
    // The command palette is rendered by the server as a sibling of the
    // input. Since the input owns keyboard focus, we intercept navigation
    // keys here and drive the highlighted option in the DOM.
    this.commandIndex = -1

    this.detach = pushScope({
      bindings: {
        arrowdown: whenFocused(this, () => {
          const options = this.commandOptions()
          if (!options.length) return false
          this.moveHighlight(1, options)
        }),
        arrowup: whenFocused(this, () => {
          const options = this.commandOptions()
          if (!options.length) return false
          this.moveHighlight(-1, options)
        }),
        // Select the highlighted command instead of submitting the form.
        // Blur first so the input isn't focused when the server patches its
        // value (LiveView won't overwrite a focused input); the server then
        // refocuses it via the focus_chat_input event. This mirrors what a
        // real mouse click does, where focus leaves the input on mousedown.
        enter: whenFocused(this, () => {
          const options = this.commandOptions()
          if (!options.length || this.commandIndex < 0) return false
          this.el.blur()
          options[this.commandIndex].click()
        }),
        escape: whenFocused(this, () => this.el.blur())
      },
      id: 'chat-command-palette',
      ignoreInputs: false
    })

    // Whenever the server re-renders the palette (open, filter, close),
    // reset the highlight to the first option. Only childList changes are
    // observed so our own aria-selected updates don't retrigger this.
    const anchor = this.el.closest('#chat-input-bar')

    if (anchor) {
      this.observer = new MutationObserver(() => this.resetHighlight())
      this.observer.observe(anchor, { childList: true, subtree: true })
    }

    this.resetHighlight()
  },

  moveHighlight(delta, options) {
    const count = options.length
    this.commandIndex = (this.commandIndex + delta + count) % count
    this.renderHighlight(options)
  },

  renderHighlight(options) {
    options.forEach((option, index) => {
      if (index === this.commandIndex) {
        option.setAttribute('aria-selected', 'true')
        option.scrollIntoView({ block: 'nearest' })
      } else {
        option.removeAttribute('aria-selected')
      }
    })
  },

  resetHighlight() {
    const options = this.commandOptions()
    this.commandIndex = options.length ? 0 : -1
    this.renderHighlight(options)
  }
}
