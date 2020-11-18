import debounce from 'lodash.debounce'

const updateVideoTimeDisplay = (
  videoTimeTrackerElement,
  playerCurrentTime,
  playerTotalTime, origin
) => {
  const currentTime = new Date(playerCurrentTime * 1000).toISOString().substr(11, 8)
  const totalTime = new Date(playerTotalTime * 1000).toISOString().substr(11, 8)
  const videoTime = `${currentTime}/${totalTime}`
  videoTimeTrackerElement.innerText = videoTime
}

const onStateChange = (hookContext, videoTimeTrackerElement) => event => {
  switch (event.data) {
    case -1: {
      // console.log('unstarted')
      break
    }
    case 0: {
      // console.log('ended')
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      hookContext.pushEvent('player_signal_video_ended')
      break
    }
    case 1: {
      // console.log('interval is on')
      const { target: player } = event
      // console.log('playing')
      const trackTimeInterval = setInterval(() => {
        updateVideoTimeDisplay(
          videoTimeTrackerElement,
          player.getCurrentTime(),
          player.getDuration()
        )
      }, 1000)
      hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
      break
    }
    case 2: {
      // console.log('paused: ', event)
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      const { target: player } = event

      updateVideoTimeDisplay(
        videoTimeTrackerElement,
        player.getCurrentTime(),
        player.getDuration()
      )
      playerTotalTimeplayerTotalTime
      break
    }
    case 3: {
      // console.log('buffering')
      break
    }
    case 5: {
      // console.log('video cued')
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
    const videoTimeTrackerElement = document.getElementById('yt-video-time')
    const player = await initPlayer(
      onStateChange(this, videoTimeTrackerElement), onVolumeChange(this)
    )
    this.pushEvent('player_signal_ready')

    this.handleEvent('receive_playing_signal', () => {
      player.playVideo()
      updateVideoTimeDisplay(
        videoTimeTrackerElement,
        player.getCurrentTime(),
        player.getDuration()
      )
    })

    this.handleEvent('receive_paused_signal', () => {
      player.pauseVideo()
      updateVideoTimeDisplay(
        videoTimeTrackerElement,
        player.getCurrentTime(),
        player.getDuration()
      )
    })

    this.handleEvent('receive_player_state', ({shouldPlay, time, videoId}) => {
      setTimeout(() => {
        document.scrollingElement.scrollIntoView({behavior: 'smooth'})
      }, 300)
      player.loadVideoById({ videoId, startSeconds: time })
      const currentTime = player.getCurrentTime()
      currentTime && updateVideoTimeDisplay(
        videoTimeTrackerElement,
        currentTime,
        player.getDuration(),
      )
      !shouldPlay && player.pauseVideo()
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 750)
  }
})

export default PlayerSyncing
