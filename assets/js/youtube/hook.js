import initPlayer from './player'
import { secondsToTime } from '../lib/date-utils'

function scrollToElement(elementId) {
  const element = document.getElementById(elementId)
  if (element) element.scrollIntoView()
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
        'Player :: on_container_mounted',
        `backdrop_container_id=${this.backdropId}`,
        `player_container_id=${this.playerContainerId}`,
        `spinner_container_id=${this.spinnerId}`
      )

      document.getElementById(this.spinnerId).classList.remove("hidden")
      document.getElementById(this.spinnerId).classList.add("animate-ping")

      const onPlayerReady = player => {
        console.debug('Player :: Ready', player)
        player.g.classList.add("rounded-lg")

        this.player = player
        this.pushEventTo(this.el, 'on_player_loaded')
      }

      const startTimeTrackerElem = document.getElementById(startTimeTrackerId)
      const endTimeTrackerElem = document.getElementById(endTimeTrackerId)
      const timeSliderElem = document.getElementById(timeSliderId)

      const onStateChange = (hookContext,
        {
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem
        }
      ) => async event => {
        console.log(startTimeTrackerElem, 'start time tracker elem')
        /* eslint-disable no-case-declarations */
        switch (event.data) {
          case YT.PlayerState.UNSTARTED:
            console.debug("Player State :: UNSTARTED")
            break
          case YT.PlayerState.ENDED:
            console.debug("Player State :: ENDED")
            clearInterval(hookContext.el.dataset.trackTimeInterval)
            await this.pushEventTo(this.el, 'on_player_ended')
            break
          case YT.PlayerState.PLAYING:
            console.debug("Player State :: PLAYING")

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
            console.debug("Player State :: PAUSED")

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
            console.debug("Player State :: BUFFERING")
            break
          case YT.PlayerState.CUED:
            console.debug("Player State :: CUED")
            break

          default:
            console.debug("Player :: Unknown state", event.data)
        }
      }

      const playerContainer = document.getElementById(this.playerContainerId)
      await initPlayer(playerContainer, {
        onReady: onPlayerReady,
        onStateChange: onStateChange(
          this, {
            endTimeTrackerElem,
            startTimeTrackerElem,
            timeSliderElem
          }
        )
      })
    })

    /**
     * show_player
     *
     * Received when the player is ready to be displayed
     */
    this.handleEvent('show_player', ({ callback_event: callbackEvent}) => {
      console.debug('Player :: show_player')

      this.player.g.classList.remove('hidden')

      const spinner = document.getElementById(this.spinnerId)
      spinner.classList.add('hidden')
      spinner.classList.remove('animate-pulse')

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
      console.debug('Player :: request_current_time')

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
      console.debug('Player :: set_current_time')

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
      console.debug('Player :: play_video')

      this.playVideo()

      await this.pushEventTo(this.el, callbackEvent)
    })

    /**
     * pause_video
     * 
     * Received when the player should pause the current track
     */
    this.handleEvent('pause_video', async ({
      callback_event: callbackEvent
    }) => {
      console.debug('Player :: pause_video')

      this.pauseVideo()

      await this.pushEventTo(this.el, callbackEvent)
    })

    /**
     * load_video
     * 
     * Received when the player should load a video
     */
    this.handleEvent('load_video', async ({
      callback_event: callbackEvent, player
    }) => {
      console.debug('Player :: load_video')
      await this.player.mute()
      await this.player.loadVideoById(
        player.media_id,
        player.current_time,
        "large"
      )

      setTimeout(async () => {
        await this.pauseVideo()
        await this.player.unMute()

        this.pushEventTo(this.el, callbackEvent, {
          duration: this.player.getDuration()
        })
      }, 500)

      // Commenting this to avoid triggering player changes at this point.
      // What I want to do is to trigger player events once the server
      // recognises the total duration of the track, which is going to be sent
      // on this function

      // switch (player.state) {
      //   case "playing":
      //     await this.player.playVideo()
      //     break

      //   case "paused":
      //     await this.player.pauseVideo()
      //     break

      //   case "idle":
      //     await this.player.stopVideo()
      //     break

      //   default:
      //     console.debug(`Unkown player state=${player.state}`)
      //     break
      // }

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
      console.debug('Player :: change_volume', volumeLevel)
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
      console.debug('Player :: mute')
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
      console.debug('Player :: unmute')
      this.player.unMute()

      await this.handleCallbackEvent(callbackEvent)
    })

    /**
     * fullscreen
     *
     * Switches to fullscreen mode
     */
    this.handleEvent('fullscreen', () => {
      console.debug('Player :: fullscreen')
      const videoIframe = this.player.getIframe()
      const requestFullScreen =
        videoIframe.requestFullScreen
        || videoIframe.mozRequestFullScreen
        || videoIframe.webkitRequestFullScreen

      if (requestFullScreen) {
        requestFullScreen.bind(videoIframe)();
      }
    })
  },
  async pauseVideo() {
    const spinner = document.getElementById(this.spinnerId)
    spinner.classList.add("animate-ping")
    spinner.classList.remove("hidden")

    const backdrop = document.getElementById(this.backdropId)
    backdrop.classList.remove("opacity-0")
    backdrop.classList.add("opacity-50")

    await this.player.pauseVideo()
  },
  async playVideo() {
    await this.player.playVideo()
      
    const backdrop = document.getElementById(this.backdropId)
    backdrop.classList.add('opacity-0')
    backdrop.classList.remove('opacity-50')
  },
  player: null,
  playerContainerId: null,
  spinnerId: null,
  startTimeTrackerId: null,
  timeSliderId: null
}
