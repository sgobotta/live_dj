import debounce from 'lodash.debounce'

const updateVideoTimeDisplay = (
  timeTrackerElem,
  playerCurrentTime,
  playerTotalTime,
) => {
  const currentTime = new Date(playerCurrentTime * 1000).toISOString().substr(11, 8)
  const totalTime = new Date(playerTotalTime * 1000).toISOString().substr(11, 8)
  const videoTime = `${currentTime}/${totalTime}`
  timeTrackerElem.innerText = videoTime
}

const updateVideoSlider = (
  timeSliderElem,
  playerCurrentTime,
  playerTotalTime,
) => {
  timeSliderElem.min = 0
  timeSliderElem.max = playerTotalTime
  timeSliderElem.value = playerCurrentTime
}


const udpateTimeDisplays = (timeTrackerElem, timeSliderElem, player) => {
  const currentTime = player.getCurrentTime()
  const totalTime = player.getDuration()
  updateVideoTimeDisplay(timeTrackerElem, currentTime, totalTime)
  updateVideoSlider(timeSliderElem, currentTime, totalTime)
}

const onStateChange = (
  hookContext,
  timeTrackerElem,
  timeSliderElem
) => event => {
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
        udpateTimeDisplays(timeTrackerElem, timeSliderElem, player)
      }, 1000)
      hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
      break
    }
    case 2: {
      // console.log('paused: ', event)
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      const { target: player } = event
      udpateTimeDisplays(timeTrackerElem, timeSliderElem, player)
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

const initTimeSlider = hookContext => player => {
  // const timeSlider = document.getElementById('video-time-control')

  // const playerCurrentTime = player.getCurrentTime()
  // const playerDuration = player.getDuration()
  // console.log('[Player] Current time :: ', playerCurrentTime)
  // console.log('[Player] Duration :: ', playerDuration)
  // timeSlider.min = 0
  // timeSlider.max = playerDuration
  // timeSlider.value = playerCurrentTime

  // const onTimeChange = debounce(({target}) => {
    
  //   console.log('target :: ', target)
  //   console.log('value :: ',target.value)
  //   // timeTracker.value = player.getCurrentTime()
  
  // }, 200)

  // timeSlider.oninput = onTimeChange
}

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const timeTrackerElem = document.getElementById('yt-video-time')
    const timeSliderElem = document.getElementById('video-time-control')
    const player = await initPlayer(
      onStateChange(this, timeTrackerElem, timeSliderElem),
      onVolumeChange(this),
    )
    this.pushEvent('player_signal_ready')

    this.handleEvent('receive_mute_signal', () => {
      player.mute()
    })
    
    this.handleEvent('receive_unmute_signal', () => {
      player.unMute()
    })

    this.handleEvent('receive_playing_signal', () => {
      player.playVideo()
      udpateTimeDisplays(timeTrackerElem, timeSliderElem, player)
    })

    this.handleEvent('receive_paused_signal', () => {
      player.pauseVideo()
      udpateTimeDisplays(timeTrackerElem, timeSliderElem, player)
    })

    this.handleEvent('receive_player_state', ({shouldPlay, time, videoId}) => {
      player.loadVideoById({ videoId, startSeconds: time })
      setTimeout(() => {
        document.scrollingElement.scrollIntoView({behavior: 'smooth'})

        udpateTimeDisplays(timeTrackerElem, timeSliderElem, player)

        !shouldPlay && player.pauseVideo()
      }, 300)
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 500)
  }
})

export default PlayerSyncing
