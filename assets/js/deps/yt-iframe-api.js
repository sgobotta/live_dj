export default (onIframeReady) => {
  window.onYouTubeIframeAPIReady = () => {
    onIframeReady()
  }
  const youtubeScriptTag = document.createElement("script")
  youtubeScriptTag.src = "//www.youtube.com/iframe_api"
  document.head.appendChild(youtubeScriptTag)
}
