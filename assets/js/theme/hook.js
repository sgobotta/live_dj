export default {
  mounted() {
    console.info("Mount dark mode hook")

    window.addEventListener(
      "toggle-theme",
      e => {
        e.preventDefault()
        const currentTheme = localStorage.getItem("theme")
        const theme = currentTheme === 'dark' ? 'light' : 'dark'

        const toggleDarkMode = () => {
          if (theme === 'dark') {
            localStorage.setItem('theme', 'dark')
            document.documentElement.classList.add('dark')
          } else {
            localStorage.setItem('theme', 'light')
            document.documentElement.classList.remove('dark')
          }
        }

        /**
         * Notify theme change
         */
        this.pushEventTo(this.el, 'toggle-theme', { theme })

        /**
         * Run animations
         */
        const body = document.body
        body.classList.add("duration-200")
        body.classList.add("scale-y-0")
        body.classList.add('opacity-0')

        setTimeout(() => {
          toggleDarkMode()
          body.classList.remove("duration-100")
          body.classList.add("duration-500")
          body.classList.remove("scale-y-0")
          body.classList.add("scale-y-100")
          body.classList.add('opacity-100')

          setTimeout(() => {
            body.classList.remove("scale-y-100")
            body.classList.remove("duration-500")
            body.classList.remove("rounded-full")
          }, 500)
        }, 200)
      }
    )
  }
}
