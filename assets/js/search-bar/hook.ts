import {createListScope, pushScope} from '../keyboard'

// This is optional phoenix client hook. It allows to use key down and up to select results.

export default {
  destroyed() {
    this.detach?.()
  },

  mounted() {
    const searchBarContainer = (this as any).el as HTMLDivElement
    this.focusedId = null

    const form = searchBarContainer.querySelector('form')
    const searchInput = searchBarContainer.querySelector<HTMLInputElement>('#search-input')
    const resultsList = searchBarContainer.querySelector<HTMLUListElement>('#searchbox__results_list')
    const panel = document.getElementById('browse-modal-panel')

    form?.addEventListener('submit', () => searchInput?.blur())

    resultsList?.addEventListener('focusin', (e) => {
      const item = (e.target as HTMLElement).closest<HTMLElement>('[data-id]')
      if (item) this.focusedId = item.dataset.id
    })

    // Block adjustments until the sheet slide-in animation (300ms) has settled.
    // visualViewport resize events that fire during the animation are no-ops.
    let panelReady = false

    const adjustForKeyboard = () => {
      if (!window.visualViewport || !panelReady) return

      const vp = window.visualViewport

      if (panel) {
        // Clear inline transform so getBoundingClientRect reflects the natural position,
        // then compute only the exact overlap with the keyboard area.
        panel.style.transform = ''
        const panelRect = panel.getBoundingClientRect()
        const visibleBottom = vp.offsetTop + vp.height
        const overlap = panelRect.bottom - visibleBottom
        panel.style.transform = overlap > 0 ? `translateY(-${overlap}px)` : ''
      }

      if (resultsList) {
        requestAnimationFrame(() => {
          if (!searchInput || !resultsList) return
          const inputRect = searchInput.getBoundingClientRect()
          const available = vp.offsetTop + vp.height - inputRect.bottom - 8
          resultsList.style.maxHeight = `${Math.max(0, available)}px`
        })
      }
    }

    const clearForKeyboard = () => {
      if (panel) panel.style.transform = ''
      if (resultsList) resultsList.style.maxHeight = ''
    }

    setTimeout(() => {
      panelReady = true
      adjustForKeyboard()
    }, 300)

    searchInput?.addEventListener('focus', () => {
      window.visualViewport?.addEventListener('resize', adjustForKeyboard)
      adjustForKeyboard()
    })

    searchInput?.addEventListener('blur', () => {
      window.visualViewport?.removeEventListener('resize', adjustForKeyboard)
      clearForKeyboard()
    })

    // Arrow up/down move real focus between the search input and every
    // still-addable result button, wrapping at both ends - the browse
    // modal (and this component with it) only exists while it's open, so
    // pushing/popping the scope on mounted()/destroyed() already matches
    // the modal's own lifecycle.
    const grid = createListScope({
      container: searchBarContainer,
      edgeBehavior: 'wrap',
      items: () =>
        Array.from(
          document.querySelectorAll<HTMLElement>(
            '#search-input, #searchbox__results_list button'
          )
        )
    })
    this.detach = pushScope({grid, id: 'search-bar'})
  },

  // Adding a track swaps its "+" button for a checkmark, so the button that
  // had focus is removed from the DOM and focus drops to <body>. Reclaim it
  // on the nearest still-addable item: prefer the next one down, fall back
  // to the nearest one above, and if every result has already been added,
  // send focus back to the search input so the user can keep typing.
  updated() {
    if (document.activeElement !== document.body) return

    const searchBarContainer = (this as any).el as HTMLDivElement
    const searchInput = searchBarContainer.querySelector<HTMLInputElement>('#search-input')
    const resultsList = searchBarContainer.querySelector<HTMLUListElement>('#searchbox__results_list')
    const items = resultsList
      ? Array.from(resultsList.querySelectorAll<HTMLElement>('[data-id]'))
      : []
    const currentIndex = items.findIndex((item) => item.dataset.id === this.focusedId)

    const nextButton = (from: number, step: number) => {
      for (let i = from; i >= 0 && i < items.length; i += step) {
        const button = items[i].querySelector('button')
        if (button) return button
      }
      return null
    }

    const target = currentIndex === -1
      ? null
      : nextButton(currentIndex + 1, 1) || nextButton(currentIndex - 1, -1)

    if (target) {
      target.focus()
      target.scrollIntoView({ block: 'center' })
    } else {
      searchInput?.focus()
    }
  },
}
