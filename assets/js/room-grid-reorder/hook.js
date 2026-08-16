// Animates a room card in the "More rooms" grid whenever a presence
// join/leave elsewhere causes the server to re-sort the grid and this card's
// position changes.
//
// Phoenix's DOM patcher moves the card's element to its new spot in the
// sibling list, but a CSS grid recomputes layout instantly - without this,
// the card would just teleport. beforeUpdate() records the card's on-screen
// position right before the patch; updated() compares it against the new
// position and plays a FLIP animation (https://aerotwist.com/blog/flip/)
// that slides it from where it was to where it now is, using the Web
// Animations API so overlapping/rapid moves each just get their own
// independent animation instance.
//
// data-rank additionally identifies the one card whose *own* presence count
// changed (as opposed to a card that only shifted because a sibling moved
// past it), which gets a brief highlight flash on top of the slide.
export default {
  mounted() {
    this.rank = this.el.dataset.rank
  },

  beforeUpdate() {
    this.rect = this.el.getBoundingClientRect()
  },

  updated() {
    this.slide()

    const rank = this.el.dataset.rank
    if (rank !== this.rank) {
      this.flash()
    }
    this.rank = rank
  },

  slide() {
    if (!this.rect) return

    const from = this.rect
    const to = this.el.getBoundingClientRect()
    const dx = from.left - to.left
    const dy = from.top - to.top

    if (dx === 0 && dy === 0) return

    this.el.animate(
      [{ transform: `translate(${dx}px, ${dy}px)` }, { transform: 'none' }],
      { duration: 350, easing: 'ease-out' }
    )
  },

  flash() {
    this.el.classList.remove('room-rank-flash')
    void this.el.offsetWidth
    this.el.classList.add('room-rank-flash')
  }
}
