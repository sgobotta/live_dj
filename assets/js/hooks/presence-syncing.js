const PresenceSyncing = () => ({
  mounted() {
    this.handleEvent("presence-changed", () => {
      console.log("::: Presence changed :::")
    })
  }
})

export default PresenceSyncing
