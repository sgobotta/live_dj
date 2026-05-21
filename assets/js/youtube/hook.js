import initPlayer from './player'
import { startNoise, stopNoise } from '../animation/noise'
import { secondsToTime } from '../lib/date-utils'

function scrollToElement(elementId) {
  const element = document.getElementById(elementId)
  if (!element) return

  const scrollContainer = document.getElementById('lists')
  if (scrollContainer) {
    const itemTop = element.offsetTop - scrollContainer.offsetTop - 8
    scrollContainer.scrollTo({ behavior: 'smooth', top: itemTop })
  } else {
    element.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }
}

const updateTimeDisplay = (timeTrackerElem, time) => {
  const videoTime = (time === 0 || time === undefined)
    ? '0:00'
    : secondsToTime(parseInt(time))
  timeTrackerElem.innerText = videoTime
}

const updateVideoSlider = (
  timeSliderElem,
  playerCurrentTime,
  playerTotalTime
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

export default {
  backdrop_id: null,
  endTimeTrackerId: null,
  handleCallbackEvent: async (callbackEvent, args = {}) => {
    if (callbackEvent) {
      await this.pushEventTo(this.el, callbackEvent, args)
    }
  },
  mounted() {
    /**
     * on_container_mounted
     *
     * Received when the player DOM has been mounted.
     */
    this.handleEvent('on_container_mounted', async ({
      backdrop_id: backdropId,
      player_container_id: playerContainerId,
      spinner_id: spinnerId,
      start_time_tracker_id: startTimeTrackerId,
      end_time_tracker_id: endTimeTrackerId,
      time_slider_id: timeSliderId
    }) => {
      this.spinnerId = spinnerId
      this.backdropId = backdropId
      this.playerContainerId = playerContainerId
      this.startTimeTrackerId = startTimeTrackerId
      this.endTimeTrackerId = endTimeTrackerId
      this.timeSliderId = timeSliderId
      console.debug(
        '[Player :: on_container_mounted]',
        `backdrop_container_id=${this.backdropId}`,
        `player_container_id=${this.playerContainerId}`,
        `spinner_container_id=${this.spinnerId}`
      )

      const canvas = document.getElementById(this.spinnerId)
      canvas.classList.remove("hidden")
      startNoise(canvas)

      const onPlayerReady = player => {
        console.debug('[Player :: Ready]', player)
        player.g.classList.add("rounded-lg")

        this.player = player
        this.pushEventTo(this.el, 'on_player_loaded')
      }

      const onStateChange = (hookContext) => async event => {
        const startTimeTrackerElem = document.getElementById(
          hookContext.startTimeTrackerId
        )
        const endTimeTrackerElem = document.getElementById(
          hookContext.endTimeTrackerId
        )
        const timeSliderElem = document.getElementById(hookContext.timeSliderId)
        /* eslint-disable no-case-declarations */
        switch (event.data) {
          case YT.PlayerState.UNSTARTED:
            console.debug("[Player State :: UNSTARTED")
            break
          case YT.PlayerState.ENDED:
            console.debug("[Player State :: ENDED")
            clearInterval(hookContext.el.dataset.trackTimeInterval)
            await this.pushEventTo(this.el, 'on_player_ended')
            break
          case YT.PlayerState.PLAYING:
            console.debug("[Player State :: PLAYING")
            hookContext.shouldAutoplay = false

            await this.pushEventTo(this.el, 'on_player_playing')
            const trackTimeInterval = setInterval(() => {
              udpateTimeDisplays(
                startTimeTrackerElem,
                endTimeTrackerElem,
                timeSliderElem,
                event.target
              )
            }, 1000)
            hookContext.el.dataset['trackTimeInterval'] = trackTimeInterval
            
            const backdrop = document.getElementById(this.backdropId)
            backdrop.classList.add('opacity-0')
            backdrop.classList.remove('opacity-50')

            break
          case YT.PlayerState.PAUSED:
            console.debug("[Player State :: PAUSED")

            await this.pushEventTo(this.el, 'on_player_paused')
            clearInterval(hookContext.el.dataset.trackTimeInterval)
            udpateTimeDisplays(
              startTimeTrackerElem,
              endTimeTrackerElem,
              timeSliderElem,
              event.target
            )
            break
          case YT.PlayerState.BUFFERING:
            console.debug("[Player State :: BUFFERING")
            if (hookContext.shouldAutoplay) {
              hookContext.shouldAutoplay = false
              hookContext.player.playVideo()
            }
            break
          case YT.PlayerState.CUED:
            console.debug("[Player State :: CUED")
            break

          default:
            console.debug("[Player :: Unknown state", event.data)
        }
      }

      const playerContainer = document.getElementById(this.playerContainerId)
      await initPlayer(playerContainer, {
        onReady: onPlayerReady,
        onStateChange: onStateChange(this)
      })
    })

    /**
     * show_player
     *
     * Received when the player is ready to be displayed
     */
    this.handleEvent('show_player', ({ callback_event: callbackEvent}) => {
      console.debug('[Player :: show_player]')

      this.player.g.classList.remove('hidden')

      const canvas = document.getElementById(this.spinnerId)
      stopNoise(canvas)
      canvas.classList.add('hidden')

      const backdrop = document.getElementById(this.backdropId)
      backdrop.classList.add('opacity-0')
      backdrop.classList.remove('opacity-50')

      this.pushEventTo(this.el, callbackEvent)
    })

    /**
     * request_current_time
     * 
     * Pushes the current player time to the given callback event.
     */
    this.handleEvent('request_current_time', async ({
      callback_event: callbackEvent
    }) => {
      console.debug('[Player :: request_current_time]')
      const currentTime = await this.player.getCurrentTime()
      await this.pushEventTo(this.el, callbackEvent, {
        current_time: currentTime
      })
    })

    /**
     * set_current_time
     * 
     * Seeks the player to the given time.
     */
    this.handleEvent('set_current_time', async ({
      current_time: currentTime
    }) => {
      console.debug('[Player :: set_current_time]')
      this.player.seekTo(currentTime, true)
    })

    /**
     * play_video
     * 
     * Received when the player should play the current track
     */
    this.handleEvent('play_video', async ({
      callback_event: callbackEvent
    }) => {
      console.debug('[Player :: play_video]')
      await this.player.playVideo()
      await this.pushEventTo(this.el, callbackEvent)

      const canvas = document.getElementById(this.spinnerId)
      stopNoise(canvas)
      canvas.classList.add('hidden')

      const backdrop = document.getElementById(this.backdropId)
      backdrop.classList.add('opacity-0')
      backdrop.classList.remove('opacity-50')
    })

    /**
     * pause_video
     * 
     * Received when the player should pause the current track
     */
    this.handleEvent('pause_video', async ({
      callback_event: callbackEvent
    }) => {
      console.debug('[Player :: pause_video]', this.spinnerId)
      await this.player.pauseVideo()
      await this.pushEventTo(this.el, callbackEvent)

      const canvas = document.getElementById(this.spinnerId)
      canvas.classList.remove("hidden")
      startNoise(canvas)

      const backdrop = document.getElementById(this.backdropId)
      backdrop.classList.remove("opacity-0")
      backdrop.classList.add("opacity-50")
    })

    /**
     * load_video
     * 
     * Received when the player should load a video
     */
    this.handleEvent('load_video', async (player) => {
      console.debug('[Player :: load_video]', player)
      console.debug('[Player :: load_video state]', player.state)
      switch (player.state) {
        case "playing":
          // loadVideoById auto-plays; set flag so BUFFERING handler
          // can retry play in case the initial auto-play is blocked
          this.shouldAutoplay = true
          this.player.loadVideoById(
            player.media_id, player.current_time, "large"
          )
          break

        case "paused":
          // cueVideoById loads without playing, avoiding any race with
          // pauseVideo
          this.shouldAutoplay = false
          this.player.cueVideoById(
            player.media_id, player.current_time, "large"
          )
          break

        case "idle":
          this.shouldAutoplay = false
          this.player.stopVideo()
          break

        default:
          console.debug(`Unknown player state=${player.state}`)
          break
      }

      scrollToElement(`${player.media_id}-item`)
    })

    /**
     * change_volume
     * 
     * Received when the player should change the volume level
     */
    this.handleEvent('change_volume', async ({
      volume_level: volumeLevel,
      callback_event: callbackEvent = null
    }) => {
      console.debug('[Player :: change_volume', volumeLevel)
      this.player.unMute()
      this.player.setVolume(volumeLevel)

      await this.handleCallbackEvent(callbackEvent)
    })

    /**
     * mute
     * 
     * Received when the player should mute
     */
    this.handleEvent('mute', async ({callback_event: callbackEvent = null}) => {
      console.debug('[Player :: mute')
      this.player.mute()

      await this.handleCallbackEvent(callbackEvent)
    })

    /**
     * unmute
     * 
     * Received when the player should unmute
     */
    this.handleEvent('unmute', async ({
      callback_event: callbackEvent = null
    }) => {
      console.debug('[Player :: unmute')
      this.player.unMute()

      await this.handleCallbackEvent(callbackEvent)
    })

    /**
     * fullscreen
     *
     * Switches to fullscreen mode
     */
    this.handleEvent('fullscreen', () => {
      console.debug('[Player :: fullscreen')
      const videoIframe = this.player.getIframe()

      console.log("iframe", videoIframe)

      const requestFullScreen =
        videoIframe.requestFullScreen
        || videoIframe.mozRequestFullScreen
        || videoIframe.webkitRequestFullScreen

      console.log(requestFullScreen)

      if (requestFullScreen) {
        requestFullScreen.bind(videoIframe)();
      }
    })
  },
  player: null,
  playerContainerId: null,
  spinnerId: null,
  startTimeTrackerId: null,
  timeSliderId: null
}
