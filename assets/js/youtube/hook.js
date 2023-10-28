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

      const playerContainer = document.getElementById(player_container_id)
      await initPlayer(playerContainer, onPlayerReady)
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
      await this.pushEventTo(this.el, 'on_player_playing')

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
      await this.pushEventTo(this.el, 'on_player_paused')

      const spinner = document.getElementById(this.spinner_id)
      spinner.classList.add("animate-ping")
      spinner.classList.remove("hidden")

      const backdrop = document.getElementById(this.backdrop_id)
      backdrop.classList.remove("opacity-0")
      backdrop.classList.add("opacity-50")
    })
  },
  player: null,
  spinner_id: null
}
