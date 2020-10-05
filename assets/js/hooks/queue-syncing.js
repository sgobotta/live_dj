const QueueSyncing = (player) => ({
  mounted() {
    this.handleEvent("queue", ({params: videos}) => {
      console.log('Event [queue] ::: Videos: ', videos)
    })
  }
})

export default QueueSyncing
