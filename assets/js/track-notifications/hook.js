// Shows a native browser notification whenever the room's now-playing track
// changes (selected from the playlist, skipped forward/back, or advanced
// automatically). Gated behind the notifications-toggle preference (off by
// default, see notifications-toggle/hook.js), and permission is only
// requested the first time an enabled change arrives rather than on page
// load, since browsers discourage prompting before any user interaction.
const STORAGE_KEY = 'livedj_track_notifications_enabled'

export default {
  mounted() {
    this.handleEvent('track_changed', ({ title, channel, thumbnail }) => {
      this.notify(title, channel, thumbnail)
    })
  },

  notify(title, channel, thumbnail) {
    if (localStorage.getItem(STORAGE_KEY) !== 'true') return
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
