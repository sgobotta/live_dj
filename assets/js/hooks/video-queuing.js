const VideoQueuing = () => ({
  mounted() {
    console.log('Video Queuing mounted')

    this.handleEvent("queue", ({params}) => {
      console.log('Event [queue] ::: Params: ', params)
    })
  }
})

export default VideoQueuing
