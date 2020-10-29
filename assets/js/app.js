import "regenerator-runtime/runtime"
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// Webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import PlayerSyncing from "./hooks/player-syncing";
import PresenceSyncing from "./hooks/presence-syncing";
import DragAndDropping from "./hooks/drag-and-dropping";
import LoadYTIframeAPI from './deps/yt-iframe-api'
import createPlayer from './lib/player'

function onIframeReady() {
  console.log("[LiveDj] YT Iframe API loaded ✔️ ")
  initLiveview()
}

function initPlayer(onStateChange) {
  const playerContainer = document.getElementById("video-player");
  return createPlayer(playerContainer, {onStateChange})
}

function initLiveview() {
  let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

  const Hooks = {
    PlayerSyncing: PlayerSyncing(initPlayer),
    PresenceSyncing: PresenceSyncing(),
    DragAndDropping: DragAndDropping(),
  }

  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks,
    params: {_csrf_token: csrfToken}
  })

  // connect if there are any LiveViews on the page
  liveSocket.connect()

  window.liveSocket = liveSocket  
}

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

console.log("[LiveDj] Loading YT Iframe API...")
LoadYTIframeAPI(onIframeReady)
