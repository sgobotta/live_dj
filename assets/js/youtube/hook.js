import initPlayer from './player'
import { secondsToTime } from '../lib/date-utils'

const updateTimeDisplay = (timeTrackerElem, time) => {
  const videoTime = (time === 0 || time === undefined)
    ? '-'
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
  mounted() {
    /**
     * on_container_mounted
     *
     * Received when the player DOM has been mounted.
     */
    this.handleEvent('on_container_mounted', async ({
      backdrop_id,
      player_container_id,
      spinner_id,
      start_time_tracker_id: startTimeTrackerElem,
      end_time_tracker_id: endTimeTrackerElem,
      time_slider_id: timeSliderElem
    }) => {
      this.spinner_id = spinner_id
      this.backdrop_id = backdrop_id
      console.debug(
        '[Player :: on_container_mounted]',
        `backdrop_container_id=${backdrop_id}`,
        `player_container_id=${player_container_id}`,
        `spinner_container_id=${spinner_id}`
      )

      document.getElementById(this.spinner_id).classList.remove("hidden")
      document.getElementById(this.spinner_id).classList.add("animate-ping")

      const onPlayerReady = player => {
        console.debug('[Player :: Ready]', player)
        player.g.classList.add("rounded-lg")

        this.player = player
        this.pushEventTo(this.el, 'on_player_loaded')
      }

      const onStateChange = (hookContext,
        {
          startTimeTrackerElem,
          endTimeTrackerElem,
          timeSliderElem
        }
      ) => async event => {
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
          case YT.PlayerState.BUFFERINGS:
            console.debug("[Player State :: BUFFERING")
            break
          case YT.PlayerState.CUED:
            console.debug("[Player State :: CUED")
            break

          default:
            console.debug("[Player :: Unknown state")
        }
      }

      const playerContainer = document.getElementById(player_container_id)
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
      console.debug('[Player :: show_player]')

      this.player.g.classList.remove('hidden')

      const spinner = document.getElementById(this.spinner_id)
      spinner.classList.add('hidden')
      spinner.classList.remove('animate-pulse')

      const backdrop = document.getElementById(this.backdrop_id)
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
      callback_event
    }) => {
      console.debug('[Player :: request_current_time]')
      const currentTime = await this.player.getCurrentTime()
      await this.pushEventTo(this.el, callback_event, {
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

      const backdrop = document.getElementById(this.backdrop_id)
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
      console.debug('[Player :: pause_video]', this.spinner_id)
      await this.player.pauseVideo()
      await this.pushEventTo(this.el, callbackEvent)

      const spinner = document.getElementById(this.spinner_id)
      spinner.classList.add("animate-ping")
      spinner.classList.remove("hidden")

      const backdrop = document.getElementById(this.backdrop_id)
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
      await this.player.loadVideoById(
        player.media_id,
        player.current_time,
        "large"
      )
      if (player.media_id) {
        await this.player.pauseVideo()
      } else {
        await this.player.stopVideo()
      }
    })
  },
  player: null,
  spinner_id: null
}
