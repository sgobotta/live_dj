const onStateChange = hookContext => event => {
  switch (event.data) {
    case -1: {
      console.log('unstarted')
      break
    }
    case 0: {
      console.log('ended')
      break
    }
    case 1: {
      console.log('playing')
      hookContext.pushEvent('player-signal-playing', {})
      break
    }
    case 2: {
      console.log('paused')
      hookContext.pushEvent('player-signal-paused', {})
      break
    }
    case 3: {
      console.log('buffering')
      break
    }
    case 5: {
      console.log('video cued')
      break
    }
  }
}

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const player = await initPlayer(onStateChange(this))
    this.pushEvent('player-signal-ready', null, reply => {
      const {shouldPlay, videoId, startSeconds} = reply
      shouldPlay && player.loadVideoById({
        videoId,
        startSeconds
      })
    })

    setInterval(() => {
      // const currentTime = player.getCurrentTime()
      // console.log('CURRENT TIME ::: ', currentTime)
      // this.pushEvent('video-time-sync', currentTime)
    }, 1000)
  }
})

export default PlayerSyncing
