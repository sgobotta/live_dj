export default (container, {onStateChange, onVolumeChange}) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "420",
      width: "100%",
      videoId: '',
      playerVars: { 'controls': 0 },
      events: {
        onReady: event => {
          const player = event.target
          onVolumeChange(player)
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
