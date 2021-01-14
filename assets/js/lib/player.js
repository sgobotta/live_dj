export default (container, {onStateChange}) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      height: "100%",
      width: "100%",
      videoId: '',
      playerVars: {
        controls: 0,
        disablekb: 1,
        enablejsapi: 1,
        iv_load_policy: 3,
        rel: 0,
        showinfo: 0,
      },
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
