import createPlayer from './player'

export default {
  mounted() {
    setTimeout(async () => {
      const playerContainer = document.getElementById("video-player")
      await createPlayer(playerContainer)

    }, 1800)

  }
}
