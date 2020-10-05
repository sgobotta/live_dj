export default (videoContainer, callbacks = []) => {

  return new Promise((resolve, reject) => {
    function init() {
      window.onYouTubeIframeAPIReady = () => {
        onIframeReady(videoContainer, '')
      }
      const youtubeScriptTag = document.createElement("script")
      youtubeScriptTag.src = "//www.youtube.com/iframe_api"
      document.head.appendChild(youtubeScriptTag)
    }
  
    function onIframeReady(videoContainer, videoId) {
      return new YT.Player(videoContainer, {
        height: "210",
        width: "100%",
        videoId,
        events: {
          onReady: (event) => {
            resolve(event.target)
          },
          onStateChange: (event) => {
            event.target.playVideo()
            callbacks.forEach(c => c(event))
          },
        },
      })
    }
  
    function getCurrentTime() {
      return Math.floor(this.player.getCurrentTime() * 1000)
    }
  
    function seekTo(millsec) {
      return this.player.seekTo(millsec / 1000)
    }

    init()
  })
}
