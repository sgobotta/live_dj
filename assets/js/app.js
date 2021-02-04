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
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

// console.log("[LiveDj] Loading YT Iframe API...")
LoadYTIframeAPI(onIframeReady)

let deferredPrompt;
const addBtn = document.querySelector('.add-pwa-button');
addBtn.style.display = 'none';

window.addEventListener('beforeinstallprompt', (e) => {
  // Prevent Chrome 67 and earlier from automatically showing the prompt
  e.preventDefault();
  // Stash the event so it can be triggered later.
  deferredPrompt = e;
  // Update UI to notify the user they can add to home screen
  addBtn.style.display = 'block';

  addBtn.addEventListener('click', (e) => {
    // hide our user interface that shows our A2HS button
    addBtn.style.display = 'none';
    // Show the prompt
    deferredPrompt.prompt();
    // Wait for the user to respond to the prompt
    deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === 'accepted') {
          console.log('User accepted the A2HS prompt');
        } else {
          console.log('User dismissed the A2HS prompt');
        }
        deferredPrompt = null;
      });
  });
});
