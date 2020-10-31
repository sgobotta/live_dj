const onStateChange = hookContext => event => {
  switch (event.data) {
    case -1: {
      console.log('unstarted')
      break
    }
    case 0: {
      console.log('ended')
      hookContext.pushEvent('player_signal_video_ended')
      break
    }
    case 1: {
      console.log('playing')
      break
    }
    case 2: {
      console.log('paused: ', event)
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

const onVolumeChange = hookContext => player => {
  const volumeControl = document.getElementById("volume-control")

  function sendVolumeChangedNotification(value) {
    hookContext.pushEvent('volume_level_changed', value, ({level}) => {
      player.setVolume(level)
    })
  }

  sendVolumeChangedNotification(player.getVolume())

  volumeControl.oninput = ({target: {value}}) => {
    sendVolumeChangedNotification(value)
  }
  volumeControl.onmouseenter = () => {
    volumeControl.focus()
  }
}

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const player = await initPlayer(onStateChange(this), onVolumeChange(this))
    this.pushEvent('player_signal_ready')

    this.handleEvent('receive_playing_signal', () => {
      player.playVideo()
    })

    this.handleEvent('receive_paused_signal', () => {
      player.pauseVideo()
    })

    this.handleEvent('receive_player_state', ({shouldPlay, time, videoId}) => {
      player.loadVideoById({
        videoId,
        startSeconds: time
      })
      !shouldPlay && player.pauseVideo()
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 1500)
  }
})

export default PlayerSyncing
