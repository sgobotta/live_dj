const SearchSyncing = () => ({
  mounted() {
    const form = document.getElementById('search-video-form')
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      this.el.classList.add('anim-fade-in')
      this.el.children[0].classList.remove('loader-container')
      this.el.children[0].classList.add('animate-loader-container')
      setTimeout(() => {
        this.el.classList.add('hidden-elements')
      }, 200)
    })

    this.handleEvent('receive_search_completed_signal', () => {
      this.el.classList.remove('hidden-elements')
      this.el.classList.remove('anim-fade-in')
      this.el.classList.add('anim-fade-out')
      this.el.scrollTop = 0
      this.el.children[0].classList.add('loader-container')
      this.el.children[0].classList.remove('animate-loader-container')
    })
  }
})

export default SearchSyncing
