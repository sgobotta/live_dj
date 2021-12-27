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
      applyAnimationClass(`[data-position="${pos}"] > div.pill`, 'sorts-track')
    })

    this.handleEvent('video_added_to_queue', ({pos}) => {
      applyAnimationClass(`[data-position="${pos}"] > div.pill`, 'adds-track')
    })

    this.handleEvent('queue_saved', () => {
      const saveButton = document.querySelector('svg.queue-control-disabled')
      saveButton.classList.add('animate-save-button-saved')

      setTimeout(() => {
        saveButton.classList.remove('animate-save-button-saved')
      }, 3000)
    })
  }
})

export default UiFeedback
