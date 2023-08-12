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
import topbar from "../vendor/topbar"

const Hooks = {}

Hooks.Sortable = {
  mounted() {
    let sorter = new Sortable(this.el, {
      animation: 150,
      delay: 100,
      dragClass: "drag-item",
      forceFallback: true,
      ghostClass: "drag-ghost",
      onEnd: e => {
        const params = {new: e.newIndex, old: e.oldIndex, ...e.item.dataset}
        this.pushEventTo(this.el, "reposition_end", params)
      },
      onStart: e => {
        this.pushEventTo(this.el, "reposition_start")
      }
    })

    this.handleEvent('disable-drag', () => {
      console.log("DISABLE!")
      console.log(this)
      console.log(sorter.option("disabled", true))
    })

    this.handleEvent('enable-drag', () => {
      console.log("ENABLE!")
      console.log(this)
      console.log(sorter.option("disabled", false))
    })
  }
}

const csrfToken =
  document.querySelector("meta[name='csrf-token']")
  .getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken }
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
