const DragAndDropping = () => ({
  async mounted() {

    function updateGhostsStyles(position, className) {
      Array.from(Array(2).keys()).forEach(index => {
        const p = position - index
        const ghostLi = document.querySelector(`[data-ghost-slot="${p}"`)
        ghostLi.classList.add(className)
      })
    }

    this.el.addEventListener('dragstart', e => {
      const { dataset: { position } } = e.target
      
      updateGhostsStyles(position, 'hide')

      e.dataTransfer.dropEffect = 'move'
      e.dataTransfer.setData('text/plain', `${position}`)
      setTimeout(() => {
        e.target.classList.add('dragged')
      }, 30)
    })

    this.el.addEventListener('dragenter', e => {      
      e.dataTransfer.dropEffect = 'move'
      const { tagName } = e.target
      if (tagName === 'SPAN' && e.target.classList.contains('over-zone')) {
        const { dataset: { overSlot: position } } = e.target
        const ghostLi = document.getElementById(`drag-data-ghost-${position}`)
        setTimeout(() => {
          e.target.classList.add('expand')
          ghostLi.classList.remove('over-zone')
          ghostLi.classList.add('ghost-slot')
          ghostLi.classList.add('dragged-over')
        }, 30)
      }
    })

    this.el.addEventListener('dragleave', e => {
      const { tagName } = e.target
      if (tagName === 'SPAN' && e.target.classList.contains('over-zone')){
        e.target.classList.remove('expand')
        const { dataset: { overSlot: position } } = e.target
        const ghostLi = document.getElementById(`drag-data-ghost-${position}`)
        setTimeout(() => {
          ghostLi.classList.add('over-zone')
          ghostLi.classList.remove('ghost-slot')
          ghostLi.classList.remove('dragged-over')
        }, 30)
      }
    })

    this.el.addEventListener('dragover', e => {
      if (e.preventDefault) {
         // Necessary. Allows dropping.
        e.preventDefault()
      }
      e.dataTransfer.dropEffect = 'move'
      return false
    })

    this.el.addEventListener('drop', e => {
      e.preventDefault() // stops the browser from redirecting.
      if (e.stopPropagation) {
        e.stopPropagation() // stops the browser from redirecting.
      }
      e.dataTransfer.dropEffect = 'move'
      const { tagName } = e.target
      if (tagName === "SPAN" && e.target.classList.contains('over-zone')) {
        const from = parseInt(e.dataTransfer.getData('text/plain'))
        const { dataset: { position: _to }} = this.el
        const to = parseInt(_to)

        const { dataset: { overSlot: position } } = e.target
        const ghostLi = document.getElementById(`drag-data-ghost-${position}`)
        setTimeout(() => {
          ghostLi.classList.add('over-zone')
          ghostLi.classList.remove('ghost-slot')
          ghostLi.classList.remove('dragged-over')
        }, 30)

        const dropsOnItself = (from === to)
        const dropsFirstElement = (from === 1) && (to === 0)
        if (dropsOnItself || dropsFirstElement) return

        this.pushEvent(
          'player_signal_sort_video',
          { from: from - 1, to: from < to ? to-1 : to }
        )
      }
    })

    this.el.addEventListener('dragend', e => {
      const { dataset: { position } } = e.target

      updateGhostsStyles(position, 'show')

      setTimeout(() => {
        e.target.classList.remove('dragged')
      }, 30)
    })
  }
})

export default DragAndDropping
