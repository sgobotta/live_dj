export default (container, {onStateChange}) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "420",
      width: "100%",
      videoId: '',
      playerVars: { 'controls': 0 },
      events: {
        onReady: event => {
          const player = event.target
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
