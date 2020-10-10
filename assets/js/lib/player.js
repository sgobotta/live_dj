export default (container, {onStateChange}) => {
  function configureVolume(player) {
    const volumeControl = document.getElementById("volume-control")
    volumeControl.value = player.getVolume()
    volumeControl.onchange = event => {
      player.setVolume(event.target.value)
    }
    volumeControl.oninput = event => {
      player.setVolume(event.target.value)
    }
    volumeControl.onmouseenter = () => {
      volumeControl.focus()
    }
  }

  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "210",
      width: "100%",
      videoId: '',
      playerVars: { 'controls': 0 },
      events: {
        onReady: event => {
          const player = event.target
          configureVolume(player)
          resolve(player)
        },
        onStateChange,
        onError: (error) => {
          console.error('[YT] ', error)
        }
      },
    })
  })
}
