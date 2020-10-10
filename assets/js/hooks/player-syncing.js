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

function setVolume(player) {
  const volumeControl = document.getElementById("volume-control")
  volumeControl.value = player.getVolume()
}

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const player = await initPlayer()
    this.pushEvent('player_signal_ready')

    this.handleEvent('receive_playing_signal', () => {
      setVolume(player)
      player.playVideo()
    })

    this.handleEvent('receive_paused_signal', () => {
      setVolume(player)
      player.pauseVideo()
    })

    this.handleEvent('receive_player_state', ({shouldPlay, time, videoId}) => {
      shouldPlay && player.loadVideoById({
        videoId,
        startSeconds: time + 1
      })
      !shouldPlay && player.pauseVideo()
      setVolume(player)
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 1500)
  }
})

export default PlayerSyncing
