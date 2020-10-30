
const UiFeedback = () => ({
  mounted() {

    this.handleEvent('single-video-effect', ({pos}) => {
      const element = document.querySelector(`[data-position="${pos}"] > div > div.pill`)
      element.classList.add('fade-in')
      setTimeout(() => {
        element.classList.remove('fade-in')
      }, 2000)
    })
  }
})

export default UiFeedback
