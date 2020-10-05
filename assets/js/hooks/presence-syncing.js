const PresenceSyncing = () => ({
  mounted() {
    this.handleEvent("presence-changed", ({ presence }) => {
      console.log("Presence changed ::: ", presence)
      this.pushEvent("sync_queue");
    })
  }
})

export default PresenceSyncing
