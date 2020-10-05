
const VideoPlayingHook = (player) => ({
  player: null,
  mounted() {
    this.handleEvent('cue', ({params}) => {
      console.log('called cue video with: ', params)
      player.cueVideoById({videoId: params.video_id, startSeconds: 0})
    })
    // const playerContainer = document.getElementById("video-player");
    // // const { videoId, videoTime } = this.el.dataset
    // Video.init(playerContainer, '', (player) => {
    //   console.log('PLAYER ', player)
    //   this.player = player

    //   // this.pushEvent("sync_queue");
    //   // player.target.playVideo()
    //   // player.target.seekTo(videoTime)

    //   // setInterval(() => {
    //   //   const currentTime = player.target.getCurrentTime()
    //   //   this.pushEvent('video-time-sync', currentTime)
    //   // }, 3000)
    // })
    // this.handleEvent("queue", ({params: videos}) => {
    //   console.log('Event [queue] ::: Videos: ', videos)
    //   console.log('Event [queue] ::: Player: ', this.player)
    //   videos.forEach(video => {
    //     console.log('player ::: ', this.player)
    //     this.player.cueVideoById(video.videoId, 0)
    //   })
    // })
  }
})

export default VideoPlayingHook
