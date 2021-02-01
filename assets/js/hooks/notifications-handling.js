const NotificationsHandling = () => ({
  mounted() {
    this.handleEvent('receive_notification', ({title, img, tag}) => {
      if (Notification.permission !== 'denied') {
        Notification.requestPermission(function (permission) {
          if (permission === "granted") {
            if (img.is_remote) {
              new Notification(title, { icon: img.value, tag })
            }
            else {
              const { origin } = window.location
              const imageUrl =  `${origin}/images/${img.value}`
              new Notification(title, { icon: imageUrl, tag })
            }
          }
        })
      }
    })
  }
})

export default NotificationsHandling
