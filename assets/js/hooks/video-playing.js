import Video from "../lib/video";

export const VideoPlayingHook = () => ({
  mounted() {
    const playerContainer = document.getElementById("video-player");
    // const { videoId, videoTime } = this.el.dataset
    Video.init(playerContainer, '1FMSAeNG9us', (player) => {
      console.log('PLAYER ', player)
      // player.target.playVideo()
      // player.target.seekTo(videoTime)

      // setInterval(() => {
      //   const currentTime = player.target.getCurrentTime()
      //   this.pushEvent('video-time-sync', currentTime)
      // }, 3000)
    })
  }
})

export default VideoPlayingHook
