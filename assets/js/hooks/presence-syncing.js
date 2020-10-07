const PresenceSyncing = () => ({
  mounted() {
    this.handleEvent("presence-changed", ({ presence }) => {
      console.log("Presence changed ::: ", presence)
      this.pushEvent("request_player_sync");
    })
  }
})

export default PresenceSyncing
