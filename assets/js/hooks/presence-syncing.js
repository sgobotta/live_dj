const PresenceSyncing = () => ({
  mounted() {
    this.handleEvent("presence-changed", () => {
      console.log("::: Presence changed :::")
      this.pushEvent("request_player_sync");
    })
  }
})

export default PresenceSyncing
