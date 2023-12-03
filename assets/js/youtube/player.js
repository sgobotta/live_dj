export default (container, {onReady, onStateChange}) => {
return new Promise((resolve, reject) => {
    new YT.Player(container, {
      events: {
        onError: (error) => {
          console.error('[YT :: On Player Error] ', error)
          reject(error)
        },
        onReady: async event => {
          console.debug("[YT :: On Player Ready]")
          await onReady(event.target)
          const player = event.target
          resolve(player)
        },
        onStateChange
      },
      playerVars: {
        controls: 0,
        disablekb: 1,
        enablejsapi: 1,
        iv_load_policy: 3,
        rel: 0,
        showinfo: 0
      },
      videoId: 'fc3EIAC--bU'
    })
  })
}
