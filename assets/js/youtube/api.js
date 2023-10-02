export default () => {
  return new Promise(resolve => {
    window.onYouTubeIframeAPIReady = () => {
      resolve()
      console.debug("✅ Youtube API loaded!")
    }
    const youtubeScriptTag = document.createElement("script")
    youtubeScriptTag.src = "//www.youtube.com/iframe_api"
    document.head.appendChild(youtubeScriptTag)
  })
}
