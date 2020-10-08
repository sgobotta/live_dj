export default (container) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "210",
      width: "100%",
      videoId: '',
      events: {
        onReady: event => {
          resolve(event.target)
        },
        onStateChange: (event) => {
  
        },
        onError: (error) => {
          console.error('[YT] ', error)
        }
      },
    })
  })
}
