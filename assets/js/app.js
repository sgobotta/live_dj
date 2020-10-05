// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "regenerator-runtime/runtime"
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import VideoPlaying from "./hooks/video-playing";
import QueueSyncing from "./hooks/queue-syncing";
import PresenceSyncing from "./hooks/presence-syncing";
import initPlayer from "./lib/player"

const playerContainer = document.getElementById("video-player");

console.log("[LiveDj] Loading player...")

function onPlayerStateChange(event) {
  console.log('miimimim ', event)
}

initPlayer(playerContainer, [onPlayerStateChange])
.then(player => {
  console.log("[LiveDj] Player loaded ✔️ ", player)

  let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

  const Hooks = {
    VideoPlaying: VideoPlaying(player),
    VideoQueuing: QueueSyncing(player),
    PresenceSyncing: PresenceSyncing(player),
  }

  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks,
    params: {_csrf_token: csrfToken}
  })

  // connect if there are any LiveViews on the page
  liveSocket.connect()
})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())


// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
