export default (container, {onStateChange}) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      events: {
        onError: (error) => {
          console.error('[YT] ', error)
        },
        onReady: event => {
          const player = event.target
          resolve(player)
        },
        onStateChange
      },
      height: "100%",
      playerVars: {
        controls: 0,
        disablekb: 1,
        enablejsapi: 1,
        iv_load_policy: 3,
        rel: 0,
        showinfo: 0
      },
      videoId: '',
      width: "100%"
    })
  })
}
