export default {
  commandOptions() {
    return Array.from(
      document.querySelectorAll('#chat-command-list [role="option"]')
    )
  },

  destroyed() {
    this.observer?.disconnect()
  },

  mounted() {
    // The command palette is rendered by the server as a sibling of the
    // input. Since the input owns keyboard focus, we intercept navigation
    // keys here and drive the highlighted option in the DOM.
    this.commandIndex = -1

    this.el.addEventListener('keydown', (e) => {
      const options = this.commandOptions()

      if (options.length) {
        if (e.key === 'ArrowDown') {
          e.preventDefault()
          this.moveHighlight(1, options)
          return
        }

        if (e.key === 'ArrowUp') {
          e.preventDefault()
          this.moveHighlight(-1, options)
          return
        }

        if (e.key === 'Enter' && this.commandIndex >= 0) {
          // Select the highlighted command instead of submitting the form.
          // Blur first so the input isn't focused when the server patches its
          // value (LiveView won't overwrite a focused input); the server then
          // refocuses it via the focus_chat_input event. This mirrors what a
          // real mouse click does, where focus leaves the input on mousedown.
          e.preventDefault()
          this.el.blur()
          options[this.commandIndex].click()
          return
        }
      }

      if (e.key === 'Escape') {
        e.preventDefault()
        this.el.blur()
      }
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
