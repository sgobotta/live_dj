export default {
  player: null,
  init(videoContainer, videoId, onReady) {
    window.onYouTubeIframeAPIReady = () => {
      this.onIframeReady(videoContainer, videoId, onReady)
    }
    const youtubeScriptTag = document.createElement("script")
    youtubeScriptTag.src = "//www.youtube.com/iframe_api"
    document.head.appendChild(youtubeScriptTag)
  },
  onIframeReady(videoContainer, videoId, onReady) {
    this.player = new YT.Player(videoContainer, {
      height: "420",
      width: "100%",
      videoId: videoId,
      events: {
        onReady: (event) => onReady(event),
        onStateChange: (event) => this.onPlayerStateChange(event),
      },
    })
  },
  onPlayerStateChange(event) {},
  getCurrentTime() {
    return Math.floor(this.player.getCurrentTime() * 1000)
  },
  seekTo(millsec) {
    return this.player.seekTo(millsec / 1000)
  },
}
