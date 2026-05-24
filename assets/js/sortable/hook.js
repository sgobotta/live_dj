import Sortable from '../../vendor/sortable'

/* eslint-disable max-len */
const TRASH_SVG = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width:28px;height:28px"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>'
/* eslint-enable max-len */

function createTrashZone() {
  const el = document.createElement('div')
  el.id = 'sortable-trash-zone'
  Object.assign(el.style, {
    alignItems: 'center',
    background: 'rgba(113,113,122,0.85)',
    borderRadius: '50%',
    bottom: '120px',
    boxShadow: '0 4px 24px rgba(0,0,0,0.3)',
    color: 'white',
    display: 'flex',
    height: '64px',
    justifyContent: 'center',
    left: '50%',
    opacity: '0',
    pointerEvents: 'none',
    position: 'fixed',
    transform: 'translateX(-50%) scale(0.6)',
    transition: 'opacity 0.2s ease, transform 0.2s ease, background 0.15s ease',
    width: '64px',
    zIndex: '9999'
  })
  el.innerHTML = TRASH_SVG
  document.body.appendChild(el)
  requestAnimationFrame(() => {
    el.style.opacity = '1'
    el.style.transform = 'translateX(-50%) scale(1)'
  })
  return el
}

function isOverElement(x, y, el) {
  const rect = el.getBoundingClientRect()
  return x >= rect.left && x <= rect.right &&
    y >= rect.top && y <= rect.bottom
}

export default {
  mounted() {
    const noDropCursor = 'cursor-no-drop'
    const grabCursor = 'cursor-grab'
    const grabbingCursor = 'cursor-grabbing'

    const cancelledPointerHover = `hover:${noDropCursor}`
    const grabbablePointerHover = `hover:${grabCursor}`
    const grabbingPointerHover = `hover:${grabbingCursor}`

    let trashZone = null
    let lastPointerX = 0
    let lastPointerY = 0
    let onPointerMove = null

    const cleanupTrash = () => {
      if (!trashZone) return
      document.removeEventListener('pointermove', onPointerMove)
      document.removeEventListener('touchmove', onPointerMove)
      trashZone.remove()
      trashZone = null
      onPointerMove = null
    }

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

        const droppedOnTrash = trashZone &&
          isOverElement(lastPointerX, lastPointerY, trashZone)
        cleanupTrash()

        const {dataRelatedInsertedAfter, dataRelatedId} = this
        let params

        if (droppedOnTrash) {
          params = {status: "remove", track_id: item.dataset.id}
        } else if ([
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
      onStart: (event) => {
        Array.from(sorter.el.children).forEach(c => {
          c.classList.remove(grabbablePointerHover)
        })
        sorter.el.classList.add(grabbingPointerHover)

        this.pushEventTo(this.el, "reposition_start")

        const isCurrentMedia =
          event.item.dataset.id === this.el.dataset.currentMediaId

        if (isCurrentMedia) return

        trashZone = createTrashZone()
        let lastOver = false
        onPointerMove = (e) => {
          const pos = e.touches ? e.touches[0] : e
          lastPointerX = pos.clientX
          lastPointerY = pos.clientY

          const over = isOverElement(lastPointerX, lastPointerY, trashZone)
          if (over === lastOver) return
          lastOver = over

          const dragEl = document.querySelector('.drag-item')
          if (over) {
            trashZone.style.background = 'rgba(239,68,68,0.9)'
            trashZone.style.transform = 'translateX(-50%) scale(1.15)'
            if (dragEl) {
              const rect = dragEl.getBoundingClientRect()
              const raw = rect.width > 0
                ? (lastPointerX - rect.left) / rect.width * 100
                : 50
              const pct = Math.max(0, Math.min(100, raw))
              const lClip = `${pct.toFixed(1)}%`
              const rClip = `${(100 - pct).toFixed(1)}%`
              dragEl.style.transition = 'none'
              dragEl.style.clipPath = 'inset(0 0% 0 0%)'
              requestAnimationFrame(() => {
                if (!lastOver) return
                dragEl.style.transition = 'clip-path 0.5s ease'
                dragEl.style.clipPath = `inset(0 ${rClip} 0 ${lClip})`
              })
            }
          } else {
            trashZone.style.background = 'rgba(113,113,122,0.85)'
            trashZone.style.transform = 'translateX(-50%) scale(1)'
            if (dragEl) {
              dragEl.style.transition = 'clip-path 0.35s ease'
              dragEl.style.clipPath = 'inset(0 0% 0 0%)'
            }
          }
        }
        document.addEventListener('pointermove', onPointerMove)
        document.addEventListener('touchmove', onPointerMove, {passive: true})
      }
    })

    this.handleEvent('disable-drag', () => {
      sorter.option("disabled", true)
    })

    this.handleEvent('enable-drag', () => {
      sorter.option("disabled", false)
    })

    this.handleEvent('cancel-drag', () => {
      cleanupTrash()
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
