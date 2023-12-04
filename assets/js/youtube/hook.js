import initPlayer from './player'

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
      spinner_id
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
        this.pushEventTo(this.el, 'player_loaded')
      }

      const onStateChange = async event => {
        switch (event.data) {
          case YT.PlayerState.UNSTARTED:
            console.debug("[Player State :: UNSTARTED")
            break
          case YT.PlayerState.ENDED:
            console.debug("[Player State :: ENDED")
            await this.pushEventTo(this.el, 'on_player_ended')
            break
          case YT.PlayerState.PLAYING:
            console.debug("[Player State :: PLAYING")
            await this.pushEventTo(this.el, 'on_player_playing')
            break
          case YT.PlayerState.PAUSED:
            console.debug("[Player State :: PAUSED")
            await this.pushEventTo(this.el, 'on_player_paused')
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
      await initPlayer(playerContainer, {onReady: onPlayerReady, onStateChange})
    })

    /**
     * show_player
     *
     * Received when the player is ready to be displayed
     */
    this.handleEvent('show_player', () => {
      console.debug('[Player :: show_player]')

      this.player.g.classList.remove('hidden')

      const spinner = document.getElementById(this.spinner_id)
      spinner.classList.add('hidden')
      spinner.classList.remove('animate-ping')

      const backdrop = document.getElementById(this.backdrop_id)
      backdrop.classList.add('opacity-0')
      backdrop.classList.remove('opacity-50')

      this.pushEventTo(this.el, 'player_visible')
    })

    /**
     * play_video
     * 
     * Received when the player should play the current track
     */
    this.handleEvent('play_video', async () => {
      console.debug('[Player :: play_video]')
      await this.player.playVideo()
      await this.pushEventTo(this.el, 'on_player_play')

      const backdrop = document.getElementById(this.backdrop_id)
      backdrop.classList.add('opacity-0')
      backdrop.classList.remove('opacity-50')
    })

    /**
     * pause_video
     * 
     * Received when the player should pause the current track
     */
    this.handleEvent('pause_video', async () => {
      console.debug('[Player :: pause_video]', this.spinner_id)
      await this.player.pauseVideo()
      await this.pushEventTo(this.el, 'on_player_pause')

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
      await this.player.loadVideoById(player.media_id, 0, "large")
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
