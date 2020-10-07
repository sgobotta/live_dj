const PlayerSyncing = (player) => ({
  mounted() {
    this.handleEvent("receive_current_video", ({params: video}) => {
      console.log('Event [receive_current_video] ::: Video: ', video)
      const v = player.getVolume()
      console.log('Volume: ', v)
      player.loadVideoById({
        videoId: video.video_id,
        startSeconds: 0
      })
    })
  }
})

export default PlayerSyncing
