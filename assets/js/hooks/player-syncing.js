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
      console.log('State ', event.target.getPlayerState())
      const time = event.target.getCurrentTime()
      // hookContext.pushEvent('player_signal_playing', {time})
      break
    }
    case 2: {
      console.log('paused')
      const time = event.target.getCurrentTime()
      // hookContext.pushEvent('player_signal_paused', {time})
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
    const player = await initPlayer()
    this.pushEvent('player-signal-ready', null, reply => {
      const {shouldPlay, videoId, startSeconds} = reply
      player.loadVideoById({
        videoId,
        startSeconds
      })
      !shouldPlay && player.pauseVideo()
    })

    this.handleEvent('receive_playing_signal', () => {
      player.playVideo()
    })

    this.handleEvent('receive_paused_signal', () => {
      player.pauseVideo()
    })

    this.handleEvent('receive_current_time_signal', ({time, videoId, shouldPlay}) => {
      shouldPlay && player.loadVideoById({
        videoId,
        startSeconds: time + 2
      })
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 1500)
  }
})

export default PlayerSyncing
