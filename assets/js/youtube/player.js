export default (container, onReady) => {
  return new Promise((resolve) => {
    new YT.Player(container, {
      events: {
        onError: (error) => {
          console.error('[YT :: On Player Error] ', error)
        },
        onReady: async event => {
          console.debug("[YT :: On Player Ready]")
          await onReady(event.target)
          const player = event.target
          resolve(player)
        }
        // onStateChange
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
      videoId: 'oCcks-fwq2c',
      width: "100%"
    })
  })
}
