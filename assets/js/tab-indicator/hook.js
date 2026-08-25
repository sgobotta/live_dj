// Slides the shared underline indicator (the last child of this element) to
// sit under whichever sibling tab link has data-active="true". Positioned via
// offsetLeft/offsetWidth against this element as the nearest positioned
// ancestor, so it lines up correctly even though the tabs aren't equal width.
//
// The enclosing modal's own reveal (a separate phx-mounted JS.show command)
// isn't guaranteed to run before this hook's mounted(), so the container can
// still measure as zero-size at that exact instant. A ResizeObserver on the
// container self-corrects whenever its real layout settles, rather than
// gambling on a fixed delay - it also keeps the indicator aligned across
// window resizes and font loading. updated() covers the other case: the
// active tab changing on a LiveView patch without the container itself
// resizing, which is where the indicator's own transition classes animate
// the slide.
import {createGrid, pushScope} from '../keyboard'

export default {
  destroyed() {
    this.observer?.disconnect()
    this.detach?.()
  },

  mounted() {
    this.observer = new ResizeObserver(() => this.position())
    this.observer.observe(this.el)
    this.position()

    // Left/right move real focus between tabs, matching how the ARIA
    // tablist pattern expects arrow-key navigation to work. This element
    // only exists while the settings modal is open (see session_modals.ex),
    // so pushing/popping here already matches the modal's own lifecycle.
    const grid = createGrid({
      container: this.el,
      edgeBehavior: 'clamp',
      rows: () => [Array.from(this.el.querySelectorAll('a[data-active]'))]
    })
    this.detach = pushScope({grid, id: 'settings-modal-tabs'})
  },

  position() {
    const active = this.el.querySelector('[data-active="true"]')
    const indicator = this.el.lastElementChild
    if (!active || !indicator) return

    indicator.style.left = `${active.offsetLeft}px`
    indicator.style.width = `${active.offsetWidth}px`
  },

  updated() {
    this.position()
  }
}
