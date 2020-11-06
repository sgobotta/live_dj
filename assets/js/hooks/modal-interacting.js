
const ModalInteracting = () => ({
  mounted() {
    const handleOpenCloseEvent = event => {
      if (event.detail.open === false) {
        this.el.removeEventListener("modal-change", handleOpenCloseEvent)

        setTimeout(() => {
          this.pushEventTo(event.detail.id, "close", {})
        }, 300);
      }
    }
    this.el.addEventListener("modal-change", handleOpenCloseEvent)
  }
})

export default ModalInteracting
