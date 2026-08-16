// Flashes a room card in the "More rooms" grid when its data-rank attribute
// changes between patches - i.e. when a presence join/leave elsewhere caused
// the server to re-sort the grid and this card moved. Comparing data-rank
// (rather than reacting to every updated() call) filters out unrelated
// re-renders of the card's contents, e.g. its now-playing text changing
// without its position changing.
//
// The flash class is removed and forced to reflow before re-adding it so the
// CSS animation restarts even if the same card moves again before its
// previous flash finished playing.
export default {
  mounted() {
    this.rank = this.el.dataset.rank
  },

  updated() {
    const rank = this.el.dataset.rank

    if (rank !== this.rank) {
      this.flash()
    }

    this.rank = rank
  },

  flash() {
    this.el.classList.remove('room-rank-flash')
    void this.el.offsetWidth
    this.el.classList.add('room-rank-flash')
  }
}
