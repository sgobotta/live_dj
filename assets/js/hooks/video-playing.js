import Video from "../lib/video";

const VideoPlayingHook = () => ({
  player: null,
  mounted() {
    const playerContainer = document.getElementById("video-player");
    // const { videoId, videoTime } = this.el.dataset
    Video.init(playerContainer, '1FMSAeNG9us', (player) => {
      console.log('PLAYER ', player)
      this.player = player
      // player.target.playVideo()
      // player.target.seekTo(videoTime)

      // setInterval(() => {
      //   const currentTime = player.target.getCurrentTime()
      //   this.pushEvent('video-time-sync', currentTime)
      // }, 3000)
    })
    this.handleEvent("queue", ({params}) => {
      console.log('Event [queue] ::: Params: ', params)
      console.log('Event [queue] ::: Player: ', this.player)
    })
  }
})

export default VideoPlayingHook
