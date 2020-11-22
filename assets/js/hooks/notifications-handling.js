const NotificationsHandling = () => ({
  mounted() {
    this.handleEvent('receive_notification', ({title, img}) => {
      if (Notification.permission !== 'denied') {
        Notification.requestPermission(function (permission) {
          if (permission === "granted") {
            new Notification(title, { icon: img, tag: 'playing-track' })
          }
        })
      }
    })
  }
})

export default NotificationsHandling
