
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

    this.handleEvent('queue_saved', ({pos}) => {
      const element = document.querySelector('i.save-btn').parentElement
      const okIcon = document.createElement('i')
      okIcon.classList.add('fas')
      okIcon.classList.add('fa-check-circle')
      okIcon.classList.add('success-feedback')
      element.appendChild(okIcon)

      setTimeout(() => {
        okIcon.remove()
      }, 3000)
    })
  }
})

export default UiFeedback
