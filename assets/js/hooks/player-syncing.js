import debounce from 'lodash.debounce'

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
  const volumeControl = document.getElementById('volume-control')

  function sendVolumeChangedNotification(value) {
    hookContext.pushEvent('volume_level_changed', parseInt(value), ({level}) => {
      player.setVolume(level)
    })
  }

  sendVolumeChangedNotification(player.getVolume())

  const _sendVolumeChangedNotification = debounce(({target: {value}}) => {
    sendVolumeChangedNotification(value)
  }, 500)

  volumeControl.oninput = _sendVolumeChangedNotification

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
      setTimeout(() => {
        document.scrollingElement.scrollIntoView({behavior: 'smooth'})
      }, 300)
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
