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
import VideoPlayingHook from "./hooks/video-playing";

const request = require('superagent');

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

// Show progress bar on live navigation and form submits
// window.addEventListener("phx:page-loading-start", info => NProgress.start())
// window.addEventListener("phx:page-loading-stop", info => NProgress.done())

const playerContainer = document.getElementById("video-player");

const Hooks = {
  VideoPlaying: VideoPlayingHook(playerContainer),
}

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})


function handleSubmit(q, hdOnly) {
  var that = this,
      videoDef = hdOnly ? 'high' : 'any';

  request
    .get('https://www.googleapis.com/youtube/v3/search')
    .query({
      key: '',
      part: 'snippet',
      q: q,
      type: 'video',
      maxResults: 20,
      videoDefinition: videoDef
    })
    .end(function(err, response){
      console.log(response)
      response.body.items.forEach(i => {
        const tr = document.createElement('tr')
        const td = document.createElement('td')
        const a = document.createElement('a')
        const img = document.createElement('img')
        img.src = i.snippet.thumbnails.medium.url
        a.appendChild(img)
        td.appendChild(a)
        tr.appendChild(td)
        document.body.appendChild(tr)
      })
    });
}
const query = 'Usted Señalemelo'
const button = document.createElement('button')
button.innerHTML = "CLICK ME";
button.onclick = () => handleSubmit(query)

document.body.appendChild(button)

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

