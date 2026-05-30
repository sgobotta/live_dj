export default {
  mounted() {
    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        this.el.blur()
      }
    })
  }
}
