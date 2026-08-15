// Arrow-key navigation for the playlist. The list itself is the only Tab
// stop (see the tabindex="0" on #lists); every track link inside sits at
// tabindex="-1" so Tab skips straight over them. ArrowDown/ArrowUp move
// real DOM focus from track to track instead, letting Enter (native link
// activation) play whichever one is focused.
export default {
  mounted() {
    this.el.addEventListener('keydown', (e) => {
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
      items[nextIndex].scrollIntoView({block: 'nearest'})
    })
  }
}
