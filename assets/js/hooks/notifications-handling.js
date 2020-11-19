const NotificationsHandling = () => ({
  mounted() {
    this.handleEvent('receive_notification', ({title, img}) => {
      new Notification(title, { icon: img })
    })
  }
})

export default NotificationsHandling
