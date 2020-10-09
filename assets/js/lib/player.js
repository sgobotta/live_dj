export default (container, {onStateChange}) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "210",
      width: "100%",
      videoId: '',
      playerVars: { 'controls': 0 },
      events: {
        onReady: event => {
          resolve(event.target)
        },
        onStateChange,
        onError: (error) => {
          console.error('[YT] ', error)
        }
      },
    })
  })
}
