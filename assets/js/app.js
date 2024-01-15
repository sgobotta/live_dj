// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {LiveSocket} from "phoenix_live_view"
import {Socket} from "phoenix"
import Sortable from "../vendor/sortable"
import ThemeHook from './theme/hook'
import YoutubeAPI from './youtube/api'
import YoutubeHook from './youtube/hook'
import topbar from "../vendor/topbar"

// On page load or when changing themes, best to add inline in `head` to avoid
// FOUC
if (
    localStorage.getItem('theme') === 'dark' ||
    (!('theme' in localStorage) &&
      window.matchMedia('(prefers-color-scheme: dark)').matches
    )
  ) {
  document.documentElement.classList.add('dark')
  localStorage.setItem("theme", "dark")
} else {
  document.documentElement.classList.remove('dark')
  localStorage.setItem("theme", "light")
}

// eslint-disable-next-line no-unexpected-multiline
(async () => {
  await YoutubeAPI()

  const Hooks = {}
  Hooks.Theme = ThemeHook
  Hooks.Youtube = YoutubeHook
  Hooks.Sortable = {
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
  
  const csrfToken =
    document.querySelector("meta[name='csrf-token']")
    .getAttribute("content")
  const _theme = localStorage.getItem("theme")
  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks,
    params: {
      _csrf_token: csrfToken,
      _theme
    }
  })
  
  // Show progress bar on live navigation and form submits
  topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
  window.addEventListener("phx:page-loading-start", () => topbar.show(300))
  window.addEventListener("phx:page-loading-stop", () => topbar.hide())
  
  // connect if there are any LiveViews on the page
  liveSocket.connect()
  
  // expose liveSocket on window for web console debug logs and latency
  // simulation:
  // >> liveSocket.enableDebug()
  // >> liveSocket.enableLatencySim(1000) // enabled for duration of browser
  // session
  // >> liveSocket.disableLatencySim()
  window.liveSocket = liveSocket  
})();
