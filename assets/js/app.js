// Used to support async/wait functions
import "regenerator-runtime/runtime"
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import 'alpinejs'

// Webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

import ChatSyncing from "./hooks/chat-syncing"
import DragAndDropping from "./hooks/drag-and-dropping"
import ModalInteracting from "./hooks/modal-interacting"
import NotificationsHandling from "./hooks/notifications-handling"
import PlayerSyncing from "./hooks/player-syncing"
import PresenceSyncing from "./hooks/presence-syncing"
import SearchSyncing from "./hooks/search-syncing"
import UiFeedback from "./hooks/ui-feedback"

import LoadYTIframeAPI from './deps/yt-iframe-api'

import createPlayer from './lib/player'

console.log('Hello there :)')

function onIframeReady() {
  // console.log("[LiveDj] YT Iframe API loaded ✔️ ")
  initLiveview()
}

function initPlayer(onStateChange, onVolumeChange) {
  const playerContainer = document.getElementById("video-player")
  return createPlayer(playerContainer, {onStateChange, onVolumeChange})
}

function initLiveview() {
  let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

  Notification.requestPermission()

  const Hooks = {
    ChatSyncing: ChatSyncing(),
    DragAndDropping: DragAndDropping(),
    ModalInteracting: ModalInteracting(),
    NotificationsHandling: NotificationsHandling(),
    PlayerSyncing: PlayerSyncing(initPlayer),
    PresenceSyncing: PresenceSyncing(),
    SearchSyncing: SearchSyncing(),
    UiFeedback: UiFeedback(),
  }

  const liveSocket = new LiveSocket("/live", Socket, {
    dom: {
      onBeforeElUpdated(from, to) {
        if (from.__x) {
          window.Alpine.clone(from.__x, to)
        }
      }
    },
    hooks: Hooks,
    params: {_csrf_token: csrfToken}
  })

  // connect if there are any LiveViews on the page
  liveSocket.connect()

  window.liveSocket = liveSocket  
}

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => {
  if (info.detail && info.detail.kind && info.detail.kind === "error") {
    const alert = document.getElementById('livedj-alert')
    alert.classList.remove('invisible')
    alert.classList.add('visible')
    const textContainer = document.getElementById('livedj-alert-container')
    const text = document.createElement('p')
    text.innerHTML = 'Connecting to server...'
    textContainer.replaceChildren(text)
  }
  NProgress.start()
})
window.addEventListener("phx:page-loading-stop", info => {
  const textContainer = document.getElementById('livedj-alert-container')
  const alert = document.getElementById('livedj-alert')
  const text = document.createElement('p')
  text.innerHTML = ''
  textContainer.replaceChildren(text)
  setTimeout(() => {
    alert.classList.remove('visible')
    alert.classList.add('invisible')
  }, 1000)

  NProgress.done()
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

// console.log("[LiveDj] Loading YT Iframe API...")
LoadYTIframeAPI(onIframeReady)
