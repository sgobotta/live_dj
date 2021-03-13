import { secondsToTime } from '../lib/date-utils'

const HOOK_ID = '#player-syncing-controls'

const updateTimeDisplay = (timeTrackerElem, time) => {
  const videoTime = (time === 0 || time === undefined)
    ? '-'
    : secondsToTime(parseInt(time))
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


const udpateTimeDisplays = (
  startTimeTrackerElem,
  endTimeTrackerElem,
  timeSliderElem,
  player
) => {
  const currentTime = player.getCurrentTime()
  const totalTime = player.getDuration()
  updateTimeDisplay(startTimeTrackerElem, currentTime)
  updateTimeDisplay(endTimeTrackerElem, totalTime)
  updateVideoSlider(timeSliderElem, currentTime, totalTime)
}

const onStateChange = (
  hookContext,
  startTimeTrackerElem,
  endTimeTrackerElem,
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
      hookContext.pushEventTo(HOOK_ID, 'player_signal_playing')
      const trackTimeInterval = setInterval(() => {
        udpateTimeDisplays(
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem,
          player,
        )
      }, 1000)
      hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
      break
    }
    case 2: {
      hookContext.pushEventTo(HOOK_ID, 'player_signal_paused')
      const { trackTimeInterval } = hookContext.el.dataset
      clearInterval(trackTimeInterval)
      const { target: player } = event
      udpateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player,
      )
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

const PlayerSyncing = initPlayer => ({
  async mounted() {
    const startTimeTrackerElem = document.getElementById('yt-video-start-time')
    const endTimeTrackerElem = document.getElementById('yt-video-end-time')
    const timeSliderElem = document.getElementById('video-time-control')
    const player = await initPlayer(
      onStateChange(
        this,
        startTimeTrackerElem, endTimeTrackerElem, timeSliderElem
      ),
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
      udpateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player,
      )
    })

    this.handleEvent('receive_paused_signal', () => {
      player.pauseVideo()
      udpateTimeDisplays(
        startTimeTrackerElem,
        endTimeTrackerElem,
        timeSliderElem,
        player,
      )
    })

    this.handleEvent('receive_player_state', ({
      shouldPlay,
      time,
      videoId
    }) => {
      player.loadVideoById({ videoId, startSeconds: time })
      setTimeout(() => {
        document.scrollingElement.scrollIntoView({ behavior: 'smooth' })

        udpateTimeDisplays(
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem,
          player,
        )

        !shouldPlay && player.pauseVideo()
      }, 300)
    })

    this.handleEvent('receive_player_volume', ({ level: volumeLevel }) => {
      player.setVolume(volumeLevel)
    })

    setInterval(() => {
      const currentTime = player.getCurrentTime()
      this.pushEvent('player_signal_current_time', currentTime)
    }, 500)
  }
})

export default PlayerSyncing
