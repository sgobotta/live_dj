import initPlayer from './player'

export default {
  mounted() {
    /**
     * on_container_mounted
     *
     * Received when the player DOM has been mounted.
     */
    this.handleEvent('on_container_mounted', ({container_id}) => {
      console.debug(
        '[Player :: on_container_mounted]', `container_id=${container_id}`)

      const onPlayerReady = player => {
        console.debug('[Player :: Ready]', player)
        player.g.classList.add("rounded-lg")

        this.player = player
        this.pushEventTo(this.el, 'player_loaded')
      }

      const playerContainer = document.getElementById(container_id)
      initPlayer(playerContainer, onPlayerReady)
    })

    /**
     * show_player
     *
     * Received when the player is ready to be displayed
     */
    this.handleEvent('show_player', ({loader_container_id}) => {
      console.debug('[Player :: show_player]')

      this.player.g.classList.remove('hidden')
      
      const playerLoader = document.getElementById(loader_container_id)
      playerLoader.classList.add('hidden', 'scale-0')
      playerLoader.classList.remove('animate-ping')

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
    })

    /**
     * pause_video
     * 
     * Received when the player should pause the current track
     */
    this.handleEvent('pause_video', async () => {
      console.debug('[Player :: pause_video]')
      await this.player.pauseVideo()
      await this.pushEventTo(this.el, 'on_player_paused')
    })
  },
  player: null
}
