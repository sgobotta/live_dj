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

    this.handleEvent("receive_current_video", ({params: video}) => {
      console.log('Event [receive_current_video] ::: Video: ', video)
      const v = player.getVolume()
      console.log('Volume: ', v)
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      console.log('CURRENT TIME ::: ', currentTime)
      // this.pushEvent('video-time-sync', currentTime)
    }, 1000)
  }
})

export default PlayerSyncing
