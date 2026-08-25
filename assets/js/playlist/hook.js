import {createListScope, pushScope} from '../keyboard'

// Arrow-key navigation for the playlist, via the keyboard registry's list
// scope (see assets/js/keyboard). The list itself is the only Tab stop
// (see the tabindex="0" on #lists); every track link inside sits at
// tabindex="-1" so Tab skips straight over them. ArrowDown/ArrowUp move
// real DOM focus from track to track instead, letting Enter (native link
// activation) play whichever one is focused.
//
// Playing a track (Enter, or a click) flips it to "current", which swaps
// its markup from the play-button branch to the now-playing branch in
// list_component.ex — a different element ends up carrying tabindex/
// data-nav-item, so the node that had focus is removed from the DOM and
// the browser drops focus to <body>. Track which track (by data-id) last
// had focus and, if an update leaves focus stranded on <body>, reclaim it
// on that track's new nav target so arrow-key navigation can continue.
// (This stays bespoke rather than using the grid's own reconcileFocus():
// the identity attribute here is data-id, which lives on the row wrapper
// and not always on the actual [data-nav-item] target - see the branches
// below.)
//
// #lists itself is also the Tab stop that wraps the whole list, so
// Tab-ing away and back (or Shift+Tab-ing in) lands browser focus on the
// container rather than on any track. Redirect that back to whichever
// track was last focused, so leaving and returning to the playlist picks
// up where the user left off instead of resetting to the top. The very
// first Tab into the list has no "last focused" track yet — default to
// the currently playing one there, so that first visit behaves like any
// later one instead of leaving focus on the bare, unstyled container.
//
// That same container is also the nearest tabindex="0" ancestor of every
// track (tabindex="-1"), so Shift+Tab *out* of a focused track would
// normally pass through #lists too, as the natural previous stop in
// sequential focus order — landing on the bare container instead of
// whatever precedes the playlist is pointless, since the container isn't
// itself a thing worth focusing. Skip it outright: briefly drop #lists
// out of the tab order on Shift+Tab so the browser's own handling lands
// focus on the real previous element. (The relatedTarget guard on
// focusin below stays as a fallback for the same case, in browsers/paths
// where that trick doesn't apply.)
export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    this.focusedId = null

    const grid = createListScope({
      container: this.el,
      edgeBehavior: 'clamp',
      items: () => Array.from(this.el.querySelectorAll('[data-nav-item]'))
    })
    this.detach = pushScope({grid, id: this.el.id})

    this.el.addEventListener('focusin', (e) => {
      if (e.target === this.el) {
        if (!e.relatedTarget || !this.el.contains(e.relatedTarget)) {
          this.refocusLastItem()
        }
        return
      }

      const item = e.target.closest('[data-id]')
      if (item) this.focusedId = item.dataset.id
    })

    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'Tab' && e.shiftKey && document.activeElement !== this.el) {
        this.el.setAttribute('tabindex', '-1')
        setTimeout(() => this.el.setAttribute('tabindex', '0'), 0)
      }
    })
  },

  refocusLastItem() {
    const item = this.focusedId === null
      ? this.el.querySelector('[role="option"][data-nav-item]')
      : this.el.querySelector(`[data-id="${CSS.escape(this.focusedId)}"]`)

    const target = item?.matches('[data-nav-item]')
      ? item
      : item?.querySelector('[data-nav-item]')

    target?.focus()
    target?.scrollIntoView({block: 'center'})
  },

  updated() {
    if (this.focusedId === null) return
    if (document.activeElement !== document.body) return
    this.refocusLastItem()
  }
}
