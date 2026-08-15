// Shows a native browser notification whenever the room's now-playing track
// changes (selected from the playlist, skipped forward/back, or advanced
// automatically). Permission is only requested the first time a change
// arrives rather than on page load, since browsers discourage prompting
// before any user interaction.
export default {
  mounted() {
    this.handleEvent('track_changed', ({ title, channel, thumbnail }) => {
      this.notify(title, channel, thumbnail)
    })
  },

  notify(title, channel, thumbnail) {
    if (typeof Notification === 'undefined') return

    if (Notification.permission === 'granted') {
      this.showNotification(title, channel, thumbnail)
    } else if (Notification.permission === 'default') {
      Notification.requestPermission().then((permission) => {
        if (permission === 'granted') {
          this.showNotification(title, channel, thumbnail)
        }
      })
    }
  },

  showNotification(title, channel, thumbnail) {
    new Notification(title, {
      body: channel,
      icon: thumbnail || undefined
    })
  }
}
