import Video from "../video";

export const VideoPlayingHook = (playerContainer) => ({
  mounted() {
    // const { videoId, videoTime } = this.el.dataset
    Video.init(playerContainer, '1FMSAeNG9us', (player) => {
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
