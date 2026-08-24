export default {
  mounted() {
    console.info("Mount dark mode hook")

    const setTheme = theme => {
      if (theme === 'dark') {
        localStorage.setItem('theme', 'dark')
        document.documentElement.classList.add('dark')
      } else {
        localStorage.setItem('theme', 'light')
        document.documentElement.classList.remove('dark')
      }

      /**
       * Notify theme change
       */
      this.pushEventTo(this.el, 'toggle-theme', { theme })
    }

    window.addEventListener(
      "toggle-theme",
      e => {
        e.preventDefault()
        const currentTheme = localStorage.getItem("theme")
        const theme = currentTheme === 'dark' ? 'light' : 'dark'

        setTheme(theme)
      }
    )

    window.addEventListener(
      "set-theme",
      e => {
        e.preventDefault()
        const theme = e.detail && e.detail.theme

        if (theme !== 'light' && theme !== 'dark') return
        if (theme === localStorage.getItem('theme')) return

        setTheme(theme)
      }
    )
  }
}
