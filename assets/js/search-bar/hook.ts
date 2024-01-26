// This is optional phoenix client hook. It allows to use key down and up to select results.

export default {
  mounted() {
    const searchBarContainer = (this as any).el as HTMLDivElement
    document.addEventListener('keydown', (event) => {
      if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') {
        return
      }

      const focusElemnt = document.querySelector(':focus') as HTMLElement

      if (!focusElemnt) {
        return
      }

      if (!searchBarContainer.contains(focusElemnt)) {
        return
      }

      event.preventDefault()

      const tabElements = document.querySelectorAll(
        '#search-input, #searchbox__results_list a',
      ) as NodeListOf<HTMLElement>
      const focusIndex = Array.from(tabElements).indexOf(focusElemnt)
      const tabElementsCount = tabElements.length - 1

      if (event.key === 'ArrowUp') {
        tabElements[focusIndex > 0 ? focusIndex - 1 : tabElementsCount].focus()
      }

      if (event.key === 'ArrowDown') {
        tabElements[focusIndex < tabElementsCount ? focusIndex + 1 : 0].focus()
      }
    })
  },
}
