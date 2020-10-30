
const UiFeedback = () => ({
  mounted() {

    function applyAnimationClass(querySelector, className) {
      const element = document.querySelector(querySelector)
      element.classList.add(className)
      setTimeout(() => {
        element.classList.remove(className)
      }, 2000)
    }

    this.handleEvent('video_sorted_to_queue', ({pos}) => {
      applyAnimationClass(`[data-position="${pos}"] > div > div.pill`, 'sorts-track')
    })

    this.handleEvent('video_added_to_queue', ({pos}) => {
      applyAnimationClass(`[data-position="${pos}"] > div > div.pill`, 'adds-track')
    })
  }
})

export default UiFeedback
