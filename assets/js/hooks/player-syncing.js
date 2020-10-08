const PlayerSyncing = player => ({
  mounted() {
    this.pushEvent('player-is-ready', null, reply => {
      console.log('Reply: ', reply)
      const {shouldPlay, videoId, startSeconds} = reply
      shouldPlay && player.loadVideoById({
        videoId,
        startSeconds
      })
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      console.log('CURRENT TIME ::: ', currentTime)
      // this.pushEvent('video-time-sync', currentTime)
    }, 1000)
  }
})

export default PlayerSyncing
