// Arrow-key navigation for the playlist. The list itself is the only Tab
// stop (see the tabindex="0" on #lists); every track link inside sits at
// tabindex="-1" so Tab skips straight over them. ArrowDown/ArrowUp move
// real DOM focus from track to track instead, letting Enter (native link
// activation) play whichever one is focused. Each move scrolls the newly
// focused track to the vertical center of the list when there's enough
// room; scrollIntoView clamps at the list's own start/end instead of
// forcing centering there, so top/bottom tracks just land as centered
// as the available scroll room allows.
//
// Playing a track (Enter, or a click) flips it to "current", which swaps
// its markup from the play-button branch to the now-playing branch in
// list_component.ex — a different element ends up carrying tabindex/
// data-nav-item, so the node that had focus is removed from the DOM and
// the browser drops focus to <body>. Track which track (by data-id) last
// had focus and, if an update leaves focus stranded on <body>, reclaim it
// on that track's new nav target so arrow-key navigation can continue.
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
  mounted() {
    this.focusedId = null

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
        return
      }

      if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return

      const items = Array.from(this.el.querySelectorAll('[data-nav-item]'))
      if (items.length === 0) return

      e.preventDefault()

      const currentIndex = items.indexOf(document.activeElement)
      const delta = e.key === 'ArrowDown' ? 1 : -1
      const nextIndex = currentIndex === -1
        ? (e.key === 'ArrowDown' ? 0 : items.length - 1)
        : Math.max(0, Math.min(items.length - 1, currentIndex + delta))

      items[nextIndex].focus()
      items[nextIndex].scrollIntoView({block: 'center'})
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
    if (document.activeElement !== document.body) return
    this.refocusLastItem()
  }
}
