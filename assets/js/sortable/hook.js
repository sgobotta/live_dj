import Sortable from '../../vendor/sortable'

export default {
  mounted() {
    const noDropCursor = 'cursor-no-drop'
    const grabCursor = 'cursor-grab'
    const grabbingCursor = 'cursor-grabbing'

    const cancelledPointerHover = `hover:${noDropCursor}`
    const grabbablePointerHover = `hover:${grabCursor}`
    const grabbingPointerHover = `hover:${grabbingCursor}`

    const sorter = new Sortable(this.el, {
      animation: 400,
      delay: 300,
      dragClass: "drag-item",
      forceFallback: true,
      ghostClass: "drag-ghost",
      onEnd: ({item: item, newIndex: newIndex, oldIndex: oldIndex}) => {
        sorter.el.classList.remove(cancelledPointerHover)
        sorter.el.classList.remove(grabbingPointerHover)
        Array.from(sorter.el.children).forEach(c => {
          c.classList.add(grabbablePointerHover)
          c.classList.remove(cancelledPointerHover)
        })

        const {dataRelatedInsertedAfter, dataRelatedId} = this
        let params

        if ([
          (newIndex !== oldIndex),
          (dataRelatedInsertedAfter !== undefined),
          (dataRelatedId !== undefined)
        ].every(c => c === true)) {
          params = {
            insertedAfter: dataRelatedInsertedAfter,
            new: newIndex,
            old: oldIndex,
            relatedId: dataRelatedId,
            status: "update",
            ...item.dataset
          }

        } else {
          params = {status: "noop"}
        }
        
        this.pushEventTo(this.el, "reposition_end", params)
        this.dataRelatedInsertedAfter = undefined
        this.dataRelatedId = undefined
      },
      onMove: event => {
        this.dataRelatedId = event.related.id
        this.dataRelatedInsertedAfter = event.willInsertAfter
      },
      onStart: () => {
        Array.from(sorter.el.children).forEach(c => {
          c.classList.remove(grabbablePointerHover)
        })
        sorter.el.classList.add(grabbingPointerHover)

        this.pushEventTo(this.el, "reposition_start")
      }
    })

    this.handleEvent('disable-drag', () => {
      sorter.option("disabled", true)
    })

    this.handleEvent('enable-drag', () => {
      sorter.option("disabled", false)
    })

    this.handleEvent('cancel-drag', () => {
      sorter.el.classList.remove(grabbingPointerHover)
      Array.from(sorter.el.children).forEach(c => {
        c.classList.remove(grabbingPointerHover)
        c.classList.remove(`drag-ghost:${grabbingCursor}`)
        c.classList.add(`drag-ghost:${noDropCursor}`)
        c.classList.add(cancelledPointerHover)
      })
      sorter.el.classList.add(cancelledPointerHover)
    })
  }
}
